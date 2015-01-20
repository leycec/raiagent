# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# This is the Python 3-specific branch of PyInstaller, the most active
# development branch thereof. While such branch *MIGHT* be nominally compatible
# with Python 2.7, this is unlikely to (stably) be the case. Hence, both
# "python2_7" and "pypy" are omitted here.
PYTHON_COMPAT=( python{3_3,3_4} pypy3 )

EGIT_REPO_URI="https://github.com/pyinstaller/pyinstaller"
EGIT_BRANCH="python3"

# "waf" requires a threading-enabled Python interpreter.
PYTHON_REQ_USE='threads(+)'

# Order of operations is significant here. Since we explicitly call "waf-utils"
# but *NOT* "distutils-r1" phase functions, ensure that the latter remain the
# default by inheriting the latter *AFTER* the former.
inherit waf-utils distutils-r1 git-2

DESCRIPTION="Program converting Python programs into stand-alone executables"
HOMEPAGE="http://www.pyinstaller.org"

LICENSE="pyinstaller"
SLOT="0"
KEYWORDS=""

#FIXME: Add support for command-line options accepted by "bootloader/wscript",
#run by the call to waf-utils_src_configure() below (e.g., "--leak-detector",
#"--clang"). Also add a "debug" USE flag for switching between release and
#debug builds.

IUSE="doc"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

#FIXME: Interestingly, PyInstaller itself has no hard or soft dependencies
#excluding the expected build-time dependency of "setuptools". Its unit tests,
#however, require an elaborate set of pure-Python packages, C-based Python
#extensions, and system-wide shared libraries. It's fairly extreme --
#sufficiently extreme, in fact, that we do *NOT* currently bother. For an
#exhaustive list of such dependencies, see "tests/test-requirements.txt".

RDEPEND=""
DEPEND="${RDEPEND}"

# While the typical "waf" project permits "waf" to be run from outside the
# directory containing "waf", PyInstaller requires "waf" to be run from inside
# such directory in a relative manner. Ensure this.
WAF_BINARY="./waf"

# Since the "waf" script bundled with PyInstaller does *NOT* support the
# conventionel "--libdir" option, prevent such option from being passed.
NO_WAF_LIBDIR=1

python_prepare_all() {
	# Word size for the current architecture. (There simply *MUST* be a more
	# Gentooish way of determining this. I couldn't find it. While we should
	# arguably test "[[ "$(getconf LONG_BIT)" == 64 ]]" instead, such magic is
	# arguably even kludgier. Your mileage may vary.)
	local arch_word_size
	case "${ARCH}" in
	amd64) arch_word_size=64;;
	*)     arch_word_size=32;;
	esac

	# Install only the non-debug Linux bootloader specific to the architecture
	# of the current machine.
	sed\
		-e '/.*bootloader\/\*\/*.*/s~\*/\*~Linux-'${arch_word_size}'bit/run~'\
		-i setup.py || die '"sed" failed.'

	# Avoid stripping bootloader binaries and prevent the bootloader from being
	# compiled under "suboptimal" ${CFLAGS}.
	sed\
		-e "/features='strip',$/d"\
		-e "s~\\(\\s*\\)ctx.env.append_value('CFLAGS', '-O2')$~\\1pass~"\
		-i bootloader/wscript || die '"sed" failed.'

	# Continue with the default behaviour.
	distutils-r1_python_prepare_all
}

python_configure() {
	# Configure the Linux bootloader. Since Gentoo is *NOT* LSB-compliant, build
	# a non-LSB-compliant bootloader. Unfortunately, this could reduce the
	# cross-platform-portability of such bootloader and hence applications
	# frozen with such bootloader. Until Gentoo supplies an ebuild for building
	# at least version 4.0 of the LSB tools, there's little we can do here. 
	cd bootloader
	waf-utils_src_configure --no-lsb

	# Continue with the default behaviour.
	cd "${S}"
	distutils-r1_python_configure
}

python_compile() {
	# Compile the non-debug Linux bootloader. Ideally, we would simply call
	# waf-utils_src_compile() to do so. Unfortunately, such function attempts to
	# run the "build" WAF task, which for PyInstaller *ALWAYS* fails with the
	# following fatal error:
	#     Call "python waf all" to compile all bootloaders.
	# Since the "waf-utils" eclass does *NOT* support running of alternative
	# tasks, we reimplement waf-utils_src_compile() to do so. (Since this is
	# lame, we should probably file a feature request with the author of the
	# "waf-utils" eclass.)
	cd bootloader
	local _mywafconfig
	[[ "${WAF_VERBOSE}" ]] && _mywafconfig="--verbose"
	local jobs="--jobs=$(makeopts_jobs)"
	echo "\"${WAF_BINARY}\" build_release ${_mywafconfig} ${jobs}"
	"${WAF_BINARY}" build_release ${_mywafconfig} ${jobs} ||
		die "Bootloader compilation failed."

	# Move the binaries for such bootloader to "PyInstaller/bootloader" *BEFORE*
	# compiling the non-bootloader portion of PyInstaller, which requires such
	# binaries. (Note that the "install_release" task does *NOT* install files
	# to ${IMAGE}, despite the "install" in such task name.)
	"${WAF_BINARY}" install_release || die "Bootloader installation failed."

	# Continue with the default behaviour.
	cd "${S}"
	distutils-r1_python_compile
}

python_install_all() {
	distutils-r1_python_install_all

	# Install documentation.
	dodoc README.rst TODO doc/*.txt
	if use doc; then
		# Install HTML documentation.
		dohtml -r doc/*

		# Install PDF documentation.
		docinto pdf
		dodoc doc/*.pdf
	fi
}

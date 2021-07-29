# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..10} pypy3 )

# Upstream has two alternate approaches to building its Python API:
# 1. A working "CMakeList.txt" only supporting a single Python target.
# 2. A non-working "setup.py" supporting multiple Python targets but internally
#    invoking CMake in mostly non-configurable (and thus broken) ways.
# We choose the working approach.
inherit python-single-r1 cmake

DESCRIPTION="Library to instrument executable formats"
HOMEPAGE="https://lief.quarkslab.com"
SRC_URI="https://github.com/lief-project/LIEF/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

#FIXME: Uncomment after bumping to the next stable release. See below.
# IUSE="art c dex elf examples macho oat pe +python static-libs test vdex"
IUSE="c examples +python static-libs test"

# See "cmake/LIEFDependencies.cmake" for C and C++ dependencies.
BDEPEND="
	python? (
		$(python_gen_cond_dep '
			>=dev-python/setuptools-31.0.0[${PYTHON_USEDEP}]
		')
	)
"
#FIXME: Add after bumping to the next stable release:
#	>=dev-libs/spdlog-1.8.5
RDEPEND="python? ( ${PYTHON_DEPS} )"
DEPEND="${RDEPEND}"

# LIEF tests are non-trivial (if not infeasible) to run in the general case.
# For example, "tests/CMakeLists.txt" implies all USE flags must be enabled:
#     if (NOT LIEF_ELF OR NOT LIEF_PE OR NOT LIEF_MACHO)
#       message(FATAL_ERROR "Tests require all LIEF's modules activated" )
#     endif()
RESTRICT="test"

S="${WORKDIR}/LIEF-${PV}"

DISTUTILS_OPTIONAL=1

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

#FIXME: Unvender currently vendored dependencies in "third-party/". Ideally,
#upstream should add one "LIEF_EXTERNAL_${LIBNAME}" CMake option governing each
#vendored dependency resembling the existing "LIEF_EXTERNAL_SPDLOG" option.
#Note that LIEF patches the vendored "Boost leaf" and "utfcpp" dependencies.
src_prepare() {
	# Respect "multilib"-based lib dirnames.
	sed -i -e 's~\bDESTINATION lib\(64\)\{0,1\}\b~DESTINATION ${CMAKE_INSTALL_LIBDIR}~' \
		CMakeLists.txt || die
	cmake_src_prepare
}

src_configure() {
	# See also:
	# * "cmake/LIEFDependencies.cmake" for a dependency list.
	# * "cmake/LIEFOptions.cmake" for option descriptions.
	local mycmakeargs=(
		-DLIEF_COVERAGE=OFF
		-DLIEF_DISABLE_FROZEN=OFF
		-DLIEF_EXTRA_WARNINGS=OFF
		-DLIEF_PROFILING=OFF
		-DLIEF_SUPPORT_CXX14=ON
		-DLIEF_USE_CCACHE=OFF

		-DBUILD_SHARED_LIBS="$(usex static-libs OFF ON)"
		-DLIEF_C_API="$(usex c ON OFF)"
		-DLIEF_EXAMPLES="$(usex examples ON OFF)"
		-DLIEF_FORCE32="$(usex x86 ON OFF)"
		-DLIEF_FORCE_API_EXPORTS="$(usex python ON OFF)"  # <-- see "setup.py"
		-DLIEF_INSTALL_PYTHON="$(usex python ON OFF)"
		-DLIEF_PYTHON_API="$(usex python ON OFF)"

		#FIXME: Uncomment after bumping to the next stable release. Disabling
		#LIEF's format options commonly causes build failure. See also:
		#    https://github.com/lief-project/LIEF/issues/599
		# -DLIEF_ELF="$(usex elf ON OFF)"
		# -DLIEF_PE="$(usex pe ON OFF)"
		# -DLIEF_MACHO="$(usex macho ON OFF)"
		# -DLIEF_ART="$(usex art ON OFF)"
		# -DLIEF_DEX="$(usex dex ON OFF)"
		# -DLIEF_OAT="$(usex oat ON OFF)"
		# -DLIEF_VDEX="$(usex vdex ON OFF)"
		# -DLIEF_EXTERNAL_SPDLOG=ON
		-DLIEF_ELF=ON
		-DLIEF_PE=ON
		-DLIEF_MACHO=ON
		-DLIEF_ART=ON
		-DLIEF_DEX=ON
		-DLIEF_OAT=ON
		-DLIEF_VDEX=ON

		#FIXME: Add USE flags governing most or all of these options.
		-DLIEF_ENABLE_JSON=OFF
		-DLIEF_DOC=OFF
		-DLIEF_FUZZING=OFF
		-DLIEF_INSTALL_COMPILED_EXAMPLES=OFF
		-DLIEF_LOGGING=OFF
		-DLIEF_LOGGING_DEBUG=OFF
		-DLIEF_TESTS=OFF
		-LIEF_ASAN=OFF
		-LIEF_LSAN=OFF
		-LIEF_TSAN=OFF
		-LIEF_USAN=OFF
	)
	use python && mycmakeargs+=( -DPYTHON_EXECUTABLE="${PYTHON}" )

	cmake_src_configure
}

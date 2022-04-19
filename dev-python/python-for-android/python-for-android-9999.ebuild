# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

#FIXME: Submit an upstream Kivy issue (and possible PR) referencing "raiagent"
#as the new source for Gentoo installation.

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..10} pypy3 )

inherit distutils-r1

DESCRIPTION="Kivy-friendly tool for packaging Python to Android"
HOMEPAGE="https://python-for-android.readthedocs.io"

LICENSE="MIT"
SLOT="0"

#FIXME: Buildozer defaults to internally fetching appropriate versions of the
#Android NDK and SDK. It's probably best to let it do so. Nonetheless, note
#that "buildozer.spec" files can technically be configured to point to
#system-wide Android NDK installations. That said, since there appears to be
#little point in doing so, we currently disable this requirement.
# # Ideally, we would depend upon the same minimum version of the Android NDK and
# # SDK advised by that documentation. Since Portage fails to package
# # sufficiently recent versions of the Android NDK, however, that's infeasible.
# # Instead, we advise users to install both from a third-party overlay. Since
# # packaging either is extremely non-trivial, we defer to this other overlays.
# # As of this writing, we prefer @msva's high-quality mva overlay residing at:
# #     https://github.com/msva/mva-overlay
# #
# # Lastly, note that the "android-ndk" ebuild implicitly requires the
# # "android-sdk-update-manager" ebuild. Ergo, we list only the former.
# RDEPEND="${DEPEND}
# 	dev-util/android-ndk
# "
#FIXME: Actually, we should probably emit a post-installation message noting
#that Android Studio installs the Android SDK to "~/Android". Ergo,
#"buildozer.spec" can be configured to point to that rather than refetching and
#reinstalling the SDK elsewhere.
#FIXME: Actually, it appears that may *NOT* necessarily work -- at least, not
#as of a decade ago, which is admittedly ancient. According to this 2014 issue
#thread, Buildozer requires write access to the SDK directory: *facepalm*
#    https://github.com/kivy/buildozer/issues/169#issuecomment-68239361

# Build-time dependencies derive from the "install_reqs" global variable in
# "setup.py".
DEPEND="
	dev-python/appdirs[${PYTHON_USEDEP}]
	dev-python/pep517[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
	dev-python/toml[${PYTHON_USEDEP}]
	>=dev-python/colorama-0.3.3[${PYTHON_USEDEP}]
	>=dev-python/jinja-2.0.0[${PYTHON_USEDEP}]
	>=dev-python/sh-1.10.0[${PYTHON_USEDEP}]
"

# Runtime dependencies derive from online documentation at:
#     https://python-for-android.readthedocs.io/en/latest/quickstart/#installation
# Sadly, that documentation fails to list all requisite runtime dependencies,
# which we manually harvested by inspection of standard output emitted by the
# "buildozer android debug" command on a local toy project. Notably:
#     $ buildozer android debug
#     # Check configuration tokens
#     # Ensure build layout
#     # Check configuration tokens
#     # Read available permissions from api-versions.xml
#     # Preparing build
#     # Check requirements for android
#     # Run 'dpkg --version'
#     # Cwd None
#     /bin/sh: line 1: dpkg: command not found
#     # Search for Git (git)
#     #  -> found at /usr/bin/git
#     # Search for Cython (cython)
#     #  -> found at /usr/lib/python-exec/python-exec2
#     # Search for Java compiler (javac)
#     #  -> found at /usr/libexec/eselect-java/run-java-tool.bash
#     # Search for Java keytool (keytool)
#     #  -> found at /usr/libexec/eselect-java/run-java-tool.bash
#     # Install platform
#     # Run 'git clone -b master --single-branch https://github.com/kivy/python-for-android.git python-for-android'
#     Cloning into 'python-for-android'...
#     # Run '/usr/lib/python-exec/python3.8/python3 -m pip install -q --user \'appdirs\' \'colorama>=0.3.3\' \'jinja2\' \'six\' \'enum34; python_version<"3.4"\' \'sh>=1.10; sys_platform!="nt"\' \'pep517<0.7.0\' \'toml\''
#     # Cwd None
#
# Note that "python-for-android" ignores numerous system-wide runtime
# dependencies by default, including Java Ant and the Android NDK and SDK.
# Instructing "python-for-android" to accept these system-wide runtime
# dependencies requires modifying the project-specific "buildozer.spec" file
# for the current app being built. Since an ebuild clearly has no means of
# safely performing those modifications, we ignore those dependencies and let
# "python-for-android" locally download and extract duplicate copies into the
# "~/.buildozer/android/" subdirectory. *facepalm*
RDEPEND="${DEPEND}
	dev-python/cython[${PYTHON_USEDEP}]
	dev-python/pip[${PYTHON_USEDEP}]
	dev-vcs/git
"

#FIXME: Upstream fails to bundle the "tests/" directory with source tarballs.
# distutils_enable_tests pytest
distutils_enable_sphinx docs

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/kivy/python-for-android.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

python_prepare_all() {
	# Circumvent a dependency constraint on obsolete "pep517" versions.
	# "setup.py" requires "pep517<0.7.0". See also this unresolved issue:
	#     https://github.com/kivy/python-for-android/issues/2573
	sed -i -e 's~pep517<0\.7\.0~pep517~' setup.py || die '"sed" failed.'

	distutils-r1_python_prepare_all
}

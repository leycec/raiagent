# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..10} pypy3 )

inherit distutils-r1

DESCRIPTION="Kivy-friendly tool for packaging Python to Android"
HOMEPAGE="https://python-for-android.readthedocs.io"

LICENSE="MIT"
SLOT="0"

# Build-time dependencies derive from the "install_reqs" global variable in
# "setup.py". Runtime dependencies derive from online documentation at:
#     https://python-for-android.readthedocs.io/en/latest/quickstart/#installation
#
# Ideally, we would depend upon the same minimum version of the Android NDK and
# SDK advised by that documentation. Since Portage fails to package
# sufficiently recent versions of the Android NDK, however, that's infeasible.
# Instead, we advise users to install both from a third-party overlay. Since
# packaging either is extremely non-trivial, we defer to this other overlays.
# As of this writing, we prefer @msva's high-quality mva overlay residing at:
#     https://github.com/msva/mva-overlay
#
# Lastly, note that the "android-ndk" ebuild implicitly requires the
# "android-sdk-update-manager" ebuild. Ergo, we list only the former.
DEPEND="
	dev-python/appdirs[${PYTHON_USEDEP}]
	dev-python/pep517[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
	dev-python/toml[${PYTHON_USEDEP}]
	>=dev-python/colorama-0.3.3[${PYTHON_USEDEP}]
	>=dev-python/jinja-2.0.0[${PYTHON_USEDEP}]
	>=dev-python/sh-1.10.0[${PYTHON_USEDEP}]
"
RDEPEND="${DEPEND}
	dev-util/android-ndk
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

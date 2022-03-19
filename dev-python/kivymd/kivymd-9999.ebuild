# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#FIXME: Migrate to the new "DISTUTILS_USE_PEP517=setuptools" mode. See also:
#    https://projects.gentoo.org/python/guide/distutils.html
#DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..10} )

inherit distutils-r1

DESCRIPTION="Collection of Material Design-compliant widgets for use with Kivy"
HOMEPAGE="https://kivymd.readthedocs.io"

LICENSE="MIT"
SLOT="0"

# Dependencies derive from "setup.py", as expected.
BEPEND="
	doc? (
		>=dev-python/sphinx-autoapi-1.4.0[${PYTHON_USEDEP}]
		dev-python/sphinx-notfound-page[${PYTHON_USEDEP}]
		dev-python/sphinx_rtd_theme[${PYTHON_USEDEP}]
	)
	test? (
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
		dev-python/pytest-timeout[${PYTHON_USEDEP}]
	)
"
DEPEND="
	>=dev-python/Kivy-2.0.0[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
"
RDEPEND="${DEPEND}"

distutils_enable_tests pytest
distutils_enable_sphinx docs

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/kivymd/KivyMD.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

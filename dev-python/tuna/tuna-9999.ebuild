# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..10} pypy3 )

inherit distutils-r1

DESCRIPTION="In-browser Python profile viewer"
HOMEPAGE="https://github.com/nschloe/tuna"

LICENSE="GPL-3"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="dev-python/wheel[${PYTHON_USEDEP}]"

#FIXME: Add a new "doc" USE flag that, when enabled, generates and installs the
#HTML-based documentation templated as "smartypants"-driven Markdown in the
#"docs" directory. See the "docs/mkdocs.yml" file for further details.
# DOCS=( README.rst )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/nschloe/tuna"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

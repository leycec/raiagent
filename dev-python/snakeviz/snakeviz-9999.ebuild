# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} pypy3 )

inherit distutils-r1

DESCRIPTION="Web-based viewer for Python profiler output"
HOMEPAGE="https://jiffyclub.github.io/snakeviz"

LICENSE="BSD"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND="${PYTHON_DEPS}
	>=www-servers/tornado-2.0[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

#FIXME: Add a new "doc" USE flag that, when enabled, generates and installs the
#HTML-based documentation templated as "smartypants"-driven Markdown in the
#"docs" directory. See the "docs/mkdocs.yml" file for further details.
# DOCS=( README.rst )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/jiffyclub/snakeviz"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/s/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

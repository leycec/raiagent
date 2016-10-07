# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=6

#FIXME: Add support for test execution.

PYTHON_COMPAT=( python{2_7,3_4,3_5} )

inherit distutils-r1

DESCRIPTION="Python interface to Graphviz's Dot language"
HOMEPAGE="https://github.com/erocarrera/pydot"

LICENSE="MIT"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="${PYTHON_DEPS}
	>=dev-python/pyparsing-2.1.4[${PYTHON_USEDEP}]
"
RDEPEND="${DEPEND}
	media-gfx/graphviz
"

DOCS=( "README.md" )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	# Pydot leverages a GitFlow-based workflow. Pydot's "master" branch is much
	# less frequently updated than its "dev" branch, which acts as the storehouse
	# of official commits and hence the branch of most interest to end users.
	EGIT_REPO_URI="${HOMEPAGE}"
	EGIT_BRANCH="dev"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/p/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

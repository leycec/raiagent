# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} )

inherit distutils-r1

MY_PN="py_dbar"
MY_P="${MY_PN}-${PV}"

# Note this project currently lacks a public Git repository.
DESCRIPTION="Pythonic D-bar Algorithm for EIT"
HOMEPAGE="https://pypi.org/project/py-dbar"

LICENSE="MIT"
SLOT="0"

RDEPEND="
	dev-python/matplotlib[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/pyamg[${PYTHON_USEDEP}]
	dev-python/pyeit[${PYTHON_USEDEP}]
	dev-python/scipy[${PYTHON_USEDEP}]
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	#FIXME: No such repository currently exists, but probably will tomorrow.
	EGIT_REPO_URI="https://github.com/???/py-dbar"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"

	S="${WORKDIR}/${MY_P}"
fi

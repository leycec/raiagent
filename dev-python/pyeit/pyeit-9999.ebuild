# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} )

inherit distutils-r1

DESCRIPTION="Python-based toolkit for Electrical Impedance Tomography"
HOMEPAGE="https://github.com/liubenyuan/pyEIT"

LICENSE="BSD"
SLOT="0"
IUSE="3d thorax"

#FIXME: Add below *AFTER* Gentoo packages "dev-python/vispy".
#	3d? ( dev-python/vispy[${PYTHON_USEDEP}] )
RDEPEND="
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/pandas[${PYTHON_USEDEP}]
	dev-python/scipy[${PYTHON_USEDEP}]
	thorax? ( sci-libs/shapely[${PYTHON_USEDEP}] )
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/liubenyuan/pyEIT.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

DOCS=( Readme.md doc/pyEIT-data_format.pdf )

#FIXME: Remove after upstream resolves the following issue:
#    https://github.com/liubenyuan/pyEIT/issues/24
python_prepare_all() {
	# Prevent upstream from erroneously installing tests.
	sed -i -e 's~"test"~"tests", "tests.*"~' setup.py || die '"sed" failed.'

	distutils-r1_python_prepare_all
}

python_install_all() {
	[[ -d examples ]] && dodoc -r examples

	distutils-r1_python_install_all
}

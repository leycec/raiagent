# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{6..9} pypy3 )

inherit distutils-r1

DESCRIPTION="Socket.IO integration for Flask applications"
HOMEPAGE="
	https://flask-socketio.readthedocs.org
	https://github.com/miguelgrinberg/Flask-SocketIO
	https://pypi.org/project/Flask-SocketIO"

LICENSE="MIT"
SLOT="0"
IUSE="test"

BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND="
	>=dev-python/flask-0.9[${PYTHON_USEDEP}]
	>=dev-python/python-socketio-4.3.0[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}
	test? ( dev-python/coverage[${PYTHON_USEDEP}] )
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/miguelgrinberg/Flask-SocketIO.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	MY_PN="Flask-SocketIO"
	MY_P="${MY_PN}-${PV}"

	SRC_URI="mirror://pypi/${MY_PN:0:1}/${MY_PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"

	# pypi tarball does not contain tests
	RESTRICT="test"
fi

python_test() {
	PYTHONPATH="${PWD}" python ./test_socketio.py || die
}

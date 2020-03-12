# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} pypy3 )

inherit readme.gentoo-r1 distutils-r1

# Yes, the URL of this repository is actually suffixed by ".py". Just because.
DESCRIPTION="Lightweight web server for previewing reStructuredText documents"
HOMEPAGE="
	https://pypi.org/project/instant-rst
	https://github.com/gu-fan/instant-rst.py"

LICENSE="MIT"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# Note that the mandatory "net-misc/curl" runtime dependency listed below is
# actually a mandatory runtime dependency of the "Rykka/InstantRst" Vim bundle
# usually installed alongside this package. Since Vim bundles are preferably
# installed via a Vim bundle manager (e.g., Vundle, NeoBundle) rather than
# Portage, this dependency is listed here instead. This should impose no
# hardships for non-Vim users, as "curl" is usually available on most systems.
BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
DEPEND="${PYTHON_DEPS}
	dev-python/docutils[${PYTHON_USEDEP}]
	dev-python/flask-socketio[${PYTHON_USEDEP}]
	dev-python/pygments[${PYTHON_USEDEP}]
"
RDEPEND="${DEPEND}
	net-misc/curl
"

DOCS=( "README.rst" )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/gu-fan/instant-rst.py.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

python_install_all() {
	DOC_CONTENTS="
	To preview reStructuredText buffers in Vim, consider installing NeoBundle
	and add the following lines to your Vim configuration (e.g.,
	\"~/.vimrc\"):\\n
	\\n
	\\tNeoBundle 'Rykka/riv.vim'\\n
	\\tNeoBundle 'Rykka/InstantRst'\\n
	\\n
	To preview and stop previewing the current reStructuredText buffer in Vim,
	enter the following Vim excommands (respectively):\\n
	\\n
	\\t:InstantRst\\n
	\\t:StopInstantRst
	"

	readme.gentoo_create_doc

	distutils-r1_python_install_all
}

pkg_postinst() {
	readme.gentoo_print_elog
}

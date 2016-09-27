# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=6

# InstantRst Server has yet to be ported to Python 3.x -- and, frankly, probably
# never will be.
PYTHON_COMPAT=( python2_7 )

# Since default phase functions defined by "distutils-r1" take absolute
# precedence over those defined by "readme.gentoo-r1", inherit the latter later.
inherit readme.gentoo-r1 distutils-r1

# Yes, the URL of this repository is actually suffixed by ".py". Just because.
DESCRIPTION="Lightweight web server for previewing reStructuredText documents"
HOMEPAGE="https://github.com/rykka/instant-rst.py"

LICENSE="MIT"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# Note that:
#
# * Although the "install_requires" metadata key in this package's top-level
#   "setup.py" script lists "pygments" as a mandatory dependency, this package
#   does *NOT* appear to actually import or otherwise use Pygments. Hence,
#   "dev-python/pygments" is *NOT* listed as a runtime dependency below.
# * The mandatory "net-misc/curl" runtime dependency listed below is actually a
#   mandatory runtime dependency of the "Rykka/InstantRst" Vim bundle usually
#   installed alongside this package. Since Vim bundles are preferably installed
#   via a Vim bundle manager (e.g., Vundle, NeoBundle) rather than Portage, this
#   dependency is listed here instead. This should impose no hardships for non-
#   Vim users, as "curl" is usually *ALWAYS* available on most systems.
DEPEND="${PYTHON_DEPS}
	dev-python/setuptools[${PYTHON_USEDEP}]
"
RDEPEND="${PYTHON_DEPS}
	dev-python/docutils[${PYTHON_USEDEP}]
	dev-python/flask[${PYTHON_USEDEP}]
	dev-python/flask-socketio[${PYTHON_USEDEP}]
	net-misc/curl
"

DOCS=( "README.rst" )

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="${HOMEPAGE}"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/i/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

python_install_all() {
	# Documentation to be printed on first installation.
	DOC_CONTENTS="
	To preview reStructuredText buffers in Vim, install NeoBundle and add the
	following lines to your Vim configuration (e.g., \"~/.vimrc\"):\\n
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

	# Install Gentoo-specific documentation.
	readme.gentoo_create_doc

	# Install this package.
	distutils-r1_python_install_all
}

# On first installation, print Gentoo-specific documentation.
pkg_postinst() {
	readme.gentoo_print_elog
}

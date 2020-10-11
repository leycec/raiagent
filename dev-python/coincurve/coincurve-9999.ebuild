# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} pypy3 )

inherit distutils-r1

DESCRIPTION="Easy interface to the Bitcoin data structures and protocol"
HOMEPAGE="
	https://pypi.org/project/coincurve https://github.com/ofek/coincurve"

LICENSE="|| ( Apache-2.0 MIT )"
SLOT="0"
IUSE="gmp"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# Non-Python dependencies mostly derive from the following URL:
#     https://github.com/ofek/coincurve#contents
# The exception is "libsecp256k1", which derives from the "LIB_TARBALL_URL"
# global defined by the top-level "setup.py" script. Note that this URL embeds
# a Git commit hash corresponding to the minimum commit of the live repository
# for "libsecp256k1" required by "coincurve". Insanely, "libsecp256k1" has yet
# to release a stable version. Since this minimum commit is more recent than
# the most recent unstable package tagged in Portage for this package, we
# necessarily package this minimum commit ourselves. (It is bad, guys.)
#
# Note that "autotools" is *NOT* a dependency of "coincurve", despite being 
# prominently listed at the above URL. "coincurve" only requires "autotools"
# when manually downloading and recompiling "libsecp256k1", which we avoid.
BDEPEND="
	virtual/pkgconfig
	>=dev-python/setuptools-3.3[${PYTHON_USEDEP}]
"
RDEPEND="${PYTHON_DEPS}
	$(python_gen_cond_dep \
		'>=dev-python/cffi-1.3.0:=[${PYTHON_USEDEP}]' 'python*')
	dev-python/asn1crypto[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	>=dev-libs/libsecp256k1-0.1_pre20190331[ecdh,experimental]
	gmp? ( dev-libs/gmp:* )
"
DEPEND="${RDEPEND}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/ofek/coincurve.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

python_prepare_all() {
	# Reduce the download_library() function defined by "setup.py" to a noop.
	sed -i -e \
		's~^\(def download_library(command):\)$~\1 return\ndef muh_noop(command):~' \
		setup.py || die '"sed" failed.'

	distutils-r1_python_prepare_all
}

python_compile() {
	# The top-level "setup_support.py" script imported by "setup.py" requires
	# the "${LIB_DIR}" environment variable for detection of system-wide
	# "pkg-config" and "libsecp256k1" files. Oh, boy.
	LIB_DIR="${EPREFIX}/usr/$(get_libdir)" distutils-r1_python_compile
}

python_install_all() {
	dodoc *.rst
	distutils-r1_python_install_all
}

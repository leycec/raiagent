# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )

inherit distutils-r1

DESCRIPTION="Bioelectric Tissue Simulation Engine (BETSE)"
HOMEPAGE="https://gitlab.com/betse/betse"

LICENSE="BSD-2"
SLOT="0"
IUSE="ffmpeg graph profile +smp test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

#FIXME: Restore the following "smp?"-specific dependency to the requirements
#below *AFTER* Portage offers official support for ACML.
		# sci-libs/acml[eselect-ldso]

# This list of mandatory dependencies derives directly from the
# "betse.metadata.DEPENDENCIES_RUNTIME_MANDATORY" list, which is enforced at
# BETSE runtime and hence guaranteed to be authorative.
#
# For uniformity across *ALL* Python releases, the technically optional
# "dev-python/distro" dependency replacing the deprecated
# platform.linux_distribution() function removed by Python 3.8 is treated here
# as a mandatory dependency. While a USE flag governing the installation of
# this dependency could also be introduced (e.g., "distro"), doing so would be
# complicated by the version-specific conditionality of this dependency --
# which is optional only under Python <= 3.7 and is otherwise mandatory.
COMMON_DEPEND="${PYTHON_DEPS}
	>=dev-python/dill-0.2.3[${PYTHON_USEDEP}]
	>=dev-python/distro-1.0.4[${PYTHON_USEDEP}]
	>=dev-python/matplotlib-1.5.0[${PYTHON_USEDEP}]
	>=dev-python/numpy-1.13.0[${PYTHON_USEDEP}]
	>=dev-python/pillow-2.3.0[${PYTHON_USEDEP}]
	>=dev-python/ruamel-yaml-0.15.35[${PYTHON_USEDEP}]
	>=dev-python/setuptools-38.2.0[${PYTHON_USEDEP}]
	>=dev-python/six-1.5.2[${PYTHON_USEDEP}]
	>=sci-libs/scipy-0.12.0[${PYTHON_USEDEP}]
"
	# >=dev-python/psutil-5.3.0[${PYTHON_USEDEP}]
DEPEND="${COMMON_DEPEND}
	test? ( >=dev-python/pytest-3.7.0[${PYTHON_USEDEP}] )
"

# The list of multicore-aware BLAS implementations required by the "smp" USE
# flag derives directly from the docstring of the
# "betse.lib.numpy.numpys._OPTIMIZED_BLAS_OPT_INFO_LIBRARY_REGEX" (admittedly,
# a non-ideal home for critical documentation).
#
# The remaining list of optional dependencies derives directly from the
# "betse.metadata.DEPENDENCIES_RUNTIME_OPTIONAL" list, which is enforced at
# BETSE runtime and hence guaranteed to be authorative.
RDEPEND="${COMMON_DEPEND}
	ffmpeg? ( virtual/ffmpeg )
	graph? (
		>=dev-python/pydot-1.2.3[${PYTHON_USEDEP}]
		>=dev-python/networkx-2.1[${PYTHON_USEDEP}]
	)
	profile? ( >=dev-python/pympler-0.4.2[${PYTHON_USEDEP}] )
	smp? ( || (
		sci-libs/openblas[eselect-ldso]
		sci-libs/blis[eselect-ldso]
		sci-libs/mkl-rt[eselect-ldso]
	) )
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://gitlab.com/betse/betse.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

# Run tests with verbose output failing on the first failing test.
python_test() {
	py.test -vvx || die "Tests fail under ${EPYTHON}."
}

python_install_all() {
	distutils-r1_python_install_all

	# Recursively install all available documentation.
	dodoc -r README.rst doc/*
}

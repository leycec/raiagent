# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python3_{4,5,6} )

inherit distutils-r1

DESCRIPTION="Bioelectric Tissue Simulation Engine (BETSE)"
HOMEPAGE="https://gitlab.com/betse/betse"

LICENSE="BSD-2"
SLOT="0"
IUSE="ffmpeg graph profile +smp test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# This list of mandatory dependencies derives directly from the
# "betse.metadata.DEPENDENCIES_RUNTIME_MANDATORY" list, which is enforced at
# BETSE runtime and hence guaranteed to be authorative.
COMMON_DEPEND="${PYTHON_DEPS}
	>=dev-python/dill-0.2.3[${PYTHON_USEDEP}]
	>=dev-python/matplotlib-1.5.0[${PYTHON_USEDEP}]
	>=dev-python/numpy-1.8.2[${PYTHON_USEDEP}]
	>=dev-python/pillow-2.3.0[${PYTHON_USEDEP}]
	>=dev-python/setuptools-3.3[${PYTHON_USEDEP}]
	>=dev-python/six-1.5.2[${PYTHON_USEDEP}]
	>=sci-libs/scipy-0.12.0[${PYTHON_USEDEP}]
	>=dev-python/pyyaml-3.10[${PYTHON_USEDEP}]
"
#FIXME: Insert above after officially supporting "ruamel.yaml".
	# || (
	# 	>=dev-python/ruamel-yaml-0.15.0[${PYTHON_USEDEP}]
	# 	>=dev-python/pyyaml-3.10[${PYTHON_USEDEP}]
	# )

DEPEND="${COMMON_DEPEND}
	test? ( dev-python/pytest[${PYTHON_USEDEP}] )
"

# If the "smp" USE flag is enabled, increase the likelihood of multicore-aware
# NumPy operation by requiring that at least one CBLAS implementation be
# currently installed. Note, however, that this does *NOT* guarantee NumPy to be
# linked against this implementation; there appears to be no sane means of
# enforcing this constraint from within an ebuild. Instead, a post-installation
# message is subsequently logged advising the user to do so manually.
#
# All of the multicore-aware CBLAS implementations listed below are *ONLY*
# available from the third-party "science" overlay, which also publishes a
# custom "eselect" implementation. To link NumPy against such an implementation:
#
# * This implementation must be manually installed (e.g., to ensure that the
#   desired implementation is installed).
# * This implementation must be manually selected via "eselect blas".
# * NumPy must be manually reinstalled.
#
# In short, these steps *CANNOT* be automated by this ebuild. This list of
# multicore-aware CBLAS implementations derives from the docstring of the
# "betse.lib.numpy.numpys._OPTIMIZED_BLAS_OPT_INFO_LIBRARY_REGEX" -- admittedly,
# hardly the ideal location for such documentation.
#
# The remaining list of optional dependencies derives directly from the
# "betse.metadata.DEPENDENCIES_RUNTIME_OPTIONAL" list, which is enforced at
# BETSE runtime and hence guaranteed to be authorative.
RDEPEND="${COMMON_DEPEND}
	ffmpeg? ( virtual/ffmpeg )
	graph? (
		>=dev-python/pydot-1.2.3[${PYTHON_USEDEP}]
		>=dev-python/networkx-1.8[${PYTHON_USEDEP}]
		!=dev-python/networkx-1.11
	)
	profile? ( >=dev-python/pympler-0.4.2[${PYTHON_USEDEP}] )
	smp? ( || (
		sci-libs/acml
		sci-libs/atlas[threads]
		sci-libs/mkl
		sci-libs/openblas[threads]
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

# Notify users of how to properly enable multicore support. See comments above.
pkg_pretend() {
	# Ideally, the following warning would only be logged if both the "smp" USE
	# flag is enabled *AND* the version of the "app-admin/eselect" ebuild
	# provided by the "science" overlay is not installed. Unfortunately, Portage
	# does not appear to provide a means of testing this. The following *SHOULD*
	# work, as a valid atom is specified: e.g.,
	#
	#     if use smp; then
	#         if ! has_version '>=app-admin/eselect-1.4.8-r100::science'; then
	#             ewarn ...
	#         fi
	#     else
	#
	# Sadly, the has_version() function appears to support only a subset of the
	# atom language, resulting in:
	#
	#     has_version: Invalid atom: >=app-admin/eselect-1.4.8-r100::science
	#
	# Thanks for nuthin', has_version(). Until that function is improved to
	# parse atoms suffixed by overlay names, this function has little recourse
	# but to log this warning unconditionally. Sumthin' is better than nuthin'.
	if use smp; then
		ewarn 'Symmetric multiprocessing (SMP) support requires the optimized'
		ewarn 'BLAS and LAPACK stack published by the "science" overlay.'
		ewarn 'Although installation of this stack is non-trivial, failing to'
		ewarn 'do so will reduce BETSE to unoptimized single-core operation.'
		ewarn 'To install this stack, follow the instructions at:'
		ewarn 'https://wiki.gentoo.org/wiki/User_talk:Houseofsuns'
	else
		ewarn 'Symmetric multiprocessing (SMP) support disabled, reducing BETSE'
		ewarn 'to single-core operation. (This is bad.)'
	fi
}

# Run tests with verbose output failing on the first failing test.
python_test() {
	py.test -vvx betse_test || die "Tests fail under ${EPYTHON}."
}

python_install_all() {
	distutils-r1_python_install_all

	# Recursively install all available documentation.
	dodoc -r README.rst doc/*
}

# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..9} )

# inherit llvm toolchain-funcs distutils-r1
inherit multipprocessing python-r1 cmake

DESCRIPTION="Python wrapper for OCCT generated using pywrap"
HOMEPAGE="https://github.com/CadQuery/OCP"
SRC_URI="https://github.com/CadQuery/OCP/archive/refs/tags/${PV}.tar.gz"

LICENSE="Apache-2.0"
KEYWORDS="~amd64 ~x86"
SLOT="0"

	# dev-util/ninja
BDEPEND="
	~dev-python/cq-pywrap-${PV}[${PYTHON_USEDEP}]
	~sci-libs/opencascade-7.4.0
"
DEPEND="${RDEPEND}"

MY_PN=OCP
MY_P="${MY_PN}-${PV}"

S="${WORKDIR}/${MY_P}"

src_unpack() {
	default
	rm -rf pywrap || die  # unvendor vendored "pywrap" subdirectory
}

src_prepare() {
	default
	python_copy_sources
}

# OCP currently requires manual compilation as performed by the conda-specific
# "${S}/build-bindings-job.yml" file.
src_compile() {
	_NPROC=$(get_nproc)

	cq-ocp_compile() {
		${EPYTHON} -m bindgen -n $_NPROC parse     ocp.toml out.pkl
		${EPYTHON} -m bindgen -n $_NPROC transform ocp.toml out.pkl out_f.pkl
		${EPYTHON} -m bindgen -n $_NPROC generate  ocp.toml         out_f.pkl
	}

	python_foreach_impl cq-ocp_compile
}

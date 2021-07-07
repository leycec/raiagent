# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..9} )

# inherit llvm toolchain-funcs distutils-r1
inherit multiprocessing python-r1 cmake

DESCRIPTION="Python wrapper for OCCT generated using pywrap"
HOMEPAGE="https://github.com/CadQuery/OCP"
SRC_URI="https://github.com/CadQuery/OCP/archive/refs/tags/${PV}.tar.gz"

LICENSE="Apache-2.0"
KEYWORDS="~amd64 ~x86"
SLOT="0"

#FIXME: When bumping to "cadquery-ocp-7.5.*", also list the "json" USE here.
RDEPEND="~sci-libs/opencascade-7.4.0[tbb,vtk]"
DEPEND="${RDEPEND}
	~dev-python/cadquery-pywrap-${PV}[${PYTHON_USEDEP}]
"

MY_PN=OCP
MY_P="${MY_PN}-${PV}"

S="${WORKDIR}/${MY_P}"

# Unvendor the vendored "pywrap/" subdirectory.
src_unpack() {
	default
	rm -rf pywrap || die
}

src_prepare() {
	default
	python_copy_sources

	cadquery-ocp_src_prepare() {
		${EPYTHON} -m bindgen -n ${_NPROC} parse     ocp.toml out.pkl
		${EPYTHON} -m bindgen -n ${_NPROC} transform ocp.toml out.pkl out_f.pkl
		${EPYTHON} -m bindgen -n ${_NPROC} generate  ocp.toml         out_f.pkl

		# mkdir -p "${MY_P}" || die
		# cp -a out*.pkl "${MY_P}"/ || die
		echo "BUILD_DIR: ${BUILD_DIR}"
		cp -a out*.pkl "${BUILD_DIR}/" || die

		cmake_src_prepare
	}
	python_foreach_impl cadquery-ocp_src_prepare
}

# OCP currently requires manual configuration, compilation, and installation as
# performed by the conda-specific "${S}/build-bindings-job.yml" file.
src_configure() {
	local _NPROC="$(get_nproc)"

	cadquery-ocp_src_configure() {
		echo "BUILD_DIR: ${BUILD_DIR}"

		#FIXME: Pe probably also need to pass these VTK-specific paths:
		#    -DCMAKE_CXX_STANDARD_LIBRARIES="${EPREFIX}/usr/lib64/libvtkWrappingPythonCore-${_VTK_VERSION}.so"
		#    -DCMAKE_CXX_FLAGS=-I\ "${_VTK_INCLUDE_DIR}"

		# local mycmakeargs=(
		# 	"${mycmakeargs[@]}"
		# 	-DPYTHON_CONFIG_SUFFIX="-${EPYTHON}"
		# 	-DPYTHON_EXECUTABLE="${PYTHON}"
		# 	-DUSE_PYTHON_VERSION="${EPYTHON#python}"
		# )

		#FIXME: Call cmake_src_configure() instead.
		cmake_src_configure

		# -S <path-to-source>          = Explicitly specify a source directory.
		# -B <path-to-build>           = Explicitly specify a build directory.
		# cmake -B build -S "${_output}"
	}
	python_foreach_impl cadquery-ocp_src_configure
}

src_compile() {
	cadquery-ocp_src_compile() {
		echo "BUILD_DIR: ${BUILD_DIR}"

		#FIXME: Call cmake_src_compile() instead.
		cmake_src_compile
		# cmake_src_compile --build "${BUILD_DIR}"

		# _NPROC=$(get_nproc)
		# cmake --build build -j ${_NPROC} -- -k 0
	}
	python_foreach_impl cadquery-ocp_src_compile
}

src_install() {
	python_moduleinto OCP

	cadquery-ocp_src_install() {
		echo "BUILD_DIR: ${BUILD_DIR}"

		#FIXME: This almost certainly isn't quite right... *shrug*
		python_domodule OCP.cp*-*.*
	}
	python_foreach_impl cadquery-ocp_src_install
}

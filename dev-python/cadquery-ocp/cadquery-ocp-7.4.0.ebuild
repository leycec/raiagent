# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..9} )

inherit llvm multiprocessing cmake python-r1

MY_PYWRAP_PN=occt
MY_PYWRAP_PV=$(ver_cut 1-2)
MY_PYWRAP_P="${MY_PYWRAP_PN}${MY_PYWRAP_PV}"

DESCRIPTION="Python wrapper for OCCT generated using pywrap"
HOMEPAGE="https://github.com/CadQuery/OCP"
SRC_URI="https://github.com/CadQuery/OCP/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
KEYWORDS="~amd64 ~x86"
SLOT="0"

#FIXME: On bumping to 7.5.x, also list the "json" USE here.
RDEPEND="~sci-libs/opencascade-7.4.0[tbb,vtk]"
DEPEND="${RDEPEND}
	~dev-python/cadquery-pywrap-${PV}[${PYTHON_USEDEP}]
"

MY_PN=OCP
MY_P="${MY_PN}-${PV}"

S="${WORKDIR}/${MY_P}"
BUILD_DIR="${S}"

# Ensure the path returned by get_llvm_prefix() contains clang as well.
llvm_check_deps() {
	has_version -r "sys-devel/clang:${LLVM_SLOT}"
}

#FIXME: Don't submit this without getting "lief" working, as we almost
#certainly need to rebuild symbols on Gentoo. Specifically:
#* Publish our own "dev-util/lief" ebuild. *sigh*
#* Unvendor bundled "symbols_mangled_*.dat" files above: e.g.,
#      rm -rf pywrap || die
#      rm symbols_mangled_*.dat || die
#* Symlink "/usr/lib64/opencascade-7.4.0/ros/lib64/" to a new directory
#  resembling "${T}/lib_linux/".
#* Run the following command, which expects "libTK*.so.7.4.0" files to exist in
#  the "lib_linux/" subdirectory of the passed directory:
#      ${EPYTHON} dump_symbols.py "${T}"

# OCP currently requires manual configuration, compilation, and installation as
# performed by the conda-specific "build-bindings-job.yml" file.
src_prepare() {
	default
	python_copy_sources

	# Number of available hardware processors.
	local _NPROC="$(get_nproc)"

	# Most recently installed version of Clang.
	local _CLANG_VERSION="$(CPP=clang clang-fullversion)"

	# Absolute dirname of the most recently installed Clang include directory,
	# mimicing similar logic in the "dev-python/shiboken2" ebuild. See also:
	#     https://bugs.gentoo.org/619490
	local _CLANG_INCLUDE_DIR="${EPREFIX}/usr/lib/clang/${_CLANG_VERSION}/include"

	# Absolute filename of the most recently installed Clang shared library.
	local _CLANG_LIB_FILE="$(get_llvm_prefix)/lib64/libclang.so"

	# Most recently installed version (excluding trailing patch) of VTK.
	local _VTK_VERSION="$(best_version -r sci-libs/vtk)"
	_VTK_VERSION="$(ver_cut 1-2 "${_VTK_VERSION##sci-libs/vtk}")"

	# Absolute dirname of the most recently installed VTK include directory,
	local _VTK_INCLUDE_DIR="${EPREFIX}/usr/include/vtk-${_VTK_VERSION}"

	# Ensure the above paths exist (as a crude sanity check).
	test -d "${_CLANG_INCLUDE_DIR}" || die "${_CLANG_INCLUDE_DIR} not found."
	test -f "${_CLANG_LIB_FILE}"    || die "${_CLANG_LIB_FILE} not found."
	test -d "${_VTK_INCLUDE_DIR}"   || die "${_VTK_INCLUDE_DIR} not found."

	# "dev-python/clang-python" atom targeting this Clang version.
	local _CLANG_PYTHON_ATOM="dev-python/clang-python-${_CLANG_VERSION}"

	# Ensure "dev-python/clang-python" targets this Clang version.
	has_version -r "=${_CLANG_PYTHON_ATOM}" ||
		die "${_CLANG_PYTHON_ATOM} not installed."

	cadquery-ocp_src_prepare() {
		#FIXME: python_foreach_impl() should do this for us, but doesn't. This
		#is probably an eclass conflict between "python-r1" and "cmake".
		# cd "${BUILD_DIR}" || die
		echo 'bindgen pwd: '${PWD}

		${EPYTHON} -m bindgen \
			--verbose \
			--libclang "${_CLANG_LIB_FILE}" \
			--include "${_CLANG_INCLUDE_DIR}" \
			--include "${_VTK_INCLUDE_DIR}" \
			--njobs ${_NPROC} \
			all ocp.toml

		cmake_src_prepare
	}
	python_foreach_impl cadquery-ocp_src_prepare
}

src_configure() {
	#FIXME: Pe probably also need to pass these VTK-specific paths:
	# local mycmakeargs=(
	#    -DCMAKE_CXX_STANDARD_LIBRARIES="${EPREFIX}/usr/lib64/libvtkWrappingPythonCore-${_VTK_VERSION}.so"
	#    -DCMAKE_CXX_FLAGS=-I\ "${_VTK_INCLUDE_DIR}"
	# )

	cadquery-ocp_src_configure() {
		echo "BUILD_DIR: ${BUILD_DIR}"

		cmake_src_configure

		#FIXME: Excise us up.
		# -S <path-to-source>          = Explicitly specify a source directory.
		# -B <path-to-build>           = Explicitly specify a build directory.
		# cmake -B build -S "${_output}"
	}
	python_foreach_impl cadquery-ocp_src_configure
}

src_compile() {
	cadquery-ocp_src_compile() {
		echo "BUILD_DIR: ${BUILD_DIR}"

		cmake_src_compile

		#FIXME: Excise us up.
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
		python_domodule "${BUILD_DIR}"/OCP.cp*-*.*
	}
	python_foreach_impl cadquery-ocp_src_install
}

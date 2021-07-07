# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..9} )

inherit llvm toolchain-funcs distutils-r1

MY_PN=occt
MY_PV=$(ver_cut 1-2)
MY_P="${MY_PN}${MY_PV}"

DESCRIPTION="C++ binding generator based on libclang and pybind11"
HOMEPAGE="https://github.com/CadQuery/pywrap"
SRC_URI="https://github.com/CadQuery/pywrap/archive/refs/tags/${MY_P}.tar.gz"

LICENSE="Apache-2.0"
KEYWORDS="~amd64 ~x86"
SLOT="0"

# Dependencies are intentionally listed in "setup.py" order.
RDEPEND="
	dev-python/click[${PYTHON_USEDEP}]
	dev-python/logzero[${PYTHON_USEDEP}]
	dev-python/path-py[${PYTHON_USEDEP}]
	dev-python/clang-python[${PYTHON_USEDEP}]
	dev-python/cymbal[${PYTHON_USEDEP}]
	dev-python/toml[${PYTHON_USEDEP}]
	dev-python/pandas[${PYTHON_USEDEP}]
	>=dev-python/joblib-1.0.0[${PYTHON_USEDEP}]
	dev-python/tqdm[${PYTHON_USEDEP}]
	dev-python/jinja[${PYTHON_USEDEP}]
	dev-python/toposort[${PYTHON_USEDEP}]
	dev-python/pyparsing[${PYTHON_USEDEP}]
	dev-python/pybind11[${PYTHON_USEDEP}]
	dev-python/schema[${PYTHON_USEDEP}]
	sci-libs/vtk
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/pywrap-${MY_P}"

# Ensure the path returned by get_llvm_prefix() contains clang as well.
llvm_check_deps() {
	has_version -r "sys-devel/clang:${LLVM_SLOT}"
}

src_prepare() {
	# Most recently installed version of Clang.
	local _CLANG_VERSION="$(CPP=clang clang-fullversion)"

	# Absolute dirname of the most recently installed Clang include directory,
	# mimicing similar logic in the "dev-python/shiboken2" ebuild. See also:
	#     https://bugs.gentoo.org/619490
	local _CLANG_INCLUDE_DIR="${EPREFIX}/usr/lib/clang/${_CLANG_VERSION}/include"

	# Absolute filename of the most recently installed Clang shared library.
	local _CLANG_LIB_FILE="$(get_llvm_prefix)/lib64/libclang.so"

	# "dev-python/clang-python" atom targeting this Clang version.
	local _CLANG_PYTHON_ATOM="dev-python/clang-python-${_CLANG_VERSION}"

	# Most recently installed version (excluding trailing patch) of VTK.
	local _VTK_VERSION="$(best_version -r sci-libs/vtk)"
	_VTK_VERSION="$(ver_cut 1-2 "${_VTK_VERSION##sci-libs/vtk}")"

	# Absolute dirname of the most recently installed VTK include directory,
	local _VTK_INCLUDE_DIR="${EPREFIX}/usr/include/vtk-${_VTK_VERSION}"

	# Ensure "dev-python/clang-python" targets this Clang version.
	has_version -r "=${_CLANG_PYTHON_ATOM}" ||
		die "${_CLANG_PYTHON_ATOM} not installed."

	# Ensure the above paths exist (as a crude sanity check).
	test -d "${_CLANG_INCLUDE_DIR}" || die "${_CLANG_INCLUDE_DIR} not found."
	test -f "${_CLANG_LIB_FILE}"    || die "${_CLANG_LIB_FILE} not found."
	test -d "${_VTK_INCLUDE_DIR}"   || die "${_VTK_INCLUDE_DIR} not found."

	#FIXME: Remove this line and file on the next ebuild bump.
	# Inject "setup.py" from the live "pywrap" repository.
	cp "${FILESDIR}/${P}.setup.py" setup.py || die

	# Relax Jinja version requirements. See also this upstream pull request:
	#     https://github.com/CadQuery/pywrap/pull/34
	sed -i -e "s~'jinja2==\\(.*\\)',~'jinja2>=\\1,<4',~" setup.py || die
	sed -i \
		-e 's~^\({%- macro super(cls,classes,typedefs\)\() -%}\)$~\1=[]\2~' \
		bindgen/macros.j2 || die

	# Sanitize the "bindgen" version to avoid Gentoo QA notices. See also:
	#     https://www.python.org/dev/peps/pep-0440/#id24
	sed -i -e 's~\(version="0.1\)dev"~\1a1"~' setup.py || die

	# Replace conda- with Gentoo-specific root dirnames.
	sed -i -e "s~\\bgetenv('CONDA_PREFIX')~'${EPREFIX}/usr'~" bindgen/*.py ||
		die

	#FIXME: When bumping to "cadquery-pywrap-7.5.*":
	#* Reduce the following fragile and thus problematic block to simply:
	#      sed -i -e 's~rv\.append(Path(prefix).*~True~' bindgen/utils.py || die
	#* Pass the same paths to each "bindgen" call in "cadquery-ocp-7.5.*" with:
	#      bindgen \
	#          -l "${_CLANG_LIB_FILE}" \
	#          -i "${_CLANG_INCLUDE_DIR}" \
	#          -i "${_VTK_INCLUDE_DIR}"
	#Sadly, bindgen 7.4.0 fails to support the "-l" and "-i" options.

	# Replace hardcoded paths with Gentoo-specific paths: i.e.,
	# * Replace the first hardcoded Clang include dirnames with the VTK
	#   include dirname above.
	# * Remove all other hardcoded Clang include dirnames except the last.
	# * Replace the last hardcoded Clang include dirname with the above.
	# * Replace the hardcoded Clang shared library filename with the above.
	sed -i \
		-e "0,\\~\\bPath(prefix) / 'lib/clang/.*/include/'~s~~'${_VTK_INCLUDE_DIR}'~" \
		-e   "\\~\\bPath(prefix) / 'lib/clang/.*/include/'~d" \
		-e "s~\\bPath(prefix) / 'include/c++/v1/'~'${_CLANG_INCLUDE_DIR}'~" \
		-e "s~\\bconda_prefix / 'lib' / 'libclang.so'~'${_CLANG_LIB_FILE}'~" \
		bindgen/utils.py || die

	distutils-r1_src_prepare
	eapply_user
}

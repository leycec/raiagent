# Copyright 2021-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..11} )

inherit cmake python-single-r1

IUSE="+bzip2 +lz4 +parquet +python +zlib +zstd"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

DESCRIPTION="A cross-language development platform for in-memory data"
HOMEPAGE="https://arrow.apache.org/"
SRC_URI="https://www.apache.org/dyn/closer.lua?action=download&filename=arrow/arrow-${PV}/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

RDEPEND="
	dev-java/brotli-dec
	lz4? ( app-arch/lz4:= )
	bzip2? ( app-arch/bzip2 )
	parquet? (
		dev-libs/libutf8proc:=
		dev-libs/re2:=
		dev-libs/thrift
	)
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			dev-python/numpy[${PYTHON_USEDEP}]
		')
	)
	zlib? ( sys-libs/zlib )
	zstd? ( app-arch/zstd:= )
"
DEPEND="
	${RDEPEND}
	dev-libs/rapidjson
	net-libs/grpc
	>=dev-cpp/xsimd-8.1
"

PATCHES=(
	"${FILESDIR}"/${PN}-9.0.0-thrift-limit.patch
)

S="${WORKDIR}/${P}/cpp"

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_prepare() {
	# use Gentoo CXXFLAGS, specify docdir at src_configure.
	sed -e '/SetupCxxFlags/d' \
		-e '/set(ARROW_DOC_DIR.*)/d' \
		-i CMakeLists.txt || die
	# xsimd version is managed by Gentoo.
	sed -e 's/resolve_dependency(xsimd.*)/resolve_dependency(xsimd)/' \
		-i cmake_modules/ThirdpartyToolchain.cmake || die
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DARROW_BUILD_STATIC=OFF
		-DARROW_BUILD_SHARED=ON
		-DARROW_CXXFLAGS="-DNDEBUG"
		-DARROW_DEPENDENCY_SOURCE=SYSTEM
		# TODO: Enable jemalloc and mimalloc support when time permits.
		-DARROW_DOC_DIR=share/doc/${PF}
		-DARROW_JEMALLOC=OFF
		-DARROW_PARQUET=$(usex parquet)
		-DARROW_PYTHON=$(usex python)
		-DARROW_USE_CCACHE=OFF # Use ccache via Portage
		-DARROW_WITH_BZ2=$(usex bzip2)
		# TODO: Temporarily force LZ4 support off until this issue is resolved:
		#     https://github.com/streamlit/streamlit/issues/5683
		-DARROW_WITH_LZ4=OFF
		# -DARROW_WITH_LZ4=$(usex lz4)
		-DARROW_WITH_ZLIB=$(usex zlib)
		-DARROW_WITH_ZSTD=$(usex zstd)
	)
	cmake_src_configure
}

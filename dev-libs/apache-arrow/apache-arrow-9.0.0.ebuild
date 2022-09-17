# Copyright 2021-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# CAUTION: Synchronize with upstream changes in the Spark overlay at:
#     https://github.com/gentoo-mirror/spark-overlay/tree/master/dev-libs/apache-arrow
# This package is a mandatory reverse dependency of PyArrow and thus Streamlit,
# copied as is from the Spark overlay into this overlay to streamline building.
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

EAPI=7

PYTHON_COMPAT=( python3_{8..11} )

inherit cmake python-single-r1

IUSE="+bzip2 +lz4 +parquet +python +zlib +zstd"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DESCRIPTION="A cross-language development platform for in-memory data."
HOMEPAGE="https://arrow.apache.org/"
SRC_URI="https://www.apache.org/dyn/closer.lua?action=download&filename=arrow/arrow-${PV}/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			dev-python/numpy[${PYTHON_USEDEP}]
		')
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	app-arch/lz4
	>=dev-cpp/xsimd-8.1
	dev-java/brotli-dec
	dev-libs/libutf8proc
	dev-libs/rapidjson
	dev-libs/re2
	dev-libs/thrift
	net-libs/grpc
"

S="${WORKDIR}/${P}/cpp"

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
		-DARROW_DEPENDENCY_SOURCE=SYSTEM
		-DARROW_BUILD_STATIC=OFF
		-DARROW_DOC_DIR=share/doc/${PF}
		-DARROW_JEMALLOC=OFF
		-DARROW_PARQUET=$(usex parquet ON OFF)
		-DARROW_WITH_BZ2=$(usex bzip2 ON OFF)
		-DARROW_WITH_LZ4=$(usex lz4 ON OFF)
		-DARROW_PYTHON=$(usex python ON OFF)
		-DARROW_WITH_ZLIB=$(usex zlib ON OFF)
		-DARROW_WITH_ZSTD=$(usex zstd ON OFF)
	)
	cmake_src_configure
}

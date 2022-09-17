# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# CAUTION: Synchronize with upstream changes in the Spark overlay at:
#     https://github.com/gentoo-mirror/spark-overlay/tree/master/dev-python/pyarrow
# This package is a mandatory reverse dependency of PyArrow and thus Streamlit,
# copied as is from the Spark overlay into this overlay to streamline building.
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

EAPI=8

PYTHON_COMPAT=( python3_{8..11} )

inherit distutils-r1 multiprocessing

DESCRIPTION="Python library for Apache Arrow"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
HOMEPAGE="https://arrow.apache.org/"

IUSE="+parquet"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="dev-util/cmake"
RDEPEND="
	>=dev-python/numpy-1.16.6[${PYTHON_USEDEP}]
	~dev-libs/apache-arrow-${PV}[parquet?]
"
DEPEND="${RDEPEND}"

distutils_enable_tests pytest

src_prepare() {
	default

	# arrow is in the standard location, making ARROW_LIB_DIR useless.
	sed -e "s/ARROW_INCLUDE_DIR ARROW_LIB_DIR//" \
		-i cmake_modules/FindArrow.cmake || die
}

src_compile() {
	export PYARROW_WITH_PARQUET=$(usex parquet "ON" "")
	local jobs=$(makeopts_jobs "${MAKEOPTS}" INF)
	export PYARROW_PARALLEL="${jobs}"
	export PYARROW_BUILD_VERBOSE="1"
	export PYARROW_BUNDLE_ARROW_CPP_HEADERS=0
	distutils-r1_src_compile
}

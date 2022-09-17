# Copyright 2021-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# CAUTION: Synchronize with upstream changes in the Spark overlay at:
#     https://github.com/gentoo-mirror/spark-overlay/tree/master/dev-cpp/xsimd
# This package is a mandatory reverse dependency of PyArrow and thus Streamlit,
# copied as is from the Spark overlay into this overlay to streamline building.
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

EAPI=7

CMAKE_MAKEFILE_GENERATOR="emake"

inherit cmake

DESCRIPTION="C++ wrappers for SIMD intrinsics and math implementations"
HOMEPAGE="https://github.com/xtensor-stack/xsimd"
SRC_URI="https://github.com/xtensor-stack/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

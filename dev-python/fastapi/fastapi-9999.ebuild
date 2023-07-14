# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{10..12} pypy3 )

inherit distutils-r1

DESCRIPTION="FastAPI framework, high performance, easy to learn, fast to code"
HOMEPAGE="
	https://fastapi.tiangolo.com
	https://pypi.org/project/fastapi
	https://github.com/tiangolo/fastapi
"

LICENSE="MIT"
SLOT="0"

BDEPEND=">=dev-python/hatchling-1.13.0[${PYTHON_USEDEP}]"
RDEPEND="
	>=dev-python/pydantic-1.7.4[${PYTHON_USEDEP}]
	>=dev-python/starlette-0.27.0[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.5.0[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

#FIXME: Enable tests when time allows, please.
RESTRICT="test"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/tiangolo/fastapi"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	inherit pypi

	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

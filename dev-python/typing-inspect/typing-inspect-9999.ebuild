# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..11} pypy3 )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="Runtime inspection utilities for typing module"
HOMEPAGE="
	https://pypi.org/project/typing-inspect
	https://github.com/ilevkivskyi/typing_inspect
"

LICENSE="MIT"
SLOT="0"

RDEPEND="
	>=dev-python/mypy_extensions-0.3.0[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-3.7.4[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

distutils_enable_tests pytest

EPYTEST_DESELECT=(
	# https://github.com/ilevkivskyi/typing_inspect/issues/84
	'test_typing_inspect.py::GetUtilityTestCase::test_typed_dict_typing_extension'
)

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/ilevkivskyi/typing_inspect.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	MY_PN=${PN/-/_}
	MY_P=${MY_PN}-${PV}

	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"

	S="${WORKDIR}/${MY_P}"
fi

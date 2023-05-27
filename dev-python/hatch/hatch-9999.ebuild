# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# CAUTION: This ebuild is largely copy-and-pasted from the official Portage
# ebuild for "hatchling", the Hatch-specific build system required by Hatch.
# Hatch and "hatchling" share the same GitHub repository and thus a similar
# workflow for building and installation.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

DISTUTILS_USE_PEP517=hatchling
PYTHON_TESTED=( pypy3 python3_{10..11} )
PYTHON_COMPAT=( "${PYTHON_TESTED[@]}" python3_12 )

inherit distutils-r1

TAG=${P/-/-v}
MY_P=hatch-${TAG}
DESCRIPTION="Modern, extensible Python project management"
HOMEPAGE="
	https://hatch.pypa.io
	https://pypi.org/project/hatch
	https://github.com/pypa/hatch
"

LICENSE="MIT"
SLOT="0"

# deps are listed in pyproject.toml
BDEPEND=">=dev-python/hatchling-1.14.0[${PYTHON_USEDEP}]"
RDEPEND="${BDEPEND}
	>=dev-python/click-8.0.3[${PYTHON_USEDEP}]
	>=dev-python/httpx-0.22.0[${PYTHON_USEDEP}]
	>=dev-python/hyperlink-21.0.0[${PYTHON_USEDEP}]
	>=dev-python/keyring-23.5.0[${PYTHON_USEDEP}]
	>=dev-python/packaging-21.3[${PYTHON_USEDEP}]
	>=dev-python/pexpect-4.8[${PYTHON_USEDEP}]
	>=dev-python/platformdirs-2.5.0[${PYTHON_USEDEP}]
	>=dev-python/pyperclip-1.8.2[${PYTHON_USEDEP}]
	>=dev-python/rich-11.2.0[${PYTHON_USEDEP}]
	>=dev-python/shellingham-1.4.0[${PYTHON_USEDEP}]
	>=dev-python/tomli-w-1.0[${PYTHON_USEDEP}]
	>=dev-python/tomlkit-0.11.1[${PYTHON_USEDEP}]
	>=dev-python/userpath-1.7[${PYTHON_USEDEP}]
	>=dev-python/virtualenv-20.16.2[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

#FIXME: Tests are currently disabled, as (A) we could personally care less, (B)
#this repository mostly exists just to satisfy my own packaging OCD, (C) Hatch
#tests are likely to prove extremely non-trivial to support offline, and (D) the
#full set of all test-time dependencies required by Hatch is unknown. In short:
#        "Meh."
RESTRICT="test"
# distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/pypa/hatch"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="
		https://github.com/pypa/hatch/archive/${TAG}.tar.gz
			-> ${MY_P}.gh.tar.gz
	"
	KEYWORDS="~amd64 ~arm ~arm64 ~hppa ~ia64 ~loong ~m68k ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux ~arm64-macos ~ppc-macos ~x64-macos ~x64-solaris"

	S=${WORKDIR}/${MY_P}
fi

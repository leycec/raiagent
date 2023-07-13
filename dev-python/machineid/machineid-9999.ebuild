# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..12} pypy3 )

inherit distutils-r1

DESCRIPTION="Get the unique machine ID of any host (without admin privileges)"
HOMEPAGE="
	https://pypi.org/project/machineid
	https://github.com/keygen-sh/py-machineid
"

LICENSE="MIT"
SLOT="0"

distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/keygen-sh/py-machineid.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	inherit pypi

	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

python_prepare_all() {
	# Prevent installation of Windows-specific dependencies.
	sed -i -e "s~'winregistry'~~g" setup.py || die

	distutils-r1_python_prepare_all
}

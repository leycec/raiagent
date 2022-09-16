# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..11} )

inherit distutils-r1

DESCRIPTION="Kivy garden installation script"
HOMEPAGE="https://github.com/kivy-garden/garden"

LICENSE="MIT"
SLOT="0"

DEPEND=""
RDEPEND="dev-python/requests[${PYTHON_USEDEP}]"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/kivy-garden/garden.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	# Note that this package is non-trivial to fetch from PyPI due to being
	# hosted at a non-standard host: e.g.,
	#     https://files.pythonhosted.org/packages/0b/33/9ad8dab579e7c48e95e7de6bf00b5e671c4ee1c0a57df140fb2d145ffe36/Kivy%20Garden-0.1.5.tar.gz
	SRC_URI="https://github.com/kivy-garden/garden/archive/refs/tags/v${PV}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"

	S="${WORKDIR}/garden-${PV}"
fi

python_prepare_all() {
	# Prevent Windows-specific batch files from being subsequently installed.
	sed -i -e "s~'bin/garden.bat'~~" setup.py || die '"sed" failed.'

	distutils-r1_python_prepare_all
}

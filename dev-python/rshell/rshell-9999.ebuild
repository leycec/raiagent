# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#FIXME: Sadly, rshell is currently incompatible with Python >= 3.10 due to its
#mandatory dependency on "pyreadline", which is dead and thus fails to support
#Python >= 3.10. See also this issue:
#    https://github.com/dhylands/rshell/issues/171
PYTHON_COMPAT=( python3_{8..9} )

inherit distutils-r1

DESCRIPTION="Remote Shell for MicroPython"
HOMEPAGE="https://github.com/dhylands/rshell"

LICENSE="MIT"
SLOT="0"
IUSE="+rsync"

RDEPEND="
	dev-python/pyserial[${PYTHON_USEDEP}]
	>=dev-python/pyudev-0.16[${PYTHON_USEDEP}]
	rsync? ( net-misc/rsync )
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/dhylands/rshell.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

#FIXME: Perform tests if the "test" USE flag is enabled. Doing so will be
#complicated by upstream's ad-hoc non-standard test suite. *sigh*
#FIXME: Remove this phase after upstream resolves this issue:
#    https://github.com/dhylands/rshell/issues/170
python_prepare_all() {
	# Avoid this setuptools deprecation warning:
	#     Usage of dash-separated 'description-file' will not be supported in
	#     future versions. Please use the underscore name 'description_file'
	#     instead
	sed -i -e "s~description-file~description_file~" setup.cfg ||
		die '"sed" failed.'

	# Prevent upstream from erroneously installing tests.
	sed -i -e "s~, 'tests'~~" setup.py || die '"sed" failed.'

	distutils-r1_python_prepare_all
}

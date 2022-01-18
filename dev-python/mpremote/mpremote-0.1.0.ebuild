# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} )

DISTUTILS_USE_SETUPTOOLS=pyproject.toml

inherit distutils-r1

# Note that there intentionally exists *NO* "mpremote-9999.ebuild", as
# "mpremote" is officially embedded with the official MicroPython repository
# itself (under the "tools/mpremote" subdirectory) rather than as an
# independent repository.
DESCRIPTION="MicroPython remote control"
HOMEPAGE="https://pypi.org/project/mpremote"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

BDEPEND="dev-python/wheel[${PYTHON_USEDEP}]"

# #FIXME: Perform tests if the "test" USE flag is enabled. Doing so will be
# #complicated by upstream's ad-hoc non-standard test suite. *sigh*
# #FIXME: Remove this phase after upstream resolves this issue:
# #    https://github.com/dhylands/rshell/issues/170
# python_prepare_all() {
# 	# Avoid this setuptools deprecation warning:
# 	#     Usage of dash-separated 'description-file' will not be supported in
# 	#     future versions. Please use the underscore name 'description_file'
# 	#     instead
# 	sed -i -e "s~description-file~description_file~" setup.cfg ||
# 		die '"sed" failed.'
#
# 	# Prevent upstream from erroneously installing tests.
# 	sed -i -e "s~, 'tests'~~" setup.py || die '"sed" failed.'
#
# 	distutils-r1_python_prepare_all
# }

# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} pypy3 )

inherit distutils-r1

DESCRIPTION="Python functions for thorough checks on types"
HOMEPAGE="https://pypi.org/project/typish"

# Prefer GitHub. Upstream failed to push its source tarball to PyPI.
SRC_URI="https://github.com/ramonhagenaars/typish/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
KEYWORDS="~amd64 ~x86"
SLOT="0"

#FIXME: Enable tests, which require "nptyping", which circularly requires
#"typish", which is insane. That's upstream for you.
RESTRICT="test"

src_prepare() {
	# Prevent "setup.py" from installing tests. See also:
	#     https://github.com/ramonhagenaars/typish/issues/28
	sed -i -e \
		"s~\\('tests', 'test_resources'\\)~\\1, 'tests.*', 'test_resources.*'~" \
		setup.py || die

	distutils-r1_src_prepare
}

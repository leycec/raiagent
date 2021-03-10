# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..9} )

DISTUTILS_USE_SETUPTOOLS=rdepend

inherit distutils-r1

DESCRIPTION="High-level app and dashboarding solution for Python"
HOMEPAGE="
	https://panel.holoviz.org
	https://pypi.org/project/panel
	https://github.com/holoviz/panel"

LICENSE="BSD"
SLOT="0"
IUSE=""

BDEPEND="
	>=dev-python/setuptools-30.3.0[${PYTHON_USEDEP}]
	>=net-libs/nodejs-15.11.0
"
DEPEND="
	>=dev-python/bokeh-2.3.0[${PYTHON_USEDEP}]
	>=dev-python/param-1.10.0[${PYTHON_USEDEP}]
	>=dev-python/pyct-0.4.4[${PYTHON_USEDEP}]
"
RDEPEND="
	dev-python/markdown[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/tqdm[${PYTHON_USEDEP}]
	>=dev-python/pyviz_comms-0.7.4[${PYTHON_USEDEP}]
"

#FIXME: *THIS IS HORRIBLE.* Instead, we should manually list *ALL* Node.js
#dependencies listed in the "panel/panel/package-lock.json" file above as
#${DEPEND} dependencies. Since packaging these dependencies as Gentoo packages
#is effectively infeasible with scarce time, this will have to do instead.

# Permit Panel to violate network sandboxing, as "setup.py" invokes "npm" to
# fetch and bundle Node.js assets with Panel.
RESTRICT=network-sandbox

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/holoviz/panel.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

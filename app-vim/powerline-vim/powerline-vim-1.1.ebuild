# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="5"

# Enforce Bash scrictness.
set -e

# Since eclasses cannot be conditionally inherited, this ebuild remains distinct
# from the top-level Powerline ebuild at "app-misc/powerline".
inherit vim-plugin

MY_PN='powerline-status'
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Vim plugin for Python-based Powerline"
HOMEPAGE="https://pypi.python.org/pypi/powerline-status"
SRC_URI="mirror://pypi/p/${MY_PN}/${MY_P}.tar.gz"
LICENSE="MIT"

SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86 ~x86-fbsd"
IUSE=""
DEPEND="|| (
	>=app-editors/vim-7.2[python]
	>=app-editors/gvim-7.2[python]
)"
RDEPEND="${DEPEND}
	~app-misc/powerline-${PV}
"

# Basename of this plugin's help file.
VIM_PLUGIN_HELPFILES="Powerline"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	# vim-plugin_src_install() expects ${S} to be the Vim plugin directory to be
	# installed to "/usr/share/vim/vimfiles". Ensure this by temporarily moving
	# such directory away, deleting everything remaining under ${S}, and moving
	# such directory back to ${S}.
	mkdir "${T}"/ignore
	mv "${S}"/powerline/bindings/vim "${T}"
	mv * "${T}"/ignore
	mv "${T}"/vim/* "${S}"

	# Remove all remaining Python files to prevent vim-plugin_src_install() from
	# installing such files as documentation.
	find . -type f -name '*.py' -delete

	# Remove nonstandard paths from the plugin's implementation.
	sed -i -e '/sys\.path\.append/d' "${S}"/plugin/powerline.vim
}

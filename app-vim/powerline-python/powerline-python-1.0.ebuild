# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="5"

# Enforce Bash scrictness.
set -e

# Since eclasses cannot be conditionally inherited, this ebuild remains distinct
# from the top-level Powerline ebuild at "app-misc/powerline".
inherit vim-plugin

DESCRIPTION="Vim plugin for Python-based Powerline"
HOMEPAGE="http://github.com/Lokaltog/powerline"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86 ~x86-fbsd"
IUSE=""
DEPEND="|| (
	>=app-editors/vim-7.2[python]
	>=app-editors/gvim-7.2[python]
)"
RDEPEND="${DEPEND}
	=app-misc/powerline-9999*
"

# Basename of this plugin's help file.
VIM_PLUGIN_HELPFILES="Powerline"

SRC_URI="https://pypi.python.org/packages/source/p/powerline-status/powerline-status-${PV}.tar.gz"

S="${WORKDIR}/powerline-status-${PV}"

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
	find "${S}" -type f -name '*.py' -delete

	# Remove nonstandard paths from the plugin's implementation.
	sed -i -e '/sys\.path\.append/d' "${S}"/plugin/powerline.vim
}

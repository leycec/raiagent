# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="6"

# Since eclasses cannot be conditionally inherited, this ebuild remains distinct
# from the top-level Powerline ebuild at "app-misc/powerline".
inherit vim-plugin

DESCRIPTION="Vim plugin for Python-based Powerline"
HOMEPAGE="https://pypi.python.org/pypi/powerline-status"

LICENSE="MIT"
SLOT="0"
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

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/powerline/powerline"
	EGIT_BRANCH="develop"
	KEYWORDS=""
else
	MY_PN="powerline-status"
	MY_P="${MY_PN}-${PV}"
	SRC_URI="mirror://pypi/p/${MY_PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~ppc ~x86 ~x86-fbsd"
	S="${WORKDIR}/${MY_P}"
fi

src_prepare() {
	# vim-plugin_src_install() expects that ${S} is the top-level directory for
	# the Vim plugin to be installed to "/usr/share/vim/vimfiles". To guarantee
	# this, that directory is moved to "${T}/vim", everything else
	# under ${S} is moved to "${T}/ignore", and that directory is moved back
	# directly into ${S}.
	mkdir "${T}"/ignore || die '"mkdir" failed.'
	mv "${S}"/powerline/bindings/vim "${T}" || die '"mv" failed.'
	mv * "${T}"/ignore || die '"mv" failed.'
	mv "${T}"/vim/* "${S}" || die '"mv" failed.'

	# Remove all remaining Java and Python files to prevent
	# vim-plugin_src_install() from installing such files as documentation.
	# Which, if you think about it, is a pretty terrible default behaviour.
	find . -type f '(' -name '*.class' -o -name '*.py' ')' -delete ||
		die '"find" failed.' 

	# Remove nonstandard paths from this plugin's implementation.
	sed -i -e '/sys\.path\.append/d' "${S}"/plugin/powerline.vim ||
		die '"sed" failed.'

	# Apply user-specific patches *AFTER* all requisite patches above.
	default_src_prepare
}

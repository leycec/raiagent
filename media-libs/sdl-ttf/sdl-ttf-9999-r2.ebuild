# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4
inherit eutils mercurial

MY_P="SDL_ttf-${PV}"
DESCRIPTION="TrueType font decoding add-on for SDL"
HOMEPAGE="http://www.libsdl.org/projects/SDL_ttf"
EHG_REPO_URI="http://hg.libsdl.org/SDL_ttf"

LICENSE="ZLIB"
SLOT="2"
KEYWORDS="~amd64 ~x86"

#FIXME: Add "test".
IUSE="showfont static-libs X"

RDEPEND="
	media-libs/libsdl:2
	>=media-libs/freetype-2.3
	X? ( x11-libs/libXt )
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_P}"

src_configure() {
	local myeconfargs=(
		--disable-imageio
		$(use_enable static-libs static)
		$(use_enable X x)
	)

	# See "sdl-image-9999.ebuild" for discussion.
	MISSING=true econf "${myeconfargs[@]}"
}

src_install() {
	default
	dodoc CHANGES README
	use static-libs || prune_libtool_files --all

	# Prevent SDL 2.0's "showfont" from colliding with SDL 1.2's "showfont".
	use showfont && newbin '.libs/showfont' "showfont-${SLOT}"
}

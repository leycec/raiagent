# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4
inherit eutils mercurial

MY_P="SDL_image-${PV}"
DESCRIPTION="Image file loading library"
HOMEPAGE="http://www.libsdl.org/projects/SDL_image"
EHG_REPO_URI="http://hg.libsdl.org/SDL_image"

LICENSE="ZLIB"
SLOT="2"
KEYWORDS="~amd64"

#FIXME: Add "test".
IUSE="
static-libs
gif jpeg png tiff webp xpm
"

RDEPEND="
	media-libs/libsdl:2
	>=sys-libs/zlib-1.2.5
	png? ( >=media-libs/libpng-1.5.7 )
	jpeg? ( virtual/jpeg )
	tiff? ( >=media-libs/tiff-4.0.0 )
	webp? ( >=media-libs/libwebp-0.1.3 )
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_P}"

src_configure() {
	local myeconfargs=(
		# Avoid the OS X-specific ImageIO library.
 		--disable-imageio 
 		$(use_enable static-libs static) 
 		$(use_enable gif) 
 		$(use_enable jpeg jpg) 
 		$(use_enable tiff tif) 
 		$(use_enable png) 
 		$(use_enable webp) 
 		$(use_enable xpm)
	)

	# SDL_image 2.0 ships with a demonstrably horrible "configure" script. By
	# default, this script adds globals to the created "Makefile" resembling:
	#
	#   AUTOCONF = /bin/sh /var/tmp/portage/media-libs/sdl-image-9999/work/SDL_image/missing --run autoconf-1.10
	#
	# On running "make", "Makefile" then attempts to run the expansion of
	# "$(AUTOCONF)". Since the system is unlikely to have autoconf-1.0, the
	# "missing" script naturally fails with non-zero exit status. To sidestep 
	# this insanity, force "configure" to instead set globals resembling:
	#
	#   AUTOCONF = true --run autoconf-1.10
	#
	# Since "true" always succeeds with zero exit status, this forces sanity.
	# SDL, I am not happy with you.
 	MISSING=true econf "${myeconfargs[@]}"
}

src_install() {
 	default
	dobin .libs/showimage
	dodoc CHANGES README
	use static-libs || prune_libtool_files --all
}

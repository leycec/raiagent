# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enable Bash strictness.
set -e

inherit autotools eutils mercurial

MY_P="SDL_image-${PV}"
DESCRIPTION="Image file loading library"
HOMEPAGE="http://www.libsdl.org/projects/SDL_image"
EHG_REPO_URI="http://hg.libsdl.org/SDL_image"

LICENSE="ZLIB"
SLOT="2/0.8.5"
KEYWORDS="~amd64 ~x86"

#FIXME: Add "test".
IUSE="
showimage static-libs
bmp gif jpeg pnm png tiff tga webp xcf xpm
"

RDEPEND="
	media-libs/libsdl:2=
	>=sys-libs/zlib-1.2.5
	jpeg? ( virtual/jpeg )
	png?  ( >=media-libs/libpng-1.5.7 )
	tiff? ( >=media-libs/tiff-4.0.0 )
	webp? ( >=media-libs/libwebp-0.1.3 )
"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	# SDL_image specifically requires libpng 1.5, but attempts to compile
	# against *ANY* libpng -- even if libpng 1.5 is not currently slotted to
	# "libpng.so". Patch "configure" to specifically require libpng 1.5. While
	# it's usually preferable to patch "configure.in" instead, most SDL
	# autotools-based scripts are fundamentally, nonsensically broken. Calling
	# eautoreconf() here with the following globally defined variables *SHOULD*
	# produce a working "aclocal.m4" file with corresponding scripts:
	#
	#   AM_OPTS='--foreign --include-deps'
    #   AT_M4DIR='acinclude'
	#
	# Naturally, it doesn't, failing with the usual
	# "libtool: version mismatch error". I hate you, autotools. Since SDL itself
	# has since moved to CMake, this really isn't worth fixing. Hack it for now.
	sed -e 's~libpng~libpng15~' -i configure
}

src_configure() {
	local myeconfargs=(
		# Disable support for OS X's ImageIO library.
		--disable-imageio
		$(use_enable static-libs static)
		$(use_enable bmp)
		$(use_enable gif)
		$(use_enable jpeg jpg)
		$(use_enable pnm)
		$(use_enable png)
		$(use_enable tga)
		$(use_enable tiff tif)
		$(use_enable webp)
		$(use_enable xcf)
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
	dodoc CHANGES README
	use static-libs || prune_libtool_files --all

	# Prevent SDL 2.0's "showimage" from colliding with SDL 1.2's "showimage".
	use showimage && newbin '.libs/showimage' "showimage-2"
}

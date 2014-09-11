# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enable Bash strictness.
set -e

inherit autotools cvs eutils

# While the source tarballs on the OpenGLide project page hail from late 2002,
# the most recent commit to the OpenGLide repository hails from 2010. However,
# such repository contains no compilation instructions! Google uncovered a blog
# post with nice instructions:
# http://www.tobiasmaasland.de/2009/06/02/dosbox-3dfx-games-mit-opengl-auf-linux
DESCRIPTION="Glide to OpenGL wrapper"
HOMEPAGE="http://sourceforge.net/projects/openglide"

#cvs -d:pserver:anonymous@openglide.cvs.sourceforge.net:/cvsroot/openglide login
#cvs -z3 -d:pserver:anonymous@openglide.cvs.sourceforge.net:/cvsroot/openglide co -P openglide
ECVS_AUTH="pserver"
ECVS_USER="anonymous"
ECVS_PASS=""
ECVS_SERVER="openglide.cvs.sourceforge.net:/cvsroot/openglide"
ECVS_MODULE="openglide"
ECVS_CVS_OPTIONS="-P"  # prune empty directories

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="X sdl static-libs"

# Since it's unclear which specific X11 dependencies OpenGLide requires, we
# list the customary dependencies.
RDEPEND+="
	sdl? ( >=media-libs/libsdl-1.2 )
	X? (
		x11-libs/libXt
		x11-libs/libXext
		x11-libs/libX11
		x11-libs/libXrandr
	)"
DEPEND+="
	X? (
		x11-proto/xextproto
		x11-proto/xproto
	)
	${RDEPEND}"

S="${WORKDIR}/${PN}"

src_prepare() {
	# Remove the "install-data-hook" target from "Makefile.am" *BEFORE*
	# generating "Makefile.in". While we could theoretically patch such target
	# to work properly, it's much simpler to do so ourselves in src_install().
	sed -i -e '/^install-data-hook:$/,+1d' Makefile.am

	# Regenerate autotools files. Although OpenGLide also provides a script
	# "bootstrap" for doing so, such script is rather... hacky.
	eautoreconf
}

src_configure() {
	econf \
 		$(use_enable sdl) \
 		$(use_enable static-libs static) \
 		$(use_with X x)
}

# OpenGLide provides no documentation to speak of, so this is it.
src_install() {
	emake DESTDIR="${D}" install
	use static-libs || prune_libtool_files --all

	# Implement the equivalent of the deleted "install-data-hook" target.
	dosym /usr/include/${PN}/sdk2_glide.h /usr/include/glide.h
}

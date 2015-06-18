# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

#FIXME: C:DDA ships with an undocumented and currently unsupported
#"CMakeLists.txt" for building under CMake. Switch to such makefile when
#confirmed to be reliably working.

# See "COMPILING.md" in the C:DDA repository for compilation instructions.
inherit games

DESCRIPTION="Roguelike set in a post-apocalyptic world"
HOMEPAGE="http://www.cataclysmdda.com"

LICENSE="CC-BY-SA-3.0"
SLOT="0"
IUSE="clang lua ncurses nls sdl sound"
REQUIRED_USE="
	lua? ( sdl )
	sound? ( sdl )
	|| ( ncurses sdl )
"

RDEPEND="
	app-arch/bzip2:= 
	sys-libs/glibc:2.2=
	sys-libs/zlib:=
	lua? ( >=dev-lang/lua-5.1:0= )
	ncurses? ( sys-libs/ncurses:5= )
	nls? ( sys-devel/gettext:0=[nls] )
	sdl? (
		media-libs/libsdl2:0=
		media-libs/sdl2-ttf:0=
		media-libs/sdl2-image:0=[jpeg,png]
		media-libs/freetype:2=
	)
	sound? (
		media-libs/sdl2-mixer:0=
	)
"
DEPEND="${RDEPEND}
	clang? ( sys-devel/clang )
	!clang? ( sys-devel/gcc[cxx] )
"

# Absolute path of the directory containing C:DDA data files.
CATACLYSM_HOME="${GAMES_DATADIR}/${PN}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/CleverRaven/Cataclysm-DDA.git"
	SRC_URI=""
	KEYWORDS=""
else
	# Post-0.9 versions of C:DDA employ capitalized alphabetic letters rather
	# than numbers (e.g., "0.A" rather than "1.0"). Since Portage permits
	# version specifiers to contain only a single suffixing letter prefixed by
	# one or more digits, we:
	#
	# * Encode such versions as "0.9${lowercase_letter}" in ebuild filenames.
	# * In the ebuilds themselves (i.e., here), we:
	#   * Manually strip the "9" in such filenames.
	#   * Uppercase the lowercase letter in such filenames.
	MY_PV="${PV/.9/.}"
	MY_PV="${MY_PV^^}"
	SRC_URI="https://github.com/CleverRaven/Cataclysm-DDA/archive/${MY_PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/Cataclysm-DDA-${MY_PV}"
fi

src_prepare() {
	# Strip the following from the the Makefile:
	#
	# * Hardcoded optimizations (e.g., "-O3").
	# * g++ option "-Werror", converting compiler warnings to errors and hence
	#   failing on the first (inevitable) warning.
	sed -i\
		-e '/OTHERS += /s~ -O3~~'\
		-e '/RELEASE_FLAGS = /s~ -Werror~~'\
		Makefile || die '"sed" failed.'

	# Replace the hardcoded home directory with our Gentoo-specific directory,
	# which *MUST* be suffixed by "/" here to satisfy code requirements.
	sed -i -e 's~^\(\s*update_pathname("datadir", \)[^)]*\(.*\)$~\1"'${CATACLYSM_HOME}'/"\2~g'\
		src/path_info.cpp || die '"sed" failed.'

	# The Makefile assumes subdirectories "obj" and "obj/tiles" both exist,
	# which (of course) they do not. Create such subdirectories manually.
	mkdir -p obj/tiles || die '"mkdir" failed.'
}

src_compile() {
	# Options passed to all ncurses- and SDL-specific emake() calls below.
	declare -ga CATACLYSM_EMAKE_NCURSES CATACLYSM_EMAKE_SDL

	# Define ncurses-specific emake() options first.
	CATACLYSM_EMAKE_NCURSES=(
		# Unlike all other paths defined below, ${PREFIX} is compiled into
		# installed binaries and hence *MUST* refer to a run- rather than
		# install-time directory (e.g., relative to ${EROOT} rather than ${ED}).
		PREFIX="${EROOT}"usr

		# Install-time directories. Since ${PREFIX} does *NOT* refer to an
		# install-time directory, all variables defined by the Makefile relative
		# to ${PREFIX} *MUST* be redefined here relative to ${ED}.
		BIN_PREFIX="${ED}/${GAMES_BINDIR}"
		DATA_PREFIX="${ED}/${CATACLYSM_HOME}"
		LOCALE_DIR="${ED}"/usr/share/locale

		# For efficiency, prefer release to debug builds.
		RELEASE=1

		# Link against Portage-provided shared libraries.
		DYNAMIC_LINKING=1

		# Write saves and configs to user-specific XDG base directories.
		USE_XDG_DIR=1
	)

	use clang && CATACLYSM_EMAKE_NCURSES+=( CLANG=1 )
	use lua   && CATACLYSM_EMAKE_NCURSES+=( LUA=1 )

	# If enabling internationalization, do so.
	if use nls; then
		CATACLYSM_EMAKE_NCURSES+=( LOCALIZE=1 )

		# If optional Gentoo-specific string global ${LINGUAS} is defined (e.g.,
		# in "make.conf"), pass all such whitespace-delimited locales.
		[[ -n "${LINGUAS+x}" ]] &&
			CATACLYSM_EMAKE_NCURSES+=( LANGUAGES="${LINGUAS}" )
	else
		CATACLYSM_EMAKE_NCURSES+=( LOCALIZE=0 )
	fi

	# Define SDL- *AFTER* ncurses-specific emake() options, as the former is a
	# strict superset of the latter.
	CATACLYSM_EMAKE_SDL=( TILES=1 "${CATACLYSM_EMAKE_NCURSES[@]}" )
	use sound && CATACLYSM_EMAKE_SDL+=( SOUND=1 )

	# If enabling ncurses, compile the ncurses-based binary.
	if use ncurses; then
		einfo 'Compiling ncurses interface...'
		emake "${CATACLYSM_EMAKE_NCURSES[@]}"
	fi

	# If enabling SDL, compile the SDL-based binary.
	if use sdl; then
		einfo 'Compiling SDL interface...'
		emake "${CATACLYSM_EMAKE_SDL[@]}"
	fi
}

src_install() {
	# If enabling ncurses, install the ncurses-based binary.
	if use ncurses; then
		emake install "${CATACLYSM_EMAKE_NCURSES[@]}"
	fi

	# If enabling SDL, install the SDL-based binary.
	if use sdl; then
		emake install "${CATACLYSM_EMAKE_SDL[@]}"
	fi

	# Force game-specific user and group permissions.
	prepgamesdirs
}

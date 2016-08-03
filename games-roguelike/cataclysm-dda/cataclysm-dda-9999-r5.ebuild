# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=5

#FIXME: C:DDA ships with an undocumented and currently unsupported
#"CMakeLists.txt" for building under CMake. Switch to this makefile when
#confirmed to be reliably working.

# See "COMPILING.md" in the C:DDA repository for compilation instructions.
DESCRIPTION="Roguelike set in a post-apocalyptic world"
HOMEPAGE="http://en.cataclysmdda.com"

LICENSE="CC-BY-SA-3.0"
SLOT="0"
IUSE="clang lua ncurses nls sdl sound test xdg kernel_linux kernel_Darwin"
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
	sound? ( media-libs/sdl2-mixer:0= )
"
DEPEND="${RDEPEND}
	clang? ( sys-devel/clang )
	!clang? ( sys-devel/gcc[cxx] )
"

# Absolute path of the directory containing C:DDA data files.
CATACLYSM_HOME=/usr/share/"${PN}"

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
	# If this ebuild requires patching to support the compile-time
	# ${USE_XDG_DIR} option, do so.
	local xdg_patch="${FILESDIR}/${P}-USE_XDG_DIR.patch"
	[[ -f "${xdg_patch}" ]] && epatch "${xdg_patch}"

	# Strip the following from all "Makefile" files:
	#
	# * Hardcoded optimization (e.g., "-O3", "-Os") and stripping (e.g., "-s").
	# * g++ option "-Werror", converting compiler warnings to errors and hence
	#   failing on the first (inevitable) warning.
	# * The "tests" target from the "all" target, preventing tests from being
	#   implicitly run when the "test" USE flag is disabled.
	# * "astyle"-specific targets (e.g., "astyle-check") from the "all" target,
	#   preventing style tests from being implicitly run.
	# * The Makefile-specific ${BUILD_PREFIX} variable, conflicting with the 
	#   Portage-specific variable of the same name. For disambiguity, this
	#   variable is renamed to a Makefile-specific variable name.
	sed -i\
		-e '/\(CXXFLAGS\|OTHERS\) += /s~ -O.~~'\
		-e '/LDFLAGS += /s~ -s~~'\
		-e '/RELEASE_FLAGS = /s~ -Werror~~'\
		-e '/^all:\s\+/s~\btests$~~'\
		-e '/^all:\s\+/s~\s\+\$(ASTYLE)\s\+~ ~'\
		-e 's~\bBUILD_PREFIX\b~CATACLYSM_BUILD_PREFIX~'\
		{tests/,}Makefile || die '"sed" failed.'

	# Replace the hardcoded home directory with our Gentoo-specific directory,
	# which *MUST* be suffixed by "/" here to satisfy code requirements.
	sed -i -e 's~^\(\s*update_pathname("datadir", \)[^)]*\(.*\)$~\1"'${CATACLYSM_HOME}'/"\2~g'\
		src/path_info.cpp || die '"sed" failed.'

	# The Makefile assumes subdirectories "obj" and "obj/tiles" both exist,
	# which (...of course) they don't. Create these subdirectories manually.
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
		BIN_PREFIX="${ED}"/usr/bin
		DATA_PREFIX="${ED}/${CATACLYSM_HOME}"
		LOCALE_DIR="${ED}"/usr/share/locale

		# For efficiency, prefer release to debug builds.
		RELEASE=1

		# Link against Portage-provided shared libraries.
		DYNAMIC_LINKING=1

		# Conditionally set USE flag-dependent options. Note that Lua support
		# requires SDL support but, paradoxically, appears to be supported when
		# compiling both SDL *AND* ncurses binaries. Black magic is black.
		CLANG=$(usex clang 1 0)
		LOCALIZE=$(usex nls 1 0 )
		LUA=$(usex lua 1 0 )
	)

	# Detect the current machine architecture and operating system.
	local cataclysm_arch
	if use kernel_linux; then
		if use amd64; then
			cataclysm_arch=linux64
		elif use x86; then
			cataclysm_arch=linux32
		fi
	elif use kernel_Darwin; then
		cataclysm_arch=osx
	else
		die "Architecture \"${ARCH}\" unsupported."
	fi
	CATACLYSM_EMAKE_NCURSES+=( NATIVE=${cataclysm_arch} )

	# If storing saves and settings in XDG base directories, do so.
	if use xdg; then
		CATACLYSM_EMAKE_NCURSES+=( USE_HOME_DIR=0 USE_XDG_DIR=1 )
	# Else, store saves and settings in home directories.
	else
		CATACLYSM_EMAKE_NCURSES+=( USE_HOME_DIR=1 USE_XDG_DIR=0 )
	fi

	# If enabling internationalization *AND* the optional Gentoo-specific string
	# global ${LINGUAS} is defined (e.g., in "make.conf"), pass all such
	# whitespace-delimited locales.
	use nls && [[ -n "${LINGUAS+x}" ]] &&
		CATACLYSM_EMAKE_NCURSES+=( LANGUAGES="${LINGUAS}" )

	# If enabling ncurses, compile the ncurses-based binary.
	if use ncurses; then
		einfo 'Compiling ncurses interface...'
		emake "${CATACLYSM_EMAKE_NCURSES[@]}"
	fi

	# If enabling SDL, compile the SDL-based binary.
	if use sdl; then
		# Define SDL- *AFTER* ncurses-specific emake() options. The former is a
		# strict superset of the latter.
		CATACLYSM_EMAKE_SDL=(
			"${CATACLYSM_EMAKE_NCURSES[@]}"

			# Enabling tiled output implicitly enables SDL.
			TILES=1

			# Conditionally set USE flag-dependent SDL options.
			SOUND=$(usex sound 1 0)
		)

		# Compile us up the tiled bomb.
		einfo 'Compiling SDL interface...'
		emake "${CATACLYSM_EMAKE_SDL[@]}"
	fi
}

src_test() {
	emake tests || die 'Tests failed.'
}

src_install() {
	# If enabling ncurses, install the ncurses-based binary.
	use ncurses && emake install "${CATACLYSM_EMAKE_NCURSES[@]}"

	# If enabling SDL, install the SDL-based binary.
	use sdl && emake install "${CATACLYSM_EMAKE_SDL[@]}"
}

pkg_preinst() {
	if has_version "=games-roguelike/cataclysm-dda-0.9c-r2" ||
	   has_version "=games-roguelike/cataclysm-dda-9999-r4"; then
		BROKEN_SAVES_VERSION_INSTALLED=1
	fi
}

pkg_postinst() {
	games_pkg_postinst

	if [[ -n $BROKEN_SAVES_VERSION_INSTALLED ]]; then
		ewarn "The prior ebuild always stored saves and settings in the"
		ewarn "\"\$XDG_CONFIG_HOME/${PN}\" directory. The current ebuild stores"
		ewarn "saves and settings in that directory only when the \"xdg\" USE"
		ewarn "flag is enabled or in the \"~/${PN}\" directory otherwise."
		ewarn "Consider either manually moving existing saves and settings or"
		ewarn "enabling this USE flag."
	fi
}

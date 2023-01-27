# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

#FIXME: C:DDA ships with an undocumented and currently unsupported
#"CMakeLists.txt" for building under cmake. Switch to this makefile when
#confirmed to be reliably working.
#FIXME: After switching to cmake, remove the "pch? ( || ( ncurses sdl ) )"
#restriction below. Indeed, the inapplicability of that restriction to cmake is
#one of the strongest arguments in favour of switching to cmake.

inherit xdg-utils

# See "COMPILING.md" in the C:DDA repository for compilation instructions.
DESCRIPTION="Roguelike set in a post-apocalyptic world"
HOMEPAGE="https://cataclysmdda.org"

LICENSE="CC-BY-SA-3.0"
SLOT="0"
IUSE="
	astyle clang debug lintjson lto ncurses nls pch sdl sound test xdg
	kernel_linux kernel_Darwin"

# Enabling precompiled headers prevents sequential compilation of both the
# ncurses and SDL binaries. Fundamental flaws in upstream makefiles erroneously
# attempt to reuse precompiled headers unique to the ncurses binary when
# compiling the SDL binary, resulting in compilation errors resembling:
#     cc1plus: error: pch/main-pch.hpp.gch: not used because `_XOPEN_SOURCE'
#     not defined [-Werror=invalid-pch]
# See also: https://github.com/CleverRaven/Cataclysm-DDA/issues/42598
REQUIRED_USE="
	|| ( ncurses sdl )
	pch? ( ^^ ( ncurses sdl ) )
	sound? ( sdl )
"

# Note that, while GCC also supports LTO via the gold linker, Portage appears
# to provide no way of validating the current "gcc" to link with gold. *shrug*
IDEPEND="dev-util/desktop-file-utils"
BDEPEND="
	clang? (
		sys-devel/clang
		debug? ( sys-devel/clang-runtime[sanitize] )
		lto?   ( sys-devel/llvm[gold] )
	)
	!clang? (
		sys-devel/gcc[cxx]
		debug? ( sys-devel/gcc[sanitize] )
	)
"
DEPEND="
	app-arch/bzip2
	sys-libs/glibc
	sys-libs/zlib
	virtual/libc
	astyle? ( dev-util/astyle )
	ncurses? ( >=sys-libs/ncurses-6.0:0 )
	nls? ( sys-devel/gettext:0[nls] )
	sdl? (
		media-libs/freetype:2
		media-libs/libsdl2:0
		media-libs/sdl2-image:0[jpeg,png]
		media-libs/sdl2-ttf:0
	)
	sound? ( media-libs/sdl2-mixer:0 )
"
RDEPEND="${DEPEND}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/CleverRaven/Cataclysm-DDA.git"
	EGIT_BRANCH=master

	SRC_URI=""
	KEYWORDS=""
else
	# Post-0.9 versions of C:DDA employ capitalized alphabetic letters rather
	# than numbers (e.g., "0.A" rather than "1.0"). Since Portage permits
	# version specifiers to contain only a single suffixing letter prefixed by
	# one or more digits:
	# * Encode these versions as "0.9${lowercase_letter}[_p${digit}]" in ebuild
	#   filenames, where the optional suffixing "[_p${digit}]" portion connotes
	#   a patch revision. As example, encode the upstream:
	#   * "0.D" as "0.9d".
	#   * "0.E-2" as "0.9e_p2".
	# * Deencode these encoded versions here by (in order):
	#   1. Reducing the "0.9" in these filenames to merely "0.".
	#   2. Reducing the "_p" in these filenames to merely "-".
	#   3. Uppercasing the lowercase letter in these filenames.
	MY_PV="${PV}"
	MY_PV="${MY_PV/0.9/0.}"
	MY_PV="${MY_PV/_p/-}"
	MY_PV="${MY_PV^^}"

	SRC_URI="https://github.com/CleverRaven/Cataclysm-DDA/archive/${MY_PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"

	S="${WORKDIR}/Cataclysm-DDA-${MY_PV}"
fi

src_prepare() {
	# The makefile assumes subdirectories "obj" and "obj/tiles" both exist,
	# which (...of course) they don't. Create these subdirectories manually.
	mkdir -p obj/tiles || die

	# Strip the following from all makefiles:
	# * Hardcoded optimization (e.g., "-O3", "-Os") and stripping (e.g., "-s").
	# * g++ option "-Werror", converting compiler warnings to errors and hence
	#   failing on the first (inevitable) warning.
	# * The makefile-specific ${BUILD_PREFIX} variable, conflicting with the
	#   Portage-specific variable of the same name. For disambiguity, this
	#   variable is renamed to a makefile-specific variable name.
	sed -i \
		-e '/\bOPTLEVEL = /s~-O.\b~~' \
		-e '/LDFLAGS += /s~-s\b~~' \
		-e '/RELEASE_FLAGS = /s~-Werror\b~~' \
		-e 's~\bBUILD_PREFIX\b~CATACLYSM_BUILD_PREFIX~' \
		{tests/,}Makefile || die

	# If *NOT* linting with astyle, remove all globally scoped process
	# substitutions unconditionally running "astyle" from makefiles to avoid:
	#     /bin/sh: line 1: astyle: command not found
	if ! use astyle; then
		sed -i -e 's~$(shell if $(ASTYLE_BINARY)[^)]*)~not-foo~' \
			{tests/,}Makefile || die
	fi

	# If compiling with g++, remove the Clang-specific
	# "-Wno-unknown-warning-option" flag unsupported by g++ from makefiles.
	if ! use clang; then
		sed -i -e 's~-Wno-unknown-warning-option\b~~' {tests/,}Makefile || die
	fi

	# If "doc/JSON_LOADING_ORDER.md" is still a symbolic link, replace this link
	# with a copy of its transitive target to avoid "QA Notice" complaints.
	if [[ -L doc/JSON_LOADING_ORDER.md ]]; then
		rm doc/JSON_LOADING_ORDER.md || die
		cp data/json/LOADING_ORDER.md doc/JSON_LOADING_ORDER.md || die
	fi

	#FIXME: Consider removing this block on the next stable bump.
	# If installing a stable release...
	if [[ "${PV}" != 9999* ]]; then
		#FIXME: Report the "-Werror" issue upstream, please.
		# Modify all makefiles as follows:
		# * Remove all globally scoped process substitutions unconditionally
		#   running "git" from makefiles to avoid:
		#     fatal: not a git repository (or any parent up to mount point /var/tmp)
		#     Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set)
		# * Prevent non-fatal warnings from being implicitly promoted to
		#   fatal errors. By default, these makefiles implicitly promote
		#   warnings to errors via the "-Werror" flag. When that flag is *NOT*
		#   passed, g++ accepts ill-formed code (e.g., improper casts) it would
		#   otherwise reject as syntactically invalid; that's bad. Ergo, this
		#   flag is a sane default. Sadly, the most recent stable release of
		#   C:DDA fails to compile when this flag is passed with a
		#   non-human-readable fatal compile-time error resembling:
		#       c++  -DRELEASE -DTILES -DBACKTRACE -DLOCALIZE -DPREFIX="/usr" -DDATA_DIR_PREFIX -DUSE_HOME_DIR -march=skylake -O2 -pipe -ffast-math -Wodr -Werror -Wall -Wextra -Wformat-signedness -Wlogical-op -Wmissing-declarations -Wmissing-noreturn -Wnon-virtual-dtor -Wold-style-cast -Woverloaded-virtual -Wpedantic -Wsuggest-override -Wunused-macros -Wzero-as-null-pointer-constant -Wredundant-decls -g -fsigned-char -std=c++14 -MMD -MP -m64 -I/usr/include/SDL2 -D_REENTRANT -DSDL_SOUND -I/usr/include/SDL2 -D_REENTRANT -I/usr/include/harfbuzz -I/usr/include/freetype2 -I/usr/include/glib-2.0 -I/usr/lib64/glib-2.0/include  -c src/sdl_font.cpp -o obj/tiles/sdl_font.o
		#       [01m[Ksrc/sdl_font.cpp:[m[K In function ‘[01m[Kint test_face_size(const string&, int, int)[m[K’:
		#       [01m[Ksrc/sdl_font.cpp:25:44:[m[K [01;31m[Kerror: [m[Kinvalid conversion from ‘[01m[Kconst char*[m[K’ to ‘[01m[Kchar*[m[K’ [[01;31m[K]8;;https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-fpermissive-fpermissive]8;;[m[K]
		#          25 |         char *style = [01;31m[KTTF_FontFaceStyleName( fnt.get() )[m[K;
		#             |                       [01;31m[K~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~~~[m[K
		#             |                                            [01;31m[K|[m[K
		#             |                                            [01;31m[Kconst char*[m[K
		#       [01m[Ksrc/sdl_font.cpp:32:64:[m[K [01;31m[Kerror: [m[Kinvalid conversion from ‘[01m[Kconst char*[m[K’ to ‘[01m[Kchar*[m[K’ [[01;31m[K]8;;https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html#index-fpermissive-fpermissive]8;;[m[K]
		#          32 |                     if( nullptr != ( ts = [01;31m[KTTF_FontFaceStyleName( tf.get() )[m[K ) ) {
		#             |                                           [01;31m[K~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~~[m[K
		#             |                                                                [01;31m[K|[m[K
		#             |                                                                [01;31m[Kconst char*[m[K
		#       make: *** [Makefile:962: obj/tiles/sdl_font.o] Error 1
		#
		#   Note that g++ advises additionally passing the "-fpermissive" flag
		#   to circumvent this in the error message above. Naturally, that
		#   advice is bad. Why? Because the "-Werror" flag quietly assumes
		#   precedence over the "-fpermissive" flag, which g++ then ignores.
		#   This is one of many reasons why Clang intentionally refuses to
		#   support the g++-specific "-fpermissive" flag. *sigh*
		#
		#   See also this overlay issue:
		#       https://github.com/leycec/raiagent/issues/106
		sed -i \
			-e 's~$(shell git [^)]*)~not-true~' \
			-e 's~-Werror~-fpermissive~' \
			{tests/,}Makefile || die
	fi

	# Apply user-specific patches and all patches added to ${PATCHES} above.
	default_src_prepare
}

src_compile() {
	# Options passed to all ncurses- and SDL-specific emake() calls below.
	declare -ga CATACLYSM_EMAKE_NCURSES CATACLYSM_EMAKE_SDL

	# Define ncurses-specific emake() options first.
	CATACLYSM_EMAKE_NCURSES=(
		# Install-time directories. Since ${PREFIX} does *NOT* refer to an
		# install-time directory, all variables defined by the makefile
		# relative to ${PREFIX} *MUST* be redefined here relative to ${ED}.
		BIN_PREFIX="${ED}"/usr/bin
		DATA_PREFIX="${ED}"/usr/share/${PN}
		LOCALE_DIR="${ED}"/usr/share/locale

		# Unconditionally enable backtrace support. Note that:
		# * Enabling this functionality incurs no performance penalty.
		# * Disabling this functionality has undesirable side effects,
		#   including:
		#   * Stripping of symbols, which Portage already does when requested.
		#   * Disabling of crash reports on fatal errors, a tragically common
		#     occurence when installing the live version.
		# Ergo, this support should *NEVER* be disabled.
		BACKTRACE=1

		# Unconditionally add debug symbols to executable binaries, which
		# Portage then subsequently strips by default.
		DEBUG_SYMBOLS=1

		# Link against Portage-provided shared libraries.
		DYNAMIC_LINKING=1

		# Since Gentoo's ${L10N} USE_EXPAND flag conflicts with this makefile's
		# flag of the same name, temporarily prevent the former from being
		# passed to this makefile by overriding the current user-defined value
		# of ${L10N} with the empty string. Failing to do so results in the
		# following link-time fatal error:
		#     make: *** No rule to make target 'en', needed by 'all'.  Stop.
		L10N=

		# Conditionally enable all remaining USE flag-dependent options.
		ASTYLE=$(usex astyle 1 0)
		LINTJSON=$(usex lintjson 1 0)
		PCH=$(usex pch 1 0)
		RUNTESTS=$(usex test 1 0)
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

	# Conditionally set USE flag-dependent options. Since the makefile tests
	# for the existence rather than the value of the corresponding environment
	# variables, these variables must be left undefined rather than defined to
	# some false value (e.g., 0, "False", the empty string) if the
	# corresponding USE flags are disabled.
	use clang && CATACLYSM_EMAKE_NCURSES+=( CLANG=1 )

	# If enabling link time optimization, do so.
	use lto && CATACLYSM_EMAKE_NCURSES+=( LTO=1 )

	# If enabling debugging-specific facilities, do so. Specifically,
	# * "RELEASE=0", disabling release-specific optimizations.
	# * "BACKTRACE=1", enabling backtrace support.
	# * "SANITIZE=address", enabling Google's AddressSanitizer (ASan)
	#   instrumentation for detecting memory corruption (e.g., buffer overrun).
	if use debug; then
		CATACLYSM_EMAKE_NCURSES+=( RELEASE=0 SANITIZE=address )
	# Else, enable release-specific optimizations.
	#
	# Note that, unlike similar options, the "SANITIZE" option does *NOT*
	# support disabling via "SANITIZE=0" and *MUST* thus be explicitly omitted.
	else
		CATACLYSM_EMAKE_NCURSES+=( RELEASE=1 )
	fi

	# If storing saves and settings in XDG-compliant base directories, do so.
	if use xdg; then
		CATACLYSM_EMAKE_NCURSES+=( USE_HOME_DIR=0 USE_XDG_DIR=1 )
	# Else, store saves and settings in standard home dot directories.
	else
		CATACLYSM_EMAKE_NCURSES+=( USE_HOME_DIR=1 USE_XDG_DIR=0 )
	fi

	# If enabling internationalization, do so.
	if use nls; then
		CATACLYSM_EMAKE_NCURSES+=( LOCALIZE=1 )

		#FIXME: This used to work, but currently causes installation to fail
		#with fatal shell errors resembling:
		#    mkdir -p /var/tmp/portage/games-roguelike/cataclysm-dda-9999-r6/image//usr/share/locale
		#    LOCALE_DIR=/var/tmp/portage/games-roguelike/cataclysm-dda-9999-r6/image//usr/share/locale lang/compile_mo.sh en en_CA
		#    msgfmt: error while opening "lang/po/en.po" for reading: No such file or directory
		#    msgfmt: error while opening "lang/po/en_CA.po" for reading: No such file or directory
		#Since the Cataclysm: DDA script compiling localizations (currently,
		#"lang/compile_mo.sh") cannot be trusted to safely do so for explicitly
		#passed locales, avoid explicitly passing locales for the moment.
		#Uncomment the following statement after upstream resolves this issue.
		CATACLYSM_EMAKE_NCURSES+=( LANGUAGES='all' )

		# # If the optional Gentoo-specific string global ${LINGUAS} is defined
		# # (e.g., in "make.conf"), enable all such whitespace-delimited locales.
		# [[ -n "${LINGUAS+x}" ]] &&
		# 	CATACLYSM_EMAKE_NCURSES+=( LANGUAGES="${LINGUAS}" )
	fi

	# If enabling ncurses, compile the ncurses-based binary.
	if use ncurses; then
		einfo 'Compiling ncurses interface...'

		# Unlike all other paths defined elsewhere, ${PREFIX} is compiled into
		# installed binaries and therefore *MUST* refer to a runtime rather
		# than installation-time directory (i.e., relative to ${ESYSROOT}
		# rather than ${ED}) during the src_compile() phase.
		emake "${CATACLYSM_EMAKE_NCURSES[@]}" PREFIX="${ESYSROOT}"/usr
	fi

	# If enabling SDL, compile the SDL-based binary.
	if use sdl; then
		# Define SDL- *AFTER* ncurses-specific emake() options. The former is a
		# strict superset of the latter.
		CATACLYSM_EMAKE_SDL=(
			"${CATACLYSM_EMAKE_NCURSES[@]}"

			# Enabling tiled output implicitly enables SDL.
			TILES=1
		)

		# If enabling SDL-dependent sound support, do so.
		use sound && CATACLYSM_EMAKE_SDL+=( SOUND=1 )

		# Compile us up the tiled bomb.
		einfo 'Compiling SDL interface...'
		emake "${CATACLYSM_EMAKE_SDL[@]}" PREFIX="${ESYSROOT}"/usr
	fi
}

src_test() {
	emake tests || die
}

src_install() {
	dodoc -r README.md doc/*

	# If enabling ncurses, install the ncurses-based binary.
	#
	# Set ${PREFIX} to refer to an installation-time rather than runtime
	# directory (i.e., relative to ${ED} rather than ${ESYSROOT}) during the
	# src_install() phase.
	use ncurses &&
		emake install "${CATACLYSM_EMAKE_NCURSES[@]}" PREFIX="${ED}"/usr

	# If enabling SDL, install the SDL-based binary.
	use sdl &&
		emake install "${CATACLYSM_EMAKE_SDL[@]}" PREFIX="${ED}"/usr
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

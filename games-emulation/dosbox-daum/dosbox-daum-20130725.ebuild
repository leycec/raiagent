# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-emulation/dosbox/dosbox-0.74.ebuild,v 1.15 2013/04/02 15:35:59 mr_bones_ Exp $

# Since DOSBox SVN Daum significantly patches the official DOSBox, this ebuild
# inherits very little of the official "dosbox" ebuild. More's the pity.
EAPI=5

# Enforce bash strictness.
set -e

# List "games" last, as suggested by the "Gentoo Games Ebuild HOWTO."
inherit autotools eutils toolchain-funcs games

DESCRIPTION="DOS emulator (unofficial SVN-based Daum patchset maintained by ykhwong)"
HOMEPAGE="http://ykhwong.x-y.net"
SRC_URI="${P}.7z"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="alsa c++0x debug hardened opengl printer"

# DOSBox SVN Daum requires manual download. See pkg_nofetch() below. *sigh*
RESTRICT="fetch"

#FIXME: We *REALLY* want a new "virtual/dosbox". Why? Because DOSBox frontends
#(e.g., DBGL) need to know that "dosbox-daum" is an acceptable DOSBox substitute.
#It's all certainly feasible, but a slight slice of a headache. Let's ignore the
#issue wholesale, for now.

# DOSBox SVN Daum requires:
#
# * The newest released stable version of "libsdl" patched with Moe's
#   "openglhq" patch available from ykhwong's site. Since the official SDL 1.2
#   ebuilds provide no such patch, use the overlay-specific unofficial SDL 1.2
#   ebuild explicitly providing such patch. (Yes, this is insanity.)
# * The newest unreleased live version of "sdl-sound", unconditionally
#   supporting FLAC and Ogg Vorbis but *NOT* PhysFS.
RDEPEND+="
	alsa? ( media-libs/alsa-lib )
	opengl? ( virtual/glu virtual/opengl )
	debug? ( sys-libs/ncurses )
	media-libs/libpng:0
	~media-libs/libsdl-1.2.9999[joystick,openglhq,video,X]
	media-libs/sdl-net
	~media-libs/sdl-sound-9999[flac,vorbis]"

# DOSBox SVN Daum supports additional libraries, all mandatory except
# Freetype. Make files should probably be patched so as to render *ALL*
# libraries optional, but it's hard to be bothered at the moment.
#
# "tbb" is Intel's Thread Building Blocks (TBB). Daum requires TBB for
# parallelizing high-quality image scaling under xBRZ. Since TBB currently only
# runs on x86 architecture (both 32- and 64-bit), this ebuild is unlikely to be
# very portable.
#
# OpenGLide is a Glide-to-OpenGL wrapper required by Daum but *NOT* listed as
# such by its documentation. (We can do better than that next time, ykhwong.)
RDEPEND+="
	printer? ( media-libs/freetype )
	dev-cpp/tbb
	dev-games/physfs[zip]
	media-libs/flac
	media-libs/openglide
	media-sound/fluidsynth
	net-libs/libpcap"

# DOSBox SVN Daum is merely a patchset on DOSBox (albiet, a rather extensive
# patchset). Install directly over and hence conflict with DOSBox. Block!
RDEPEND+="
	!games-emulation/dosbox"

# DOSBox SVN Daum requires autotools reconfiguration of unspecified versions.
# (Yes, I'm not kidding.) Inheriting the "autotools" eclass above would also add
# such dependencies but in a version-dependent manner, as well as introducing
# spurious other issues -- including "repoman" complaints and a vast swath of
# warnings resembling:
#
#     am-wrapper: aclocal: warning: invalid WANT_AUTOMAKE 'latest'; ignoring.
DEPEND+="
	${RDEPEND}
	virtual/pkgconfig"

# Additional options to be passed to "automake" by eautoreconf(), derived from
# the "autogen.sh" script shipped with DOSBox SVN Daum.
AM_OPTS="--include-deps"

# DOSBox SVN Daum unzips into the current working directory.
S="${WORKDIR}"

# Totally lame, ykhwong. Mildly understandable, but totally lame.
pkg_nofetch() {
	einfo "To install DOSBox SVN Daum, manually download \"source.7z\" from"
	einfo "http://ykhwong.x-y.net/xe/?module=file&act=procFileDownload&file_srl=1346&sid=a25a3c7cdc5c2e99ee3d8821935bbd16"
	einfo "and move such file to \"${DISTDIR}/${SRC_URI}\"."
	einfo "Ensure such file is owned by \"portage:portage\" with permission bits 644!"
	einfo "Unfortunately, Javascript on ykhwong's site prohibits automated retrieval."
}

# Totally lame, ykhwong. This is *NOT* understandable and verges on nigh
# inexcusable. I submit there must have been a better way of achieving this.
pkg_pretend() {
	einfo "Before compiling DOSBox SVN Daum, you *MUST* edit \"/usr/include/GL/gl.h\"."
	einfo "Temporarily comment out all function definitions from glActiveTextureARB() to"
	einfo "glMultiTexCoord4svARB() by prefixing the former with \"/*\" and suffixing the"
	einfo "latter with \"*/\": e.g.,"
	einfo
	einfo "    /*"
	einfo "    GLAPI void GLAPIENTRY glActiveTextureARB(GLenum texture);"
	einfo "    ..."
	einfo "    GLAPI void GLAPIENTRY glMultiTexCoord4svARB(GLenum target, const GLshort *v);"
	einfo "    */"
	einfo
	einfo "After installing DOSBox SVN Daum, you *MUST* undo your edits to this file."
	einfo
	einfo "Yes, this is blatantly terrible."
}

src_prepare() {
	# To accomodate future revisions, prefer dynamic patching via sed() to
	# static patching via "patch".

	# When unpatched, DOSBox SVN Daum emits the following error:
	#
	#    x86_64-pc-linux-gnu-gcc -DHAVE_CONFIG_H -I. -I..  -I../include -I/usr/include/SDL -D_REENTRANT  -march=native -O2 -pipe -c miniunz.c
	#    In file included from ../include/unzip.h:55:0,
	#                     from miniunz.c:46:
	#    ../include/ioapi.h:127:51: error: expected ‘=’, ‘,’, ‘;’, ‘asm’ or ‘__attribute__’ before ‘OF’
	#
	# The core issue is that DOSBox SVN Daum bundles an outdated version of
	# miniunzip pilfered from the "contribs/" folder of "zlib". Unfortunately,
	# "zlib" has since renamed the OF() macro to _Z_OF() instead. Instead of
	# globally renaming all instances of OF() in the DOSBox SVN Daum codebase,
	# we forcefully add the expected definition of OF() to "ioapi.h".
	#
	# Like everything DOSBox SVN Daum related, *THIS IS TERRIBLE*.
	sed -ie 's~^\(#include "zlib.h"\)$~\1\
#ifndef OF /* function prototypes */\
#  ifdef STDC\
#    define OF(args)  args\
#  else\
#    define OF(args)  ()\
#  endif\
#endif~' include/ioapi.h

	# When unpatched, DOSBox SVN Daum emits the following error:
	#
	#    cpu/libcpu.a(core_dynrec.o): In function `MakeCodePage(unsigned long, CodePageHandlerDynRec*&)':
	#    core_dynrec.cpp:(.text+0x88d7): undefined reference to `PAGING_ForcePageInit(unsigned long)'
	#
	# Such reference is undefined because such function is *NEVER* defined.
	# Anywhere. (That's right.) To correct this, prominent community member
	# HAL 9000 recommends removing the entire "if" conditional calling such
	# function from the effected file:
	#
	#    http://www.vogons.org/viewtopic.php?t=25007#p251543
	sed -ie '/if (PAGING_ForcePageInit(lin_addr)) {/,+6d'\
		src/cpu/core_dynrec/decoder_basic.h

	# When unpatched, DOSBox SVN Daum emits the following error under 64-bit
	# architectures:
	#
	#    x86_64-pc-linux-gnu-g++  -march=native -O2 -pipe -std=c++0x -fpermissive  -I/usr/include/freetype2  -Wl,-O1 -Wl,--as-needed -o dosbox dosbox.o save_state.o miniunz.o minizip.o unzip.o zip.o iowin32.o ioapi.o mztools.o  cpu/libcpu.a debug/libdebug.a dos/libdos.a fpu/libfpu.a hardware/libhardware.a shell/libshell.a gui/libgui.a ints/libints.a misc/libmisc.a hardware/serialport/libserial.a hardware/parport/libparallel.a libs/gui_tk/libgui_tk.a libs/porttalk/libporttalk.a hardware/reSID/libresid.a -lSDL_sound -lasound -lm -ldl -lpthread -ltbb -lFLAC -lgthread-2.0 -pthread -lrt -lglib-2.0 -lSDL -lpng -lz -lfreetype -lz -lbz2 -lpcap -lSDL_net -lX11 -lGL -lfluidsynth -lphysfs -lz
	#    cpu/libcpu.a(cpu.o): In function `CPU_FindDecoderType(long (*)())':
	#    cpu.cpp:(.text+0x50f6): undefined reference to `CPU_Core_Dyn_X86_Run()'
	#    cpu.cpp:(.text+0x5117): undefined reference to `CPU_Core_Dyn_X86_Trap_Run()'
	#    cpu/libcpu.a(cpu.o): In function `(anonymous namespace)::SerializeCPU::setBytes(std::basic_istream<char, std::char_traits<char> >&)':
	#    cpu.cpp:(.text+0x5609): undefined reference to `CPU_Core_Dyn_X86_Cache_Reset()'
	#    hardware/libhardware.a(voodoo_interface.o): In function `Voodoo_PCI_Enable(bool)':
	#    voodoo_interface.cpp:(.text+0xad3): undefined reference to `CPU_Core_Dyn_X86_SaveDHFPUState()'
	#    voodoo_interface.cpp:(.text+0xae1): undefined reference to `CPU_Core_Dyn_X86_RestoreDHFPUState()'
	#    collect2: ld returned 1 exit status
	#
	# Such functions are defined only if compiling under 32-bit architectures.
	# To amend this, append placeholder definitions to the end of the file
	# defining the actual definitions as well. Such placeholders will be defined
	# only for 64-bit compilation (i.e., when boolean constant C_DYNAMIC_X86 is
	# disabled by the "configure" script).
	sed -ie '$ c\
Bits CPU_Core_Dyn_X86_Run(void) {\
	return 0;\
}\
Bits CPU_Core_Dyn_X86_Trap_Run(void) {\
	return 0;\
}\
void CPU_Core_Dyn_X86_Cache_Reset(void) {\
}\
#endif' src/cpu/core_dyn_x86.cpp

	# Patch DOSBox SVN Daum in the same manner as the official DOSBox ebuild.
	epatch "${FILESDIR}/dosbox-0.74-gcc46.patch"

	# Generate autotools scripts (e.g., "configure").
	eautoreconf
}

# See the "Compiling DOSBox" section of "linux.txt" for further details on Daum
# configuration and compilation.
#
# Do *NOT* set libraries and CFLAGS with the "flag-o-matic" eclass, as that
# results (for some innocuous reason) in the "configure" script failing with:
#
#     checking whether the C compiler works... no configure: error: in
#     `/var/tmp/portage/games-emulation/dosbox-daum-20130725/work': configure:
#     error: C compiler cannot create executables
#
# This ebuild has been a veritable cesspool of oddball mishaps from the get-go.
# What's one more?
src_configure() {
	# Libraries "libtbb", "libFLAC", and openglide install no "pkg-config"-
	# specific ".pc" files for and hence must be linked to and included
	# manually. "gthread-2.0" does install such files, however, and may be
	# linked to and included with "pkg-config".
	LIBS+=" -ltbb -lFLAC $(pkg-config --libs gthread-2.0)"
	CPPFLAGS+=" -I /usr/include/openglide/ $(pkg-config --cflags gthread-2.0)"

	# If enabling C++0x support, do so by passing such option *AND* an option
	# downgrading spurious "narrowing conversion" errors to warnings. (Even
	# Valve employs the latter fix, suggesting this is a "gcc" issue.)
	use c++0x && CXXFLAGS+=" -std=c++0x -fpermissive"

	# Export such globals to autotools scripts.
	export LIBS CPPFLAGS CXXFLAGS

	# The "configure" script currently only supports a command-line option for
	# USE flag "printer". Shaders are Direct3D-specific and hence disabled.
	egamesconf \
		--disable-dependency-tracking \
		--disable-shaders \
		$(use_enable alsa alsa-midi) \
		$(use_enable !hardened dynamic-core) \
		$(use_enable !hardened dynamic-x86) \
		$(use_enable debug) \
		$(use_enable opengl) \
		$(use_enable printer)
}

src_install() {
	default
	dodoc AUTHORS ChangeLog NEWS README THANKS
	make_desktop_entry dosbox DOSBox /usr/share/pixmaps/dosbox.ico
	doicon src/dosbox.ico
	prepgamesdirs
}

pkg_postinst() {
	elog "Don't forget to undo your edits to \"/usr/include/GL/gl.h\"!"
}

	# DOSBox SVN Daum ships with both C and C++ files. Usually, that would be
	# fine. But this isn't your grandmother's compilation process. The C files
	# actually include C++ files
#	sed -ie 's~\.c ~.cpp ~g' src/Makefile.am
#	local c_file
#	for   c_file in src/*.c; do
#		mv "${c_file}" "${c_file%.c}.cpp"
#	done

	#FIXME: May also need to uncomment this. Ideally, OpenGLide *SHOULD* provide
	#"pkg-config" files... but, yeah. It probably doesn't. What's the canonical
	#means for getting this directory?
#CPPFLAGS+=" -I /usr/include/openglide/"

#flag-o-matic 
#FIXME: We probably want to patch "Makefile.in" to do this. *shrug*
# Inherit the "autotools" eclass to add autotools dependencies run by the
# "autogen.sh" script.
#inherit autotools eutils games
# While
	# we could patch such script with additional support for USE flags
	#, wrap all
# changes specific to this ebuild with "#>>>>>>>" and "#<<<<<<<" guards "fluidsynth", "pcap", and "physfs", it seems simpler 
# Append rather than reset build-time dependencies to avoid overwriting the
# dependencies added by the "autotools" eclass, above.
#FIXME: Enabling this *USUALLY* (but not always, which is crazy in and of itself)
#induces obscure ebuild failure with message "[Errno 9] Bad file descriptor:".
#And... that's it. This is pretty clearly a Portage bug. As an initial fix, just
#try shifting such functionality to pkg_nofetch() above.

#pkg_pretend() {
#	# If the user requests C++11 support, ensure the current compiler supports
#	# such standard. (This conditional liberally lifted from "sci-physics/root".)
#	if use c++0x && [[ $(tc-getCXX) == *g++ ]] &&\
#		! version_is_at_least "4.7" "$(gcc-version)"; then
#		eerror ">=sys-devel/gcc-4.7.0 required for C++0x support"
#		die "Current gcc compiler does not support C++0x"
#	fi
#}

#append-libs -ltbb -lFLAC $(pkg-config --libs gthread-2.0)

	#FIXME: Reenable after worky.
#	append-cppflags $(pkg-config --cflags gthread-2.0)

	# Enable C++0x support by passing an (admittedly) g++-specific flag.
#	if use c++0x; then
#		append-cxxflags -std=c++11
#	fi

	#FIXME: Actually, it'd be far better to try calling eautoreconf() first.
	#Such function applies a wide array of benificial patches.

	# Convert DOS to Unix line endings in the "autogen.sh" script called below.
	# Failure to do so results in failure. (An aphorism is born every day.)
#sed -i 's~~~' autogen.sh

#sh autogen.sh
#sys-devel/autoconf
#sys-devel/automake
#einfo "If you feel uncomfortable doing this, Daum is probably not for you. Yes, this is terrible."
# MIDI support requires ALSA support.
#REQUIRED_USE="midi? ( alsa )"
#epatch "${FILESDIR}/openglhq-dosbox-for-sdl-20130726_msvc_gcc.patch"

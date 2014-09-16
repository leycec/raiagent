# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Since iMule is a recent aMule fork, this ebuild is strongly inspired by the
# most recent "net-p2p/amule" ebuild. Thanks, all Portage contributors!

# Enable Bash strictness.
set -e

#FIXME: Replicate such "readme.gentoo" logic in all other currently mainted ebuilds.
inherit eutils flag-o-matic readme.gentoo wxwidgets user

MY_PNV="iMule-${PV}"

# Basename of the seed database required on initial iMule startup.
IMULE_NODES_BASE="${MY_PNV}-nodes.dat"

# Absolute path to which such database is installed.
IMULE_NODES_FILE="/usr/share/${PN}/nodes.dat"

DESCRIPTION="Free, open-source, anonymous, P2P file-sharing software connecting through the I2P and Kad networks"
HOMEPAGE="http://aceini.no-ip.info/imule"
SRC_URI="
	http://aceini.no-ip.info/imule/${PV}/${MY_PNV}-src.tbz
	http://aceini.no-ip.info/imule/nodes.dat -> ${IMULE_NODES_BASE}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="daemon geoip kde linkcreator mmap nls stats upnp +X"
#remote

COMMON_DEPEND="
	>=dev-libs/crypto++-5:0=
	>=sys-libs/zlib-1.2.1:0=
	virtual/libiconv:0=
	virtual/libintl:0=
	geoip? ( dev-libs/geoip:0= )
	kde?   ( kde-base/kdelibs:4= )
	stats? ( >=media-libs/gd-2.0.26:2=[jpeg] )
	upnp?  ( >=net-libs/libupnp-1.6.6:0= )
	X?     (
		>=x11-libs/wxGTK-2.8.12:2.8=[X]
		dev-qt/qtcore:4=
		dev-qt/qtgui:4=
	)
	!X? ( >=x11-libs/wxGTK-2.8.12:2.8= )
"
	#remote? (
	#	>=media-libs/gd-2.0.26:2=
	#	>=media-libs/libpng-1.2.0:0=
	#)
DEPEND="${COMMON_DEPEND}
	sys-devel/gcc[cxx]
	sys-devel/flex
"
RDEPEND="${COMMON_DEPEND}
	net-p2p/i2p
"

S="${WORKDIR}/${MY_PNV}-src"

src_prepare() {
	# If installing the KDE Plasma applet, prevent the corresponding makefile
	# from installing files already installed with KDE. (While we technically
	# only need to patch "Makefile.in", patch both for good measure.)
	if use kde; then
		sed -i -e 's~ ed2k.protocol magnet.protocol~~'\
			src/utils/plasmamule/Makefile.*
	fi

	# Technically, we should also patch the following non-fatal installation
	# issues specific to files matching /usr/share/applications/*.desktop:
	#
	# "* QA Notice: This package installs one or more .desktop files that do not
	#  * pass validation.
	#  * 
	#  * 	/usr/share/applications/imule.desktop: error: (will be fatal in the future): value "imule.xpm" for key "Icon" in group "Desktop Entry" is an icon name with an extension, but there should be no extension as described in the Icon Theme Specification if the value is not an absolute path
	#  * 	/usr/share/applications/imule.desktop: warning: value "Application;Network;" for key "Categories" in group "Desktop Entry" contains a deprecated value "Application"
	#  * 	/usr/share/applications/plasmamule-engine-feeder.desktop: error:
	#  file contains key "StartupWMClas" in group "Desktop Entry", but keys
	#  extending the format should start with "X-"'
	#
	# However, given iMule's current development hiatus, we can't be bothered.
}

src_configure() {
	# wxGTK version required by iMule.
	WX_GTK_VER=2.8

	# Unconditionally:
	#
	# * Disable ccache, already handled by Portage.
	# * Disable eDonkey links, handled on the clearnet and hence non-anonymously.
	# * Disable "remotegui" and "webserver", iMule's internal webserver hosting
	#   a remotely accessible web-based GUI. While we'd prefer to conditionally
	#   enable both under USE flag "remote", "remotegui" currently fails to
	#   compile with the following non-ignorable fatal error:
	#
	#    amule-remote-gui.cpp: In member function ‘void CamuleRemoteGuiApp::Startup()’:
	#    amule-remote-gui.cpp:392:39: error: invalid use of incomplete type ‘class CIP2Country’
	#    In file included from amule-remote-gui.cpp:43:0:
	#    amuleDlg.h:44:7: error: forward declaration of ‘class CIP2Country’
	#
	# * Disable imulecmd, the command line client. While we'd prefer to enable
	#   such client by default, it currently fails to compile with the
	#   following non-ignorable fatal error:
	#
	#    TextClient.cpp: In member function ‘virtual int CamulecmdApp::ProcessCommand(int)’:
	#    TextClient.cpp:472:75: error: invalid conversion from ‘int’ to ‘ECTagNames’ [-fpermissive]
	#    In file included from ./libs/ec/cpp/ECPacket.h:28:0,
	#                     from ./libs/ec/cpp/RemoteConnect.h:31,
	#                     from ExternalConnector.h:38,
	#                     from TextClient.h:29,
	#                     from TextClient.cpp:33:
	#    ./libs/ec/cpp/ECTag.h:104:9: error:   initializing argument 1 of ‘CECTag::CECTag(ECTagNames, uint16_t)’ [-fpermissive]
	#
	# While appending option "-fpermissive" to CXXFLAGS does correct some of
	# the above errors, other fatal errors quickly replace such errors Clearly,
	# neither the command line or remote GUI clients were rigorously tested.
	local -a econf_options; econf_options=(
		--with-wx-config="${WX_CONFIG}"
		--disable-ccache
		--disable-debug --enable-optimize
		--disable-dependency-tracking
		--disable-ed2k
		--disable-imulecmd
		--disable-imule-gui
		--disable-webserver
	)
		#--enable-imulecmd

	if use X; then
		need-wxwidgets unicode
		use linkcreator && econf_options+=( --enable-alc )
		use stats       && econf_options+=( --enable-wxcas )
		#use remote      && econf_options+=( --enable-imule-gui )
	else
		need-wxwidgets base-unicode
		econf_options+=(
			--disable-alc
			--disable-monolithic
			--disable-wxcas
		)
			#--disable-imule-gui
	fi

	econf "${econf_options[@]}"\
 		$(use_enable stats cas)\
 		$(use_enable daemon imule-daemon)\
 		$(use_enable geoip)\
 		$(use_enable kde plasmamule)\
		$(use_enable linkcreator alcc)\
 		$(use_enable mmap)\
 		$(use_enable nls)\
 		$(use_enable upnp)
		#$(use_enable remote webserver)
}

src_install() {
	emake DESTDIR="${D}" install

	if use daemon; then
		newconfd "${FILESDIR}"/imuled.confd imuled
		newinitd "${FILESDIR}"/imuled.initd imuled
	fi
	#if use remote; then
	#	newconfd "${FILESDIR}"/imuleweb.confd imuleweb
	#	newinitd "${FILESDIR}"/imuleweb.initd imuleweb
	#fi

	# Since the makefile installs documentation to "/usr/share/doc/${PN}",
	# move such directory to the expected "/usr/share/doc/${PNV}".
	mv "${D}/usr/share/doc/${PN}" "${D}/usr/share/doc/${P}"

	# Install the downloaded "nodes.dat" seed database for bootstrapping iMule.
	cp "${DISTDIR}/${IMULE_NODES_BASE}" "${D}/${IMULE_NODES_FILE}"

	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS="
iMule requires a seed database to be manually installed. To install the
database we have already provided for you, consider running:\\n
\\n
    mkdir ~/.iMule\\n
    cp ${EROOT}${IMULE_NODES_FILE} ~/.iMule\\n
\\n
iMule also requires the I2P SAM application bridge to be enabled. Since
such bridge is disabled under all default I2P installations, enable
such bridge before running iMule. Specifically:\\n
\\n
* Browse to http://127.0.0.1:7657/configclients (assuming a default I2P
  installation).\\n
* Check the \"SAM application bridge\" checkbox.\\n
* Click the \"Start\" button to the right of such checkbox.\\n
* Click the \"Save Client Configuration\" button.\""

	# Install such document.
	readme.gentoo_create_doc
}

pkg_preinst() {
	#if use daemon || use remote; then
	if use daemon; then
		enewgroup p2p
		enewuser  p2p -1 -1 /home/p2p p2p
	fi
}

pkg_postinst() {
	# On first installations of this package, elog the contents of the
	# previously installed "/usr/share/doc/${P}/README.gentoo" file.
	readme.gentoo_print_elog

	elog 'Installed iMule binaries include:'
	elog

	if use X; then
		elog '* "imule", the standard iMule GUI.'
	fi
	if use linkcreator; then
		use X &&
			elog '* "alc", the Link Creator GUI.'
			elog '* "alcc", the Link Creator CLI.'
	fi
	if use stats; then
		use X &&
			elog '* "wxcas", the iMule statistics GUI.'
			elog '* "cas", the iMule statistics CLI.'
	fi
	if use daemon; then
		elog '* "imuled", the iMule headless daemon. Configure such daemon at'
		elog '  "/etc/conf.d/imule" and run such daemon via:'
		elog '  eselect rc restart imuled'
	fi
}

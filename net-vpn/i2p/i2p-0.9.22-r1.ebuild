# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI="5"

# This ebuild intends to provide a more frequently updated version of I2P than
# that now officially bundled by Portage. For that reason, every effort should
# be made to prevent this ebuild from diverging too heavily from its official
# Portage analogue. (To that end, "/usr/portage/net-p2p/i2p/ChangeLog" should
# prove invaluable.)

#FIXME: Contact zlg@gentoo.org, the current maintainer of the official I2P
#ebuild. It'd be great if we could come to some agreement as to how changes
#between our two versions could be best synchronized.
#FIXME: Refactor "files/i2p" according to "sys-power/phc-k8/files". At the
#least, we probably want a separate configuration file.
#FIXME: Only generate "net.i2p.i2ptunnel.proxy.messages_${LANGUAGE}"
#ResourceBundles corresponding to currently enabled locales (e.g.,
#"net.i2p.i2ptunnel.proxy.messages_en"). By default, I2P's "build.xml" appears
#to generate all ResourceBundles for all supported languages -- which consumes
#an inordinate amount of both space and time during compilation.

inherit eutils user systemd readme.gentoo java-pkg-2 java-ant-2

DESCRIPTION="The Invisible Internet Project"
HOMEPAGE="https://geti2p.net"
SRC_URI="https://download.i2p2.de/releases/${PV}/i2psource_${PV}.tar.bz2"

#FIXME: This list *STILL* appears to be incomplete. Ideally, there should be a
#one-for-one correspondence between licenses listed below and files listed in
#the "licenses/" subdirectory.

# As the list below suggests, I2P's licensing landscape is among the most
# complex of any open-source software yet invented. *IT IS INSANE.*
#
# Let's unpack this a bit. I2P's top-level "LICENSE.txt" file asserts all I2P
# code not otherwise licensed to be granted to the public domain under the
# all-caps "NO WARRANTY" license prefixing that file. For disambiguity, this
# overlay retains such license as "licenses/i2p". All other licenses listed
# below are given by the additional licenses suffixing that file, typically
# corresponding to external code embedded in the I2P codebase.
LICENSE="i2p Apache-2.0 Artistic BSD CC-BY-2.5 CC-BY-3.0 CC-BY-SA-3.0 EPL-1.0 GPL-2 GPL-3 LGPL-2.1 LGPL-3 MIT public-domain WTFPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="nls"

#FIXME: We really want to unbundle everything. See what else we can do.
#FIXME: The "i2psvc" wrapper appears to be a separate open-source dependency.
#This should probably be the first dependency we unbundle. See:
#    http://i2p-projekt.i2p/en/misc/manual-wrapper

# See "INSTALL.txt" for the complete list of all dependencies.
#
# The Simple Logging Framework for Java (SLF4J) consists of two components: an
# abstract API and an underlying implementation. Naturally, there exists only
# one API but multiple available implementations. Ideally, there would exist a
# corresponding "virtual/slf4j-impl" package upon which this package could
# depend, permitting users to install the implementation of their choice. Even
# if such package existed, however, actually supporting such conditionality here
# would be non-trivial (e.g., due to the name of the desired implementation
# being embedded in the ${EANT_GENTOO_CLASSPATH} global below). For these
# reasons and as most I2P users are unlikely to require the complex facilities
# provided by the Logging for Java (log4j12) implementation, we unconditionally
# require the simplest possible implementation -- appropriately named "simple".
CDEPEND="
	dev-java/bcprov:1.50
	dev-java/java-service-wrapper:0
	dev-java/jrobin:0
	dev-java/slf4j-api:0
	dev-java/slf4j-simple:0
	dev-java/tomcat-jstl-impl:0
	dev-java/tomcat-jstl-spec:0
"
DEPEND="${CDEPEND}
	>=virtual/jdk-1.6
	dev-java/eclipse-ecj:*
	dev-libs/gmp:*
	nls? ( sys-devel/gettext )
"
RDEPEND="${CDEPEND}
	>=virtual/jre-1.6
"

# Absolute path of I2P's system-wide data resources directory.
I2P_DATA_DIR="${EROOT}usr/share/${PN}"

# Absolute path of I2P's system-wide runtime state directory. 
I2P_STATE_DIR="${EROOT}var/lib/${PN}"

#FIXME: Either:
#
#* The "updater" task should be manually expunged from the "pkg" task's
#  dependencies in "build.xml" *OR*
#* The "distclean" and "installer" tasks should be run instead.
#
#We favour the latter, for obvious reasons.

# Whitespace-delimited list of the names of all "build.xml" Ant tasks to be run.
# Note that this is *NOT* the default "pkg" task, a wrapper task performing:
#
#     "distclean updater preppkg installer"
#
# The "preppkg" task is already performed by the "installer" task and hence
# redundant. The "updater" task builds I2P's updater archive, which this ebuild
# obsoletes and is hence irrelevant. All remaining tasks are listed below.
EANT_BUILD_TARGET="distclean installer"

# Comma-delimited list of the names of all Java-specific dependencies to be
# added to the "${gentoo.classpath}" property added to "build.xml" by the call
# to java-ant_rewrite-classpath() below. While listing such dependencies here
# technically adds such dependencies to ${DEPEND}, we explictly add such
# dependencies to ${DEPEND} above anyway (e.g., to require slots or versions).
# Yup, this is obscure beyond belief.
#
# Note that "eclipse-ecj" is intentionally omitted here, principally due to
# resulting in fatal compile-time errors.
EANT_GENTOO_CLASSPATH="bcprov-1.50,java-service-wrapper,jrobin,slf4j-api,slf4j-simple,tomcat-jstl-impl,tomcat-jstl-spec"

pkg_setup() {
	enewgroup ${PN}
	enewuser ${PN} -1 -1 "${I2P_STATE_DIR}" ${PN} -m
}

src_unpack() {
	default_src_unpack

	# Add 'classpath="${gentoo.classpath}"' to "build.xml". Annoyingly, this
	# function *MUST* be explicitly called here.
	java-ant_rewrite-classpath "${S}"/build.xml
}

src_prepare() {
	# Unconditionally avoid building Windows-specific executables.
	echo "noExe=true" >> override.properties || die '"echo" failed.'

	# Conditionally disable "gettext" support.
	use nls || echo "require.gettext=false" >> override.properties ||
		die '"echo" failed.'
}

src_install() {
	#FIXME: O.K.; we'll need to convince zgl that the current approach is...
	#well, to put it charitably, "bunk." The simplest inarguable reason why is
	#Gentoo Prefix. The value of ${EROOT} cannot be statically embedded into
	#patch files at ebuild construction time, but *MUST* paradoxically be
	#patched into the generated "wrapper.config" file at installation time.
	#It follows that only some combination of command-line utilities (e.g.,
	#"awk", "sed") run at installation time suffices. This being the case
	#*AND* such utilities being generally preferable to fragile patch files,
	#there exists no compelling reason to apply patch files during installation.

	# Patch files generated by the prior src_compile() phase.
	cd pkg-temp || die '"cd" failed.'

	# Prevent I2P startup from autostarting a browser (typically, "lynx").
	# Dismantled, this is:
	#
	# * "-n", suppressing printing of lines by default.
	# * "~p", printing only the index of I2P's UrlLauncher application.
	local url_launcher_index="$(sed -n -e\
		'/UrlLauncher/s~^clientApp\.\([0-9]\+\)\..*$~\1~p' clients.config)"
	sed -i -e\
		'/^clientApp\.'${url_launcher_index}'\.startOnLoad=/s~true~false~' \
		clients.config || die '"sed" failed.'

	# Replace I2P's default data directory with ours.
	sed -i -e 's~%INSTALL_PATH~'${I2P_DATA_DIR}'~g' \
		eepget i2prouter runplain.sh || die '"sed" failed.'
	sed -i -e 's~\$INSTALL_PATH~'${I2P_DATA_DIR}'~g' \
		wrapper.config || die '"sed" failed.'

	# Replace I2P's default user-specific home directory with the real thing.
	# Dismantled, this is:
	#
	# * "/a\", appending all following lines to the currently matched line.
	sed -i -e '/I2P=/a\
USER_HOME="$HOME"\
SYSTEM_java_io_tmpdir="$USER_HOME/.i2p"' \
		i2prouter || die '"sed" failed.'
	sed -i -e 's~%\(USER_HOME\)~$\1~g' i2prouter || die '"sed" failed.'
	sed -i -e 's~%\(SYSTEM_java_io_tmpdir\)~$\1~g' \
		i2prouter runplain.sh || die '"sed" failed.'

	# Unbundle embedded JAR dependencies. For each such dependency listed in
	# ${EANT_GENTOO_CLASSPATH} above, there should exist a corresponding line
	# below adding that dependency's system-provided JAR files to the classpath.
	sed -i \
		-e '/^wrapper\.java\.classpath\.1=/a\
wrapper.java.classpath.2='${EROOT}'usr/share/bcprov-1.50/lib/*.jar\
wrapper.java.classpath.3='${EROOT}'usr/share/java-service-wrapper/lib/*.jar\
wrapper.java.classpath.4='${EROOT}'usr/share/jrobin/lib/*.jar\
wrapper.java.classpath.5='${EROOT}'usr/share/slf4j-api/lib/*.jar\
wrapper.java.classpath.6='${EROOT}'usr/share/slf4j-simple/lib/*.jar\
wrapper.java.classpath.7='${EROOT}'usr/share/tomcat-jstl-impl/lib/*.jar\
wrapper.java.classpath.8='${EROOT}'usr/share/tomcat-jstl-spec/lib/*.jar' \
		-e '/^wrapper\.java\.library\.path\.2=/a\
wrapper.java\.library\.path.3='${EROOT}'usr/lib/java-service-wrapper' \
		wrapper.config || die '"sed" failed.'

	#FIXME: It shouldn't be terribly difficult to unbundle at least a few of
	#these (e.g., "commons-el", "commons-logging", "javax.servlet"). An
	#unofficial I2P ebuild contained the following pertinent commentary:
	#
	#   FIXME - setting paths is not sufficient for those, so we symlink
	#  dosym /usr/lib/commons-logging/commons-logging.jar ${i2p_home}/lib/commons-logging.jar || die
	#  dosym /usr/lib/commons-el/commons-el.jar ${i2p_home}/lib/commons-el.jar || die

	# Install (most) bundled JAR dependencies. While terrible, Jetty and
	# systray4j are particularly non-trivial to unbundle. 
	java-pkg_jarinto "${I2P_DATA_DIR}"/lib

	# For each basename (sans assumed ".jar" filetype) of such a dependency
	# residing in the "lib/" subdirectory, install the corresponding JAR file.
	local jar_glob
	for   jar_glob in \
		BOB commons-el commons-logging i2p i2psnark i2ptunnel jasper-compiler \
		jasper-runtime javax.servlet jbigi jetty-* mstreaming org.mortbay.* \
		router routerconsole sam standard streaming systray systray4j; do
		# Unlike zsh, bash delays glob expansion to command execution. Hence,
		# ${jar_glob} must be unquoted to ensure glob expansion here.
		java-pkg_dojar lib/${jar_glob}.jar
	done

	# Install all bundled web applications.
	java-pkg_dowar webapps/*.war

	# Install binaries.
	exeinto "${I2P_DATA_DIR}"
	doexe eepget i2prouter runplain.sh

	#FIXME: Documentation should probably only be conditionally installed if the
	#"doc" USE flag is enabled, yes? Regardless, there appear to be numerous
	#"docs/" subdirectories that have no actual bearing on documentation and
	#should probably *NOT* be installed (e.g., "docs/themes/"). Investigate us.

	# Install resources.
	insinto "${I2P_DATA_DIR}"
	doins blocklist.txt hosts.txt *.config
	doins -r certificates docs eepsite geoip scripts

	# Install documentation.
	dodoc history.txt INSTALL-headless.txt LICENSE.txt
	doman man/*

	# Symlink I2P binaries into the current ${PATH}.
	dosym "${I2P_DATA_DIR}"/i2prouter /usr/bin/i2prouter
	dosym "${I2P_DATA_DIR}"/eepget /usr/bin/eepget

	# Symlink the "/usr/bin/wrapper" binary installed by Java Service Wrapper as
	# a new "i2psvc" daemon in I2P's data directory. This daemon is typically
	# *NOT* run directly and hence need not appear in the current ${PATH}.
	dosym /usr/bin/wrapper "${I2P_DATA_DIR}"/i2psvc

	# Unconditionally install both OpenRC and systemd services. 
	doinitd "${FILESDIR}"/${PN}
	systemd_dounit "${FILESDIR}"/${PN}.service

	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS="
	For responsivity, I2P should typically be added the default runlevel: e.g.,\\n
	\\trc-update add i2p default\\n\\n
	After starting the I2P service, I2P will be accessible via the web-based I2P\\n
	Router Console at:\\n
	\\thttp://localhost:7657\\n\\n
	I2P customization should be isolated to \"${I2P_STATE_DIR}/.i2p/\" to\\n
	prevent future updates from overwriting changes."

	# Install Gentoo-specific documentation.
	readme.gentoo_create_doc
}

pkg_postinst() {
	# On first installation, print Gentoo-specific documentation.
	readme.gentoo_print_elog

	# On subsequent updates, print the following instructions.
	if [[ -n ${REPLACING_VERSIONS} ]]; then
		elog \
'If I2P fails to properly start after this upgrade, check the I2P logfile at'
		elog \
'"/var/log/i2p/log-router-0.txt". When in doubt, the simplest solution is to'
		elog \
'remove your entire I2P configuration and begin anew: e.g.,'
		elog
		elog '    $ sudo mv '${I2P_STATE_DIR}' /tmp/.i2p.bad'
		elog '    $ sudo rc-service i2p restart'
		elog
		elog \
'While I2P does attempt to preserve backward compatibility across upgrades,'
		elog \
"Murphy's Law and personal experience suggests otherwise."
	fi
}

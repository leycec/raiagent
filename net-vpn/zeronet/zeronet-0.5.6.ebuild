# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

#FIXME: Adds Python 3.x support after the following upstream issue is resolved:
#    https://github.com/HelloZeroNet/ZeroNet/issues/149
PYTHON_COMPAT=( python2_7 )

#FIXME: Replace "python-single-r1" with "distutils-r1" after ZeroNet adds
#"setup.py"-based PyPI integration, tracked at the following issue:
#    https://github.com/HelloZeroNet/ZeroNet/issues/382
#Note that, after doing so, the src_install() function will require heavy edits.
inherit systemd user readme.gentoo-r1 python-single-r1

DESCRIPTION="Decentralized websites using Bitcoin crypto and BitTorrent network"
HOMEPAGE="https://zeronet.io https://github.com/HelloZeroNet/ZeroNet"

LICENSE="GPL-2"
SLOT="0"
IUSE="debug tor"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

#FIXME: Unbundle all bundled Python dependencies in the "src/lib" directory.
#Doing so is complicated, however, by ZeroNet requiring:
#
#* Dependencies for which no Portage package currently exists, including:
#  * "BitcoinECC".
#  * "bencode". While a "dev-haskell/bencode" package exists, no corresponding
#    "dev-python/bencode" exists.
#  * "cssvendor".
#  * "opensslVerify". This appears to be a ZeroNet-specific package rather than
#    a bundled dependency, despite residing in the "src/lib" directory.
#  * "pybitcointools".
#  * "pyelliptic".
#  * "subtl".
#* Obsolete versions of packages no longer provided by Portage, including:
#  * "=dev-python/PySocks-1.5.3". Due to Tor and gevent complications, ZeroNet
#    explicitly reverted the bundled version of PySocks from a newer version
#    back to 1.5.3. Ergo, this appears to be a hard requirement.
#* Newer versions of packages not yet provided by Portage, including:
#  * "=dev-python/gevent-websocket-0.10.1".
#  * "=dev-python/pyasn1-0.2.4".
#  * "=dev-python/rsa-3.4.2".
#    
#Note that any bundled Python dependency *NOT* internally modified for ZeroNet
#may be safely unbundled once Portage provides a sufficient package version as
#follows:
#
#* Remove the "src/lib" subdirectory containing this dependency (e.g.,
#  "src/lib/pyasn1").
#* Append an import statement to the "src/lib/__init__.py" submodule importing
#  the system-wide version of this dependency (e.g., "import pyasn1").
#
#Tragically, numerous bundled dependencies are internally modified for ZeroNet,
#as the git history for these dependencies' subdirectories trivially shows. For
#each such dependency, submit an upstream issue requesting that this dependency
#be officially unbundled from ZeroNet and dynamically monkey-patched at runtime
#instead. Until ZeroNet itself unbundles these dependencies, there's little we
#can reasonably do here.

# Dependencies derive from the following sources:
#
# * The top-level "requirements.txt" file.
# * The "src/lib" directory, containing all bundled dependencies.
# * The "src/Debug/DebugMedia.py" file, dynamically forking the optional
#   "dev-lang/coffee-script" dependency when merging Coffee- to JavaScript..
# * The "src/Debug/DebugReloader.py" file, dynamically importing the optional
#   "dev-python/fs" dependency when passed the "--debug" option.
# * The "src/Ui/UiServer.py" file, dynamically importing the optional
#   "dev-python/werkzeug" dependency when passed the "--debug" option.
#
# Unfortunately, no official list of dependencies currently exists.
DEPEND="${PYTHON_DEPS}"
RDEPEND="${DEPEND}
	>=dev-python/gevent-1.1.0[${PYTHON_USEDEP}]
	>=dev-python/msgpack-0.4.4[${PYTHON_USEDEP}]
	debug? (
		>=dev-lang/coffee-script-1.9.3
		>=dev-python/fs-0.5.4[${PYTHON_USEDEP}]
		>=dev-python/werkzeug-0.11.11[${PYTHON_USEDEP}]
	)
	tor? ( >=net-vpn/tor-0.2.7.5 )
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/HelloZeroNet/ZeroNet"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="https://github.com/HelloZeroNet/ZeroNet/archive/v${PV}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/ZeroNet-${PV}"
fi

ZERONET_CONF_FILE="/etc/${PN}.conf"
ZERONET_LOG_DIR="/var/log/${PN}"
ZERONET_MODULE_DIR="/usr/share/${PN}"
ZERONET_PID_FILE="/var/run/${PN}.pid"
ZERONET_SCRIPT_FILE="/usr/bin/${PN}"
ZERONET_STATE_DIR="/var/lib/${PN}"

pkg_setup() {
	python-single-r1_pkg_setup

	# Create the ZeroNet user and group. Since ZeroNet sites are typically
	# modified while logged in as this user, a default login shell is set.
	enewgroup ${PN}
	enewuser  ${PN} -1 /bin/sh "${ZERONET_STATE_DIR}" ${PN}
}

src_prepare() {
	default_src_prepare

	#FIXME: File an upstream issue requesting:
	#
	#* The default logfile logging level be reduced from "DEBUG" to "INFO".
	#* A command-line option be added permitting this level to be configured at
	#  runtime rather than manually patched into the codebase at build time.

	# If debugging is disabled, reduce ZeroNet's default logfile logging level
	# of "DEBUG" to "INFO" to avoid consuming all available disk space.
	if ! use debug; then
		sed -i -e '/\blevel=logging.DEBUG\b/ s~\bDEBUG\b~INFO~' src/main.py ||
			die '"sed" failed.'
	fi
}

# ZeroNet provides no "setup.py" script and hence requires manual installation.
src_install() {
	# If Tor is enabled, require Tor in all files generated below.
	if use tor; then
		ZERONET_CONF_OPTIONS='tor = always'
		ZERONET_OPENRC_DEPENDENCIES='need tor'
		ZERONET_SYSTEMD_DEPENDENCIES='After=tor.service'
	else
		ZERONET_CONF_OPTIONS=''
		ZERONET_OPENRC_DEPENDENCIES=''
		ZERONET_SYSTEMD_DEPENDENCIES=''
	fi

	# If debugging is enabled, produce unoptimized and hence debuggable
	# bytecode; else, produce slightly optimized bytecode.
	if use debug; then
		ZERONET_PYTHON_OPTIONS=''
	else
		ZERONET_PYTHON_OPTIONS='-O'
	fi

	#FIXME: Consider passing ${PYTHON} the "-O" option to optimize bytecode
	#generation. For safety, this option has been omitted until tested.

	# Dynamically create and install a shell script launching ZeroNet with the
	# current Python version.
	cat <<EOF > "${T}"/${PN}
##!/usr/bin/env sh
exec ${PYTHON} ${ZERONET_PYTHON_OPTIONS} "${ZERONET_MODULE_DIR}/${PN}.py" --config_file "${ZERONET_CONF_FILE}" "\${@}"
EOF
	dobin "${T}"/${PN}

	# Dynamically create and install a ZeroNet configuration file. Since ZeroNet
	# fails to provide a default template, a Gentoo-specific file is constructed.
	# Sadly, this file's syntax is incompatible with that of "/etc/conf.d" files.
	cat <<EOF > "${T}"/${PN}.conf
# Configuration file for ZeroNet's "${ZERONET_SCRIPT_FILE}" launcher script.

# For each "--"-prefixed command-line option accepted by the "${PN}" script
# (e.g., "--data_dir"), a key of the same name excluding that prefix (e.g.,
# "data_dir") permanently setting that option may be defined by this section.
# Due to deficiencies in ZeroNet's configuration file parser, option values
# should *NOT* be single- or double-quoted.
#
# For a list of all supported options, see "${PN} --help".
[global]
data_dir = ${ZERONET_STATE_DIR}
log_dir = ${ZERONET_LOG_DIR}
${ZERONET_CONF_OPTIONS}
EOF
	insinto /etc
	doins "${T}"/${PN}.conf

	# Dynamically create and install an OpenRC script.
	cat <<EOF > "${T}"/${PN}.initd
#!/sbin/openrc-run
# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

depend() {
	need net
	${ZERONET_OPENRC_DEPENDENCIES}
}

start() {
	ebegin "Starting ZeroNet"
	start-stop-daemon --start --user ${PN} --pidfile "${ZERONET_PID_FILE}" --quiet --background --make-pidfile --exec "${ZERONET_SCRIPT_FILE}" main

	# Exit successfully only if a ZeroNet process with this PID is running.
	sleep 2
	[ -e "${ZERONET_PID_FILE}" -a -e /proc/\$(cat "${ZERONET_PID_FILE}") ]
	eend $?
}

stop() {
	ebegin "Stopping ZeroNet"
	start-stop-daemon --stop --user ${PN} --pidfile "${ZERONET_PID_FILE}" --quiet --retry SIGTERM/20 SIGKILL/20 --progress --exec "${ZERONET_SCRIPT_FILE}"
	eend $?
}

EOF
	newinitd "${T}"/${PN}.initd ${PN}

	# Dynamically create and install a systemd service unit.
	cat <<EOF > "${T}"/${PN}.service
[Unit]
Description=ZeroNet: ${DESCRIPTION}
After=network.target
${ZERONET_SYSTEMD_DEPENDENCIES}

[Service]
Type=simple
User=${PN}
Group=${PN}
ExecStart=${ZERONET_SCRIPT_FILE} main
TimeoutSec=256
WorkingDirectory=${ZERONET_STATE_DIR}

[Install]
WantedBy=multi-user.target
EOF
	systemd_dounit "${T}"/${PN}.service

	# Install ZeroNet's Python codebase.
	python_moduleinto "${ZERONET_MODULE_DIR}"
	python_domodule ${PN}.py plugins src tools

	# Create ZeroNet's logging and state directories.
	keepdir                "${ZERONET_LOG_DIR}" "${ZERONET_STATE_DIR}"
	fowners -R ${PN}:${PN} "${ZERONET_LOG_DIR}" "${ZERONET_STATE_DIR}"

	# Install all Markdown files as documentation.
	dodoc *.md

	# URL of ZeroHello.
	ZEROHELLO_URL="http://127.0.0.1:43110"

	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS="
	OpenRC users should typically add ZeroNet to the default runlevel:\\n
	\\trc-update add ${PN} default\\n\\n

	After starting ZeroNet, ZeroHello (the web interface bundled with ZeroNet)
	may be locally browsed to at:\\n
	\\t${ZEROHELLO_URL}\\n\\n

	ZeroNet sites should typically be edited while logged in as the \"${PN}\"
	user: e.g.,\\n
	\\tsudo su - ${PN}\\n
	"

	if use tor; then
		# Absolute path of Tor's ZeroNet-specific authentication directory. By
		# default, the "CookieAuthFile" configuration option defined below
		# defaults to "/var/lib/tor/data/control_auth_cookie". For security
		# reasons, however, the "tor" group to which the "zeronet" user belongs
		# does *NOT* have read permissions to access this directory and hence
		# this file. The only secure alternative is to isolate the
		# "control_auth_cookie" file to a custom directory to which the "tor"
		# group may be granted read permissions without compromising security.
		TOR_AUTH_DIR="/var/lib/tor/auth"

		DOC_CONTENTS+="\\n
	Manually enable Tor-based ZeroNet anonymization as follows:\\n
	* Stop Tor if started:\\n
	\\trc-service tor stop\\n
	* Add the ZeroNet user to the Tor group:\\n
	\\tusermod --append --groups=tor zeronet\\n
	* Permit ZeroNet to read Tor's authentication cookie:\\n
	\\tmkdir --mode=750 ${TOR_AUTH_DIR}\\n
	\\tchown -R tor: ${TOR_AUTH_DIR}\\n
	* Edit \"/etc/tor/torrc\" as follows:\\n
	\\t* Uncomment the following commented lines:\\n
	\\t\\t#ControlPort 9051\\n
	\\t\\t#CookieAuthentication 1\\n
	\\t* Add the following lines anywhere:\\n
	\\t\\tCookieAuthFile ${TOR_AUTH_DIR}/control_auth_cookie\\n
	\\t\\tCookieAuthFileGroupReadable 1\\n
	* Restart Tor and ZeroNet:\\n
	\\trc-service tor restart\\n
	\\trc-service zeronet restart\\n
	* Verify that your ZeroNet IP address is not your physical IP address at the
	  ZeroHello Stats page:\\n
	\\t${ZEROHELLO_URL}/Stats\\n\\n

	Manually enable Tor Browser-based ZeroNet support as follows:\\n
	* Open Tor Browser.\\n
	* Browse to:\\n
	\\tabout:preferences#advanced\\n
	* Click the \"Settings...\" button to the right of the \"Configure how Tor
	  Browser connects to the Internet\" text label.\\n
	* Enter the following text in the \"No Proxy for\" text area:\\n
	\\t127.0.0.1\\n
	* Click the \"OK\" button.\\n
	* Browse to:\\n
	\\t${ZEROHELLO_URL}\\n\\n
	ZeroNet recommends browsing ZeroNet sites only with Tor Browser. Explicit
	warnings will be displayed on detecting any other browser.
	"
	fi

	# Install the above Gentoo-specific documentation.
	readme.gentoo_create_doc
}

pkg_postinst() {
	# Display the above Gentoo-specific documentation on the first installation
	# of this package.
	readme.gentoo_print_elog
}

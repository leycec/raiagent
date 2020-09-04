# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,7,8} )

#FIXME: Replace "python-single-r1" with "distutils-r1" after ZeroNet adds
#"setup.py"-based PyPI integration, tracked at the following issue:
#    https://github.com/HelloZeroNet/ZeroNet/issues/382
#Note that, after doing so, the src_install() function will require heavy edits.
inherit systemd readme.gentoo-r1 python-single-r1

DESCRIPTION="Decentralized websites using Bitcoin crypto and BitTorrent network"
HOMEPAGE="https://zeronet.io https://github.com/HelloZeroNet/ZeroNet"

LICENSE="GPL-2"
SLOT="0"
IUSE="debug meek tor"
REQUIRED_USE="${PYTHON_REQUIRED_USE}
	meek? ( tor )
"

#FIXME: Consider removing "pyelliptic" on the next bump.

# Dependencies derive from the following sources:
#
# * The top-level "requirements.txt" file.
# * The "src/lib" directory, containing all bundled dependencies.
# * The "src/Debug/DebugMedia.py" file, dynamically running the optional
#   "dev-lang/coffee-script" dependency when merging Coffee- to JavaScript.
# * The "src/Debug/DebugReloader.py" file, dynamically importing the optional
#   "dev-python/fs" dependency when passed the "--debug" option.
# * The "src/Ui/UiServer.py" file, dynamically importing the optional
#   "dev-python/werkzeug" dependency when passed the "--debug" option.
#
# Unfortunately, no official list of dependencies currently exists.
# Additionally, note that:
#
# * The "gevent[test]" USE flag is unconditionally enabled, as ZeroNet imports
#   the "gevent.monkey" subpackage (typically only enabled during unit testing)
#   to monkey-patch various third-party Python package at runtime. If this USE
#   flag is disabled, ZeroNet raises non-human-readable exceptions at startup.
DEPEND="${PYTHON_DEPS}"
RDEPEND="${PYTHON_DEPS}
	acct-group/zeronet
	acct-user/zeronet
	dev-python/base58
	dev-python/bencode_py
	dev-python/coincurve
	dev-python/gevent-websocket
	dev-python/maxminddb
	dev-python/merkletools
	dev-python/pyasn1
	dev-python/python-bitcoinlib
	dev-python/rsa
	dev-python/websocket-client
	$(python_gen_cond_dep \
	   '~dev-python/pyelliptic-1.5.6[${PYTHON_USEDEP}]' -3 )
	$(python_gen_cond_dep \
		'>=dev-python/PySocks-1.6.8[${PYTHON_USEDEP}]' -3 )
	$(python_gen_cond_dep \
		'>=dev-python/gevent-1.1.0[${PYTHON_USEDEP},test]' -3 )
	$(python_gen_cond_dep \
		'>=dev-python/msgpack-0.4.4[${PYTHON_USEDEP}]' -3 )
	debug? (
		>=dev-lang/coffee-script-1.9.3
		$(python_gen_cond_dep \
			'>=dev-python/fs-0.5.4[${PYTHON_USEDEP}]' -3 )
		$(python_gen_cond_dep \
			'>=dev-python/werkzeug-0.11.11[${PYTHON_USEDEP}]' -3 )
	)
	tor? ( >=net-vpn/tor-0.2.7.5 )
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	# Note that the Python 2.7-specific "master" branch has been effectively
	# discontinued in favour of the Python 3-specific "py3" branch.
	EGIT_REPO_URI="https://github.com/HelloZeroNet/ZeroNet"
	EGIT_BRANCH="py3"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="https://github.com/HelloZeroNet/ZeroNet/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/ZeroNet-${PV}"
fi

ZERONET_CONF_FILE=/etc/${PN}.conf
ZERONET_LOG_DIR=/var/log/${PN}
ZERONET_MODULE_DIR=/usr/share/${PN}
ZERONET_PID_FILE=/var/run/${PN}.pid
ZERONET_SCRIPT_FILE=/usr/bin/${PN}
ZERONET_STATE_DIR=/var/lib/${PN}

# Prevent the "readme.gentoo-r1" eclass from autoformatting documentation via
# the external "fmt" and "echo -e" commands for readability.
DISABLE_AUTOFORMATTING=1

#FIXME: Uncomment this line to test "readme.gentoo-r1" documentation.
#FORCE_PRINT_ELOG=1

# ZeroNet offers no "setup.py" script and thus requires manual installation.
src_install() {
	# Newline-delimited string of all TOML-formatted options to be set by the 
	# ZeroNet configuration file generated below.
	ZERONET_CONF_OPTIONS=''

	# Space-delimited string of all command-line options to be passed to the
	# Python interpreter running ZeroNet generated below.
	ZERONET_PYTHON_OPTIONS=''

	# Space-delimited string of all OpenRC dependencies required by the ZeroNet
	# OpenRC startup script generated below.
	ZERONET_OPENRC_DEPENDENCIES=''

	# Space-delimited string of all systemd dependencies required by the
	# ZeroNet systemd startup script generated below.
	ZERONET_SYSTEMD_DEPENDENCIES=''

	# If debugging:
	#
	# * Increase logging verbosity to the maximum.
	# * Generate unoptimized and hence debuggable bytecode.
	if use debug; then
		ZERONET_CONF_OPTIONS+='log_level = DEBUG'$'\n'
	# Else:
	#
	# * Decrease logging verbosity from "DEBUG" to "INFO" to avoid consuming
	#   all available disk space immediately.
	# * Generate only slightly optimized bytecode.
	else
		ZERONET_CONF_OPTIONS+='log_level = INFO'$'\n'
		ZERONET_PYTHON_OPTIONS+='-O'
	fi

	# If enabling Tor, do so in all ZeroNet files generated below.
	#
	# Note that setting "tor = always" suffices to unconditionally proxy *ALL*
	# connections (including trackers) through Tor. For that reason, attempting 
	# to set "trackers_proxy = tor" here would be ignored by ZeroNet. See also:
	#     https://github.com/HelloZeroNet/ZeroNet/issues/2147#issuecomment-524147130
	if use tor; then
		ZERONET_CONF_OPTIONS+='tor = always'$'\n'
		ZERONET_OPENRC_DEPENDENCIES='need tor'
		ZERONET_SYSTEMD_DEPENDENCIES='After=tor.service'
	fi

	# If enabling Tor meek integration, do so as well. Note that doing so
	# necessarily incurs a bandwidth cost and hence is disabled by default.
	if use meek; then
		ZERONET_CONF_OPTIONS+='tor_use_bridges'$'\n'
	fi

	# Dynamically create and install a shell script launching ZeroNet with the
	# currently selected Python version, configured by the system-wide
	# configuration file created below.
	#
	# Note that ZeroNet comes bundled with a largely useless "start.py" script,
	# which unhelpfully opens the local ZeroNet console in a "default browser"
	# after starting ZeroNet. Unsurprisingly, we ignore this script entirely.
	cat <<EOF > "${T}"/${PN}
#!/usr/bin/env sh
exec ${PYTHON} ${ZERONET_PYTHON_OPTIONS} "${ZERONET_MODULE_DIR}/${PN}.py" --config_file "${ZERONET_CONF_FILE}" "\${@}"
EOF
	dobin "${T}"/${PN}

	# Dynamically create and install a ZeroNet configuration file. As ZeroNet
	# fails to provide a default template, a Gentoo-specific file is generated.
	# Note that this file is TOML-formatted and hence technically incompatible
	# with that of standard shell-formatted "/etc/conf.d/" files.
	cat <<EOF > "${T}"/${PN}.conf
# Configuration file for ZeroNet's "${ZERONET_SCRIPT_FILE}" launcher script.
#
# For each "--"-prefixed command-line option accepted by the "${PN}" script
# (e.g., "--data_dir"), a key of the same name excluding that prefix (e.g.,
# "data_dir") permanently setting that option may be defined in this section.
# Due to flaws in ZeroNet's configuration file parser, option values should
# *NOT* be single- or double-quoted.
#
# For a list of all supported options, see "${PN} --help".
[global]
config_file = ${ZERONET_CONF_FILE}
data_dir = ${ZERONET_STATE_DIR}
log_dir = ${ZERONET_LOG_DIR}
${ZERONET_CONF_OPTIONS}
EOF
	insinto /etc
	doins "${T}"/${PN}.conf

	# Dynamically create and install an OpenRC script.
	cat <<EOF > "${T}"/${PN}.initd
#!/sbin/openrc-run
# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

depend() {
	need net
	${ZERONET_OPENRC_DEPENDENCIES}
}

start() {
	ebegin "Starting ZeroNet"

	# Note that we wait 2000ms (i.e., 2s) after daemonizing ZeroNet to validate
	# that ZeroNet successfully daemonized.
	start-stop-daemon --start --user ${PN} --pidfile "${ZERONET_PID_FILE}" \\
		--background --make-pidfile --progress --wait 2000 \\
		--exec "${ZERONET_SCRIPT_FILE}" main
	eend $?
}

stop() {
	ebegin "Stopping ZeroNet"
	start-stop-daemon --stop --user ${PN} --pidfile "${ZERONET_PID_FILE}" \\
		--progress --retry TERM/10/KILL/20 \\
		--exec "${ZERONET_SCRIPT_FILE}"
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

	# URL of ZeroHello.
	ZEROHELLO_URL="http://127.0.0.1:43110"

	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS="OpenRC users should typically add ZeroNet to the default runlevel:
	$ rc-update add ${PN} default

After starting ZeroNet, ZeroHello (the web interface bundled with ZeroNet)
may be locally browsed to at:
	${ZEROHELLO_URL}

ZeroNet zites are safely editable *ONLY* while logged in as the \"${PN}\"
user: e.g.,
	$ sudo su - ${PN}
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

		DOC_CONTENTS+="
Tor-based ZeroNet anonymization *MUST* be manually enabled as follows:

	1. Stop Tor if started:
		$ rc-service tor stop
	2. Add the ZeroNet user to the Tor group:
		$ usermod --append --groups=tor zeronet
	3. Permit ZeroNet to read Tor's authentication cookie:
		$ mkdir --mode=750 ${TOR_AUTH_DIR}
		$ chown -R tor: ${TOR_AUTH_DIR}
	4. Append the following lines to \"/etc/tor/torrc\":
		# ZeroNet-specific authentication cookie.
		ControlPort 9051
		CookieAuthentication 1
		CookieAuthFile ${TOR_AUTH_DIR}/control_auth_cookie
		CookieAuthFileGroupReadable 1
	5. Restart ZeroNet and Tor:
		$ rc-service zeronet restart
	6. Verify that your ZeroNet IP address is not your physical IP address at
	   the ZeroHello Stats page:
		${ZEROHELLO_URL}/Stats

ZeroNet recommends browsing ZeroNet zites only with Tor Browser when Tor
support is enabled. Warnings will be displayed on attempting to browse with any
other browser. To do so:

	1. Install Tor Browser, ideally via the "torbrowser" overlay as follows:
		1. Install the "repository" subcommand for the "eselect" command:
			$ emerge --ask eselect-repository
		2. Enable the "torbrowser" overlay:
			$ eselect repository enable torbrowser
		3. Clone the "torbrowser" overlay:
			$ emerge --sync
		4. Install the Tor Browser Launcher:
			$ emerge --ask torbrowser-launcher
	2. Launch Tor Browser:
		$ torbrowser-launcher &!
	3. Browse to:
		about:preferences#advanced
	4. Click the \"Settings...\" button to the right of the \"Configure how Tor
	   Browser connects to the Internet\" text label.
	5. Enter the following text in the \"No Proxy for\" text area:
		$ 127.0.0.1
	6. Click the \"OK\" button.
	7. Browse to:
		${ZEROHELLO_URL}
"
	fi

	if use meek; then
		DOC_CONTENTS+="
ZeroNet users subject to anonymity-hostile censorship regimes (e.g., the Great
Firewall of China) may circumvent domestic Tor blocks by browsing ZeroNet with
recent versions of Tor Browser. As you have enabled the \"meek\" USE flag,
errors will be displayed on attempting to browse with any other browser.
"
	fi

	# Install the above Gentoo-specific documentation.
	readme.gentoo_create_doc

	# Remove testing-specific submodules from ZeroNet's Python codebase.
	rm -rf src/Test || die '"rm" failed.'

	# Install ZeroNet's Python codebase.
	python_moduleinto "${ZERONET_MODULE_DIR}"
	python_domodule ${PN}.py plugins src tools

	# Create ZeroNet's logging directory. Note that the "acct-user/zeronet"
	# package now manages ZeroNet's state directory, which is thus omitted.
	keepdir "${ZERONET_LOG_DIR}" || die '"keepdir" failed.'

	# Enable ZeroNet to modify all requisite paths. Note that:
	# * This includes the configuration file generated above. Failure to do so
	#   induces the following runtime error on browsing to the local ZeroNet
	#   router console:
	#     Unhandled exception: [Errno 13] Permission denied: '/etc/zeronet.conf'
	# * The following terser command silently fails to change ownership of
	#   files in the "${ZERONET_LOG_DIR}" directory for unknown reasons and
	#   *MUST* thus expanded to explicitly glob all files in that directory:
	#     fowners -R ${PN}:${PN} "${ZERONET_CONF_FILE}" "${ZERONET_LOG_DIR}"
	#   This is critical, as ZeroNet silently fails on startup if unable to
	#   write to even one of these files with an error resembling:
	#     * start-stop-daemon: /usr/bin/zeronet died 
	fowners ${PN}:${PN} \
		"${ZERONET_CONF_FILE}" \
		"${ZERONET_LOG_DIR}" \
		"${ZERONET_LOG_DIR}/"* \
		|| die '"fowners" failed.'

	# Install all Markdown files as documentation.
	dodoc *.md
}

# On first installation, print the above Gentoo-specific documentation.
pkg_postinst() {
	readme.gentoo_print_elog
}

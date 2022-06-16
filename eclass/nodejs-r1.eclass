# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: nodejs-r1.eclass
# @MAINTAINER:
# Cecil Curry <leycec@gmail.com>
# @AUTHOR:
# Cecil Curry <leycec@gmail.com>
# @SUPPORTED_EAPIS: 8
# @BLURB: Eclass for easy installation of Node.js packages.
# @DESCRIPTION:
# This eclass automates the fetching, compilation, and installation of Node.js
# node.js packages and dependencies hosted online with the official node package
# manager (npm) registry at http://registry.npmjs.org.
#
# This eclass automatically defines these global variables on your behalf:
# * "RDEPEND". No "BDEPEND" or "DEPEND" are typically required for Node.js.
# * "S".
# * "SRC_URI".
#
# This eclass is strongly inspired by (in no particular order):
# * Jannis Mast's third-party "node.eclass":
#   https://github.com/Jannis234/jm-overlay/blob/master/eclass/node.eclass
# * Geaaru Geaaru's third-party "npmv1.eclass":
#   https://github.com/TheGreatMcPain/TheGreatMcPain-overlay/blob/master/eclass/npmv1.eclass

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI} unsupported."
esac

EXPORT_FUNCTIONS src_unpack src_install

if [[ ! ${_NODEJS_R1_ECLASS} ]]; then

# @ECLASS-VARIABLE: NODEJS_PN
# @DESCRIPTION:
# Name of this Node.js package hosted by the official npm registry at:
#
#     http://registry.npmjs.org/${NODEJS_PN}
#
# Defaults to ${PN}.
: ${NODEJS_PN:=${PN}}

# @ECLASS-VARIABLE: NODEJS_P
# @DESCRIPTION:
# Name and version of this Node.js package hosted by the official npm registry
# at:
#
#     http://registry.npmjs.org/${NODEJS_PN}
#
# Defaults to "${NODEJS_PN}-${PV}".
: ${NODEJS_P:=${NODEJS_PN}-${PV}}
SRC_URI="http://registry.npmjs.org/${NODEJS_PN}/-/${NODEJS_P}.tgz"

# @ECLASS_VARIABLE: NODEJS_DEPEND_PACKAGES
# @DESCRIPTION:
# Whitespace-delimited string of zero or more
# "${package_name}^${package_version}"-formatted substrings listing the names
# and maximum versions of all upstream Node.js packages required by this
# package (usually manually inspected from the "dependencies" key of the
# "package.json" file bundled with this Node.js package). For example, a Node.js
# package whose "dependencies" key of the "package.json" file requires at most
# version 7.2.0 of the "glob" Node.js package as well as at most version 16.2.0
# of the "yargs" Node.js package should specify:
#
#     NODEJS_DEPEND_PACKAGES='glob^7.2.0 yargs^16.2.0'
#
# Defaults to the empty string, implying this Node.js package requires no
# upstream Node.js packages.

# @ECLASS_VERIABLE: NODEJS_BINSCRIPTS
# @DESCRIPTION:
# Whitespace-delimited string of zero or more
# "${source_filename}:${target_basename}"-formatted substrings listing the
# target basenames and source relative filenames of all runnable Node.js scripts
# bundled with this package at "package/${binscript_filename}" to be installed
# to "/usr/bin/${binscript_basename}". For example, a Node.js package installing
# the source "package/spandex" script to "/usr/bin/run-spandex" as well as the
# source "package/polyester" script to "/usr/bin/run-polyester" should specify:
#
#     NODEJS_BINSCRIPTS='spandex:run-spandex polyester:run-polyester'
#
# Defaults to the empty string, implying this Node.js package installs no
# runnable Node.js scripts.

S="${WORKDIR}/package"

_nodejs-r1_set_globals() {
	local package package_name package_version

	for _package in ${NODEJS_DEPEND_PACKAGES}; do
		_package_name="${_package%^*}"
		_package_version="${_package#*^}"
		SRC_URI+=" http://registry.npmjs.org/${_package_name}/-/${_package_name}-${_package_version}.tgz"
	done
}

unset -f _nodejs-r1_set_globals

# @ECLASS_VARIABLE: NODEJS_MIN_VERSION
# @DESCRIPTION:
# Minimum version of Node.js required by this Node.js package (usually manually
# inspected from the "package.json" file bundled with this Node.js package).
# Defaults to the empty string, implying this package accepts *any* Node.js
# version.

if [[ -z ${NODEJS_MIN_VERSION} ]]; then
	BDEPEND="net-libs/nodejs[npm]"
	RDEPEND="net-libs/nodejs"
else
	BDEPEND=">=net-libs/nodejs-${NODEJS_MIN_VERSION}[npm]"
	RDEPEND=">=net-libs/nodejs-${NODEJS_MIN_VERSION}"
fi

nodejs-r1_src_unpack() {
	local package package_name package_version
	unpack "${NODEJS_P}.tgz"

	if [[ -n ${NODEJS_DEPEND_PACKAGES} ]]; then
		mkdir "${NODEJS_PN}/node_modules" || die

		for package in ${NODEJS_DEPEND_PACKAGES}; do
			package_name="${package%:*}"
			package_version="${package#*:}"

			unpack "${package_name}-${package_version}.tgz"
			mv package "${NODEJS_PN}/node_modules/${package_name}" || die
		done
	fi
}

nodejs-r1_src_install() {
	local nodejs_binscript src_filename trg_basename trg_dirname trg_filename

	trg_dirname="/usr/$(get_libdir)/node_modules/${NODEJS_PN}"
	insinto "${trg_dirname}"
	doins -r .

	for nodejs_binscript in ${NODEJS_BINSCRIPTS}; do
		src_filename="${nodejs_binscript%:*}"
		trg_basename="${nodejs_binscript#*:}"
		trg_filename="${trg_dirname}/${src_filename}"

		dosym "${EROOT}${trg_filename}" "/usr/bin/${trg_basename}"
		fperms +x "${trg_filename}"
	done

	#FIXME: This fails to behave as expected, sadly. "npm" inexplicably replaces
	#the directory installed above with a broken symlink to
	#"../../../../work/package". This is why we can't have good things, people.
	#If we could get this to work, we could eliminate "NODEJS_BINSCRIPTS" above.
	# # Copied almost verbatim from the src_install() phase of Portage's
	# # "dev-lang/typescript" ebuild. Internally, this command:
	# # * Installs one symlink from each runnable Node.js script bundled with this
	# #   Node.js package into /usr/bin.
	# # * Runs the "install" command defined by the "package.json" file bundled
	# #   with this Node.js package (if any). 
	# npm \
	# 	--audit false \
	# 	--color false \
	# 	--foreground-scripts \
	# 	--global \
	# 	--offline \
	# 	--omit dev \
	# 	--omit optional \
	# 	--omit peer \
	# 	--prefix "${ED}"/usr \
	# 	--progress false \
	# 	--verbose \
	# 	install || die

	einstalldocs
}

_NODEJS_R1_ECLASS=1
fi

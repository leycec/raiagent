# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=5

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: Changes to ${PYTHON_COMPAT} must be synchronized with ${IUSE} below.
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# Technically, this package appears to support both Python 2.x and 3.x. However:
# 
# * The Python world is rapidly migrating to Python 3.x.
# * The "python-single-r1" eclass uses Python 2.x by default.
# * There appears to be no means of instructing that eclass to use Python 3.x by
#   default instead.
#
# Hence, we disable Python 2.x support.
PYTHON_COMPAT=( python3_{4,5} pypy3 )

inherit readme.gentoo python-single-r1

DESCRIPTION="Transparent bridge between Git and Dropbox"
HOMEPAGE="https://github.com/anishathalye/git-remote-dropbox"
SRC_URI="${HOMEPAGE}/archive/v${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# Unfortunately, the "python-single-r1" eclass appears to suffer a critical
# issue with respect to Python 3.x use. Unsurprisingly, fully debugging this
# issue is extraordinarily difficult and frankly beyond my meager capacities.
# The core of this issue appears to be caused by the default value for the
# ${PYTHON_SINGLE_TARGET} global. This global is currently only set in the
# "/usr/portage/profiles/base/make.defaults" file by default as follows:
#
#      PYTHON_SINGLE_TARGET="python2_7"
#
# Since this ebuild is marked is incompatible with Python 2.7 (above) *AND*
# since users are encouraged not to explicitly set ${PYTHON_*} globals in
# "/etc/python/make.conf", failing to enable a Python 3.x interpreter as a
# valid ${PYTHON_SINGLE_TARGET} by this kludge induces the following fatal
# error at installation time:
#
#     $ emerge git-remote-dropbox
#     
#     These are the packages that would be merged:
#     
#     Calculating dependencies...
#     
#     !!! Problem resolving dependencies for dev-vcs/git-remote-dropbox                                 ... done!
#     
#     !!! The ebuild selected to satisfy "git-remote-dropbox" has unmet requirements.
#     - dev-vcs/git-remote-dropbox-0.0.3::raiagent USE="" ABI_X86="64" PYTHON_SINGLE_TARGET="-python3_4 -python3_5" PYTHON_TARGETS="python3_4 -python3_5"
#     
#       The following REQUIRED_USE flag constraints are unsatisfied:
#         exactly-one-of ( python_single_target_python3_4 python_single_target_python3_5 )
#     
#       The above constraints are a subset of the following complete expression:
#         exactly-one-of ( python_single_target_python3_4 python_single_target_python3_5 ) python_single_target_python3_4? ( python_targets_python3_4 ) python_single_target_python3_5? ( python_targets_python3_5 )
#
# The solution, of course, is to ensure that the oldest version of Python 3.x
# supported by this ebuild is enabled as a valid ${PYTHON_SINGLE_TARGET}. Yes,
# this is utterly insane and liable to fall apart at the slightest blink. !@#$!
#
# This appears to be a long-standing issue with "python-single-r1". For example,
# see this February, 2014 blog post: https://ewgeny.wordpress.com/tag/python
IUSE="+python_single_target_python3_4"

DEPEND="${PYTHON_DEPS}"
RDEPEND="${DEPEND}
	dev-python/dropbox-sdk[${PYTHON_USEDEP}]
"

src_install() {
	# Sanitize the shebang line prefixing the binary installed below.
	python_fix_shebang ${PN}

	# Install the "git-remote-dropbox" binary and accompanying documentation.
	dobin ${PN}
	dodoc {CONTRIBUTING,DESIGN,README}.md

	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS="
	To finalize \"${PN}\" installation, you must manually:\\n\\n
	1. For each Git repository to be shared via Dropbox, generate a new\\n
	   repository-specific Dropbox app and OAuth2 token. Specifically:\\n
	   \\t1. Login to the Dropbox App console at:\\n
	         \\t\\thttps://www.dropbox.com/developers/apps\\n
	   \\t2. Create a new Dropbox API app with full access to all files\\n
	   \\t   and file types.\\n
	   \\t3. Generate an access token for yourself.\\n
	2. For each user to be granted both read and write access to this\\n
	   repository, create a new user-specific \"~/.git-remote-dropbox.json\"\\n
	   file containing this token. The contents of this file should resemble:\\n\\n
	   \\t{\\n
	   \\t\\t\"token\": \"xxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxx\"\\n
	   \\t}"

	# Install Gentoo-specific documentation.
	readme.gentoo_create_doc
}

# On first installation, print Gentoo-specific documentation.
pkg_postinst() {
	readme.gentoo_print_elog
}

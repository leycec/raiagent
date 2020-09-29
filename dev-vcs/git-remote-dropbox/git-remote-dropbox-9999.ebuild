# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} pypy3 )

inherit readme.gentoo-r1 distutils-r1

DESCRIPTION="Transparent bridge between Git and Dropbox"
HOMEPAGE="
	https://pypi.org/project/git-remote-dropbox
	https://github.com/anishathalye/git-remote-dropbox"

LICENSE="MIT"
SLOT="0"
IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
RDEPEND="${PYTHON_DEPS}
	>=dev-python/dropbox-sdk-9.0.0[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/anishathalye/git-remote-dropbox"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

DOCS=( README.rst )

src_install() {
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

	readme.gentoo_create_doc

	distutils-r1_python_install_all
}

pkg_postinst() {
	readme.gentoo_print_elog
}

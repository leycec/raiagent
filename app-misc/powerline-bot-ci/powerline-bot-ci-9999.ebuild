# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="5"

inherit git-r3

DESCRIPTION="Shell scripts used for building powerline test dependencies"
HOMEPAGE="https://github.com/powerline/bot-ci"
SRC_URI=""

EGIT_REPO_URI="https://github.com/powerline/bot-ci"
EGIT_BRANCH="master"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND=""
DEPEND=""

# Such scripts are principally intended to be used with Travis and hence
# accompanied by only a Travis-specific makefile. To permit their subsequent
# access by "app-misc/powerline", such scripts will be manually installed to the
# expected system-wide directory.
src_install() {
	# Remove unnecessary files.
	rm LICENSE .travis.yml || die '"rm" failed.'
	
	# Install all remaining files.
	insinto /usr/share/${PN}
	doins -r *
}

# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/setuptools/setuptools-9999.ebuild,v 1.1 2013/01/11 09:59:31 mgorny Exp $
EAPI="5"

# Enforce Bash scrictness.
set -e

EGIT_REPO_URI="https://github.com/Lokaltog/powerline"
EGIT_BRANCH="develop"

inherit font git-r3

DESCRIPTION="OpenType Unicode font containing only Powerline-specific symbols."
HOMEPAGE="http://github.com/Lokaltog/powerline"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86 ~x86-fbsd"
IUSE=""

DEPEND=""
RDEPEND=""

FONT_S="${S}/font"
FONT_SUFFIX="otf"
FONT_CONF=( "${FONT_S}/10-powerline-symbols.conf" )

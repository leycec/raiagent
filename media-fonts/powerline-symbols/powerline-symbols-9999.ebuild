# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit font git-r3

DESCRIPTION="OpenType Unicode font containing only Powerline-specific symbols."
HOMEPAGE="https://github.com/powerline/powerline"
EGIT_REPO_URI="https://github.com/powerline/powerline"
EGIT_BRANCH="develop"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86"

FONT_S="${S}/font"
FONT_SUFFIX="otf"
FONT_CONF=( "${FONT_S}/10-powerline-symbols.conf" )

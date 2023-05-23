# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit nodejs-r1

DESCRIPTION="Static type checker for Python"
HOMEPAGE="https://github.com/microsoft/pyright"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

# Note that this metadata derives from the "packages/pyright/package.json" file.
NODEJS_BINSCRIPTS='
	index.js:pyright
	langserver.index.js:pyright-langserver
'
NODEJS_MIN_VERSION='12.0.0'

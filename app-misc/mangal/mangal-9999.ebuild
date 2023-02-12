# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

#FIXME: Add "bash", "fish", and "zsh" USE flags, please. See also the
#install_completions() shell function of the official "mangal" installer, which
#installs completions for these shells:
#    https://raw.githubusercontent.com/metafates/mangal/main/scripts/install
DESCRIPTION="The most advanced (yet simple) CLI manga downloader"
HOMEPAGE="https://github.com/metafates/mangal"

#FIXME: Run "golicense" to decide the set of all licenses required by "mangal".
LICENSE="MIT"
SLOT="0"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/metafates/mangal.git"
	EGIT_BRANCH="main"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="https://github.com/metafates/mangal/archive/refs/tags/v${PV}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

src_compile() {
	ego build -mod=vendor .
	# emake BUILD_FLAGS="-mod=vendor" build
}

src_install() {
	dobin ${PN}
	einstalldocs
}

# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools readme.gentoo-r1 git-r3

DESCRIPTION="Universal Ctags: a maintained ctags implementation"
HOMEPAGE="https://ctags.io/ https://github.com/universal-ctags/ctags"
SRC_URI=""

EGIT_REPO_URI="https://github.com/universal-ctags/ctags"
EGIT_BRANCH="master"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="json seccomp xml yaml"

#FIXME: Insufficient. Universal Ctags has considerably more optional
#dependencies than these -- and probably more than a few mandatory dependencies
#as well. Once supported, submit our changes up to the official Portage ebuild.
COMMON_DEPEND="
	json?    ( dev-libs/jansson )
	seccomp? ( sys-libs/libseccomp )
	xml?     ( dev-libs/libxml2:2 )
	yaml?    ( dev-libs/libyaml )
"
RDEPEND="${COMMON_DEPEND}
	dev-python/docutils
"
RDEPEND="${COMMON_DEPEND}
	app-eselect/eselect-ctags
"

src_prepare() {
	default
	./misc/dist-test-cases > makefiles/test-cases.mak || die
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable json) \
		$(use_enable seccomp) \
		$(use_enable xml) \
		$(use_enable yaml) \
		--disable-readlib \
		--disable-etags \
		--enable-tmpdir="${EPREFIX}"/tmp
	#FIXME: Is this still desirable?
		# --with-posix-regex \
}

src_install() {
	emake prefix="${ED}"/usr mandir="${ED}"/usr/share/man install

	# Due to namespace collision with [X]Emacs-installed ctags, rename "ctags"
	# to "exuberant-ctags". (Mandrake does this as well).
	mv "${D}"/usr/bin/{ctags,exuberant-ctags} || die '"mv" failed.'
	mv "${D}"/usr/share/man/man1/{ctags,exuberant-ctags}.1 || die '"mv" failed.'

	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS="
	Select your preferred ctags provider via the ctags \"eselect\" module. See
	\"man ctags.eselect\" for further details."

	# Install this file.
	readme.gentoo_create_doc
}

pkg_postinst() {
	eselect ctags update

	# On first installations of this package, elog the contents of the
	# previously installed "/usr/share/doc/${P}/README.gentoo" file.
	readme.gentoo_print_elog
}

pkg_postrm() {
	eselect ctags update
}

# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/setuptools/setuptools-9999.ebuild,v 1.1 2013/01/11 09:59:31 mgorny Exp $
EAPI="5"

# Enforce Bash scrictness.
set -e

# This ebuild heavily modified from the official Powerline ebuild at:
# https://raw.github.com/Lokaltog/powerline/develop/packages/gentoo/app-misc/powerline/powerline-9999.ebuild
#
# This ebuild is *ONLY* an interim solution until ZyX, the Powerline maintainer,
# either publishes his own overlay or successfully pushes "powerline" to
# Portage. As such, this ebuild is unlikely to be frequently updated.
#
# Enjoy, folks!

PYTHON_COMPAT=( python{2_6,2_7,3_2,3_3} )

EGIT_REPO_URI="https://github.com/Lokaltog/${PN}"
EGIT_BRANCH="develop"

inherit eutils vim-plugin distutils-r1 git-r3

DESCRIPTION="Ultimate statusline/prompt utility"
HOMEPAGE="http://github.com/Lokaltog/powerline"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86 ~x86-fbsd"
IUSE="awesome doc bash test tmux vim zsh"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

PYTHON_DEPS+="
	virtual/python-argparse"
DEPEND="${PYTHON_DEPS}
	doc? ( dev-python/sphinx dev-python/docutils )
	test? (
		|| ( >=dev-vcs/git-1.7.2 >=dev-python/pygit2-0.17 )
		python_targets_python2_6? (
			dev-vcs/bzr
			dev-vcs/mercurial
			virtual/python-unittest2
		)
		python_targets_python2_7? (
			dev-vcs/bzr
			dev-vcs/mercurial
		)
	)"
RDEPEND="${PYTHON_DEPS}
	|| ( media-fonts/powerline-symbols media-fonts/powerline-fonts )
	awesome? ( >=x11-wm/awesome-3.5.1 )
	bash? ( app-shells/bash )
	vim? ( || (
		>=app-editors/vim-7.3[python]
		>=app-editors/gvim-7.3[python] ) )
	zsh? ( app-shells/zsh )"

# Source directory from which all applicable files will be installed.
POWERLINE_SRC_DIR='powerline/bindings'

# Target directory to which all applicable files will be installed.
POWERLINE_TRG_DIR='/usr/share/powerline'

# Basename of Powerline's help file for vim. 
VIM_PLUGIN_HELPFILES="Powerline"

python_test() {
	PYTHON="${PYTHON}" tests/test.sh
}

src_prepare() {
	sed -ie "/DEFAULT_SYSTEM_CONFIG_DIR/ s@None@'/etc/xdg'@" powerline/__init__.py

	if use vim; then
		# Excise "sys.path.append", which points to the wrong location.
		sed -ie '/sys\.path\.append/d' "${POWERLINE_SRC_DIR}/vim/plugin/powerline.vim"
	fi
}

src_compile() {
	distutils-r1_src_compile
	if use doc; then
		einfo "Generating documentation"
		sphinx-build -b html docs/source docs_output
	fi
}

src_install() {
	if use awesome; then
		insinto /usr/share/awesome/lib/powerline
		newins "${POWERLINE_SRC_DIR}/awesome/powerline.lua" init.lua
		exeinto /usr/share/awesome/lib/powerline
		doexe  "${POWERLINE_SRC_DIR}/awesome/powerline-awesome.py"
	fi

	if use bash; then
		insinto "${POWERLINE_TRG_DIR}/bash"
		doins   "${POWERLINE_SRC_DIR}/bash/powerline.sh"
	fi

	if use tmux; then
		insinto "${POWERLINE_TRG_DIR}/tmux"
		doins   "${POWERLINE_SRC_DIR}/tmux/powerline.conf"
	fi

	if use vim; then
		# Since vim-plugin_src_install() expects ${S} to be the directory
		# to be moved into "/usr/share/vim/vimfiles" and the distutils-based
		# makefile run below expects such directory to not be moved, copy such
		# directory to a temporary location.
		cp -R "${POWERLINE_SRC_DIR}/vim" "${T}"

		# Temporarily set ${S} to such location and install such plugin.
		local S_old="${S}"
		S="${T}/vim"

		# Since vim-plugin_src_install() installs all non-HTML files in such
		# directory as documentation, remove such files.
		rm -f "${S}/__init__.py"

		# Install such plugin.
		vim-plugin_src_install

		# Since vim-plugin_src_install() changes the current directory, restore
		# such directory and ${S} to their prior values.
		S="${S_old}"
		cd "${S}"
	fi

	if use zsh; then
		insinto /usr/share/zsh/site-contrib
		doins "${POWERLINE_SRC_DIR}/zsh/powerline.zsh"
	fi

	insinto /etc/xdg/powerline
	doins -r powerline/config_files/*

	# Prevent distutils-r1_src_install() from installing non-Python files.
	find "${POWERLINE_SRC_DIR}" -type f -not -name '*.py' -delete

	use doc && HTML_DOCS=( docs_output/. )
	distutils-r1_src_install
}

pkg_postinst() {
	# If this package is being installed for the first time rather than
	# upgraded, print post-installation messages.
	if ! has_version ${CATEGORY}/${PN}; then
		if use awesome; then
			elog 'To enable Powerline under awesome, add the following lines to your'
			elog '"~/.config/awesome/rc.lua" (assuming you originally copied such file from'
			elog '"/etc/xdg/awesome/rc.lua"):'
			elog '    require("powerline")'
			elog '    right_layout:add(powerline_widget)'
			elog ''
		fi

		if use bash; then
			elog 'To enable Powerline under bash, add the following line to either your "~/.bashrc"'
			elog 'or "~/.profile"':
			elog "    source ${EROOT}${POWERLINE_TRG_DIR}/bash/powerline.sh"
			elog ''
		fi

		if use tmux; then
			elog 'To enable Powerline under tmux, add the following line to your "~/.tmux.conf":'
			elog "    source ${EROOT}${POWERLINE_TRG_DIR}/tmux/powerline.conf"
			elog ''
		fi

		if use zsh; then
			elog 'To enable Powerline under zsh, add the following line to your "~/.zshrc":'
			elog "    source ${EROOT}/usr/share/zsh/site-contrib/powerline.zsh"
			elog ''
		fi
	fi

	# For readability, print Vim post-installation messages last.
	if use vim; then
		vim-plugin_pkg_postinst
	fi
}

pkg_postrm() {
	if use vim; then
		vim-plugin_pkg_postrm
	fi
}

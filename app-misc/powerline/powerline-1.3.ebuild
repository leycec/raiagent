# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="5"

# Enforce Bash scrictness.
set -e

PYTHON_COMPAT=( python{2_7,3_2,3_3,3_4} pypy{,2_0} )

# Since default phase functions defined by "distutils-r1" take absolute
# precedence over those defined by "readme.gentoo", inherit the latter later.
inherit eutils readme.gentoo distutils-r1

MY_PN="powerline-status"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Python-based statusline/prompt utility"
HOMEPAGE="https://pypi.python.org/pypi/powerline-status"
SRC_URI="mirror://pypi/p/${MY_PN}/${MY_P}.tar.gz"
LICENSE="MIT"

SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86 ~x86-fbsd"
IUSE="awesome busybox bash dash doc fish man mksh test tmux vim zsh fonts"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="
	dev-python/setuptools
	doc? ( dev-python/sphinx )
	man? ( dev-python/sphinx )
	test? (
		app-misc/screen
		|| (
			>=dev-vcs/git-1.7.2
			>=dev-python/pygit2-0.17
		)
	)
"
RDEPEND="
	media-fonts/powerline-symbols
	awesome? ( >=x11-wm/awesome-3.5.1 )
	bash? ( app-shells/bash )
	busybox? ( sys-apps/busybox )
	dash? ( app-shells/dash )
	fish? ( >=app-shells/fish-2.1 )
	fonts? ( media-fonts/powerline-symbols )
	mksh? ( app-shells/mksh )
	vim? ( ~app-vim/powerline-vim-${PV} )
	zsh? ( app-shells/zsh )
"

# Source directory from which all applicable files will be installed.
POWERLINE_SRC_DIR="${T}/bindings"

# Target directory to which all applicable files will be installed.
POWERLINE_TRG_DIR='/usr/share/powerline'
POWERLINE_TRG_DIR_EROOTED="${EROOT}usr/share/powerline/"

S="${WORKDIR}/${MY_P}"

# void powerline_set_config_var_to_value(
#     string variable_name, string variable_value)
#
# Globally replace each string assigned to the passed Python variable in
# Powerline's Python configuration with the passed string.
powerline_set_config_var_to_value() {
	(( ${#} == 2 )) || die 'Expected one variable name and one variable value.'
	sed -i -e 's~^\('${1}' = \).*~\1'"'"${2}"'~" "${S}"/powerline/config.py
}

python_prepare_all() {
	# Replace nonstandard system paths in Powerline's Python configuration.
	powerline_set_config_var_to_value\
		DEFAULT_SYSTEM_CONFIG_DIR "${EROOT}"etc/xdg
	powerline_set_config_var_to_value\
		BINDINGS_DIRECTORY "${POWERLINE_TRG_DIR_EROOTED}"

	# Copy the directory tree containing application-specific Powerline
	# bindings to a temporary directory. Since such tree contains both Python
	# and non-Python files, failing to remove the latter causes distutils to
	# install non-Python files into the Powerline Python module directory. To
	# safely remove such files *AND* permit their installation after the main
	# distutils-based installation, copy them to such location and then remove
	# them from the original tree that distutils operates on.
	cp -R "${S}"/powerline/bindings "${POWERLINE_SRC_DIR}"

	# Remove all non-Python files from the original tree.
	find "${S}"/powerline/bindings -type f -not -name '*.py' -delete

	# Remove all Python files from the copied tree, for safety. Most such files
	# relate to Powerline's distutils-based install process. Exclude the
	# following unrelated Python files:
	#
	# * "powerline-awesome.py", an awesome-specific integration script.
	find "${POWERLINE_SRC_DIR}"\
		-type f\
		-name '*.py'\
		-not -name 'powerline-awesome.py'\
		-delete

	# Continue with the default behaviour.
	distutils-r1_python_prepare_all
}

python_compile_all() {
	# Build documentation, if both available *AND* requested by the user. 
	if use doc && [ -d "${S}"/docs ]; then
		einfo "Generating documentation"
		sphinx-build -b html "${S}"/docs/source docs_output
		HTML_DOCS=( docs_output/. )
	fi

	# Build man pages.
	if use man; then
		einfo "Generating man pages"
		sphinx-build -b man "${S}"/docs/source man_pages
	fi
}

python_test() {
	PYTHON="${PYTHON}" "${S}"/tests/test.sh
}

python_install_all() {
	# Install man pages.
	if use man; then
		doman man_pages/*.1
	fi

	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS=""

	# Install application-specific libraries and documentation.
	if use awesome; then
		local AWESOME_LIB_DIR='/usr/share/awesome/lib/powerline'
		insinto "${AWESOME_LIB_DIR}"
		newins "${POWERLINE_SRC_DIR}"/awesome/powerline.lua init.lua
		exeinto "${AWESOME_LIB_DIR}"
		doexe  "${POWERLINE_SRC_DIR}"/awesome/powerline-awesome.py

		DOC_CONTENTS+="
	To enable Powerline under awesome, add the following lines to \"~/.config/awesome/rc.lua\" (assuming you originally copied such file from \"/etc/xdg/awesome/rc.lua\"):\\n
	\\trequire(\"powerline\")\\n
	\\tright_layout:add(powerline_widget)\\n\\n"
	fi

	if use bash; then
		insinto "${POWERLINE_TRG_DIR}"/bash
		doins   "${POWERLINE_SRC_DIR}"/bash/powerline.sh

		DOC_CONTENTS+="
	To enable Powerline under bash, add the following line to either \"~/.bashrc\" or \"~/.profile\":\\n
	\\tsource ${POWERLINE_TRG_DIR_EROOTED}bash/powerline.sh\\n\\n"
	fi

	if use busybox; then
		insinto "${POWERLINE_TRG_DIR}"/busybox
		doins   "${POWERLINE_SRC_DIR}"/shell/powerline.sh

		DOC_CONTENTS+="
	To enable Powerline under interactive sessions of BusyBox's ash shell, interactively run the following command:\\n
	\\t. ${POWERLINE_TRG_DIR_EROOTED}busybox/powerline.sh\\n\\n"
	fi

	if use dash; then
		insinto "${POWERLINE_TRG_DIR}"/dash
		doins   "${POWERLINE_SRC_DIR}"/shell/powerline.sh

		DOC_CONTENTS+="
	To enable Powerline under dash, add the following line to the file referenced by environment variable \${ENV}:\\n
	\\t. ${POWERLINE_TRG_DIR_EROOTED}dash/powerline.sh\\n
	If such variable does not exist, you may need to manually create such file.\\n\\n"
	fi

	if use fish; then
		insinto /usr/share/fish/functions
		doins "${POWERLINE_SRC_DIR}"/fish/powerline-setup.fish

		DOC_CONTENTS+="
	To enable Powerline under fish, add the following line to \"~/.config/fish/config.fish\":\\n
	\\tpowerline-setup\\n\\n"
	fi

	if use mksh; then
		insinto "${POWERLINE_TRG_DIR}"/mksh
		doins   "${POWERLINE_SRC_DIR}"/shell/powerline.sh

		DOC_CONTENTS+="
	To enable Powerline under mksh, add the following line to \"~/.mkshrc\":\\n
	\\t. ${POWERLINE_TRG_DIR_EROOTED}mksh/powerline.sh\\n\\n"
	fi

	if use tmux; then
		insinto "${POWERLINE_TRG_DIR}"/tmux
		doins   "${POWERLINE_SRC_DIR}"/tmux/powerline*.conf

		DOC_CONTENTS+="
	To enable Powerline under tmux, add the following line to \"~/.tmux.conf\":\\n
	\\tsource ${POWERLINE_TRG_DIR_EROOTED}tmux/powerline.conf\\n\\n"
	fi

	if use zsh; then
		insinto /usr/share/zsh/site-contrib
		doins "${POWERLINE_SRC_DIR}"/zsh/powerline.zsh

		DOC_CONTENTS+="
	To enable Powerline under zsh, add the following line to \"~/.zshrc\":\\n
	\\tsource ${EROOT}usr/share/zsh/site-contrib/powerline.zsh\\n\\n"
	fi

	# Install Powerline configuration files.
	insinto /etc/xdg/powerline
	doins -r "${S}"/powerline/config_files/*

	# Install Gentoo-specific documentation.
	readme.gentoo_create_doc

	# Install Powerline python modules.
	distutils-r1_python_install_all
}

pkg_postinst() {
	# On first installation, print Gentoo-specific documentation.
	readme.gentoo_print_elog
}

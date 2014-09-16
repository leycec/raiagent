# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="5"

# Enforce Bash scrictness.
set -e

PYTHON_COMPAT=( python{2_7,3_2,3_3,3_4} pypy{,2_0} )

EGIT_REPO_URI="https://github.com/Lokaltog/powerline"
EGIT_BRANCH="develop"

inherit eutils distutils-r1 git-r3

DESCRIPTION="Ultimate statusline/prompt utility"
HOMEPAGE="http://github.com/Lokaltog/powerline"
LICENSE="MIT"

SLOT="0"
KEYWORDS=""
IUSE="awesome busybox doc bash dash fish mksh test tmux vim zsh fonts"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="
	dev-python/setuptools
	doc? (
		dev-python/docutils
		dev-python/sphinx
	)
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
	vim? ( app-vim/powerline-python )
	zsh? ( app-shells/zsh )
"

# Source directory from which all applicable files will be installed.
POWERLINE_SRC_DIR="${T}/bindings"

# Target directory to which all applicable files will be installed.
POWERLINE_TRG_DIR='/usr/share/powerline'

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
		DEFAULT_SYSTEM_CONFIG_DIR "${EROOT}etc/xdg"
	powerline_set_config_var_to_value\
		BINDINGS_DIRECTORY "${EROOT}${POWERLINE_TRG_DIR}"

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
	if use doc; then
		einfo "Generating documentation"
		sphinx-build -b html "${S}"/docs/source docs_output
		HTML_DOCS=( docs_output/. )
	fi
}

python_test() {
	PYTHON="${PYTHON}" "${S}"/tests/test.sh
}

python_install_all() {
	if use awesome; then
		local AWESOME_LIB_DIR='/usr/share/awesome/lib/powerline'
		insinto "${AWESOME_LIB_DIR}"
		newins "${POWERLINE_SRC_DIR}/awesome/powerline.lua" init.lua
		exeinto "${AWESOME_LIB_DIR}"
		doexe  "${POWERLINE_SRC_DIR}/awesome/powerline-awesome.py"
	fi

	if use bash; then
		insinto "${POWERLINE_TRG_DIR}/bash"
		doins   "${POWERLINE_SRC_DIR}/bash/powerline.sh"
	fi

	if use busybox; then
		insinto "${POWERLINE_TRG_DIR}/busybox"
		doins   "${POWERLINE_SRC_DIR}/shell/powerline.sh"
	fi

	if use dash; then
		insinto "${POWERLINE_TRG_DIR}/dash"
		doins   "${POWERLINE_SRC_DIR}/shell/powerline.sh"
	fi

	if use fish; then
		insinto /usr/share/fish/functions
		doins "${POWERLINE_SRC_DIR}/fish/powerline-setup.fish"
	fi

	if use mksh; then
		insinto "${POWERLINE_TRG_DIR}/mksh"
		doins   "${POWERLINE_SRC_DIR}/shell/powerline.sh"
	fi

	if use tmux; then
		insinto "${POWERLINE_TRG_DIR}/tmux"
		doins   "${POWERLINE_SRC_DIR}/tmux/"powerline*.conf
	fi

	if use zsh; then
		insinto /usr/share/zsh/site-contrib
		doins "${POWERLINE_SRC_DIR}/zsh/powerline.zsh"
	fi

	# Install Powerline configuration files.
	insinto /etc/xdg/powerline
	doins -r "${S}"/powerline/config_files/*

	# Install Powerline python modules.
	distutils-r1_python_install_all
}

pkg_postinst() {
	if use awesome; then
		elog 'To enable Powerline under awesome, add the following lines to'
		elog '"~/.config/awesome/rc.lua" (assuming you originally copied such file from'
		elog '"/etc/xdg/awesome/rc.lua"):'
		elog '    require("powerline")'
		elog '    right_layout:add(powerline_widget)'
		elog ''
	fi

	if use bash; then
		elog 'To enable Powerline under bash, add the following line to either "~/.bashrc" or'
		elog '"~/.profile":'
		elog "    source ${EROOT}${POWERLINE_TRG_DIR}/bash/powerline.sh"
		elog ''
	fi

	if use busybox; then
		elog "To enable Powerline under an interactive session of BusyBox's ash shell,"
		elog "interactively run the following command:"
		elog "    . ${EROOT}${POWERLINE_TRG_DIR}/busybox/powerline.sh"
		elog ''
	fi

	if use dash; then
		elog 'To enable Powerline under dash, add the following line tothe file'
		elog 'referenced by the ${ENV} environment variable (which you may need to'
		elog 'manually create, if such variable does not yet exist):'
		elog "    . ${EROOT}${POWERLINE_TRG_DIR}/dash/powerline.sh"
		elog ''
	fi

	if use fish; then
		elog 'To enable Powerline under fish, add the following line to'
		elog '"~/.config/fish/config.fish":'
		elog '    powerline-setup'
		elog ''
	fi

	if use mksh; then
		elog 'To enable Powerline under mksh, add the following line to "~/.mkshrc":'
		elog "    . ${EROOT}${POWERLINE_TRG_DIR}/mksh/powerline.sh"
		elog ''
	fi

	if use tmux; then
		elog 'To enable Powerline under tmux, add the following line to "~/.tmux.conf":'
		elog "    source ${EROOT}${POWERLINE_TRG_DIR}/tmux/powerline.conf"
		elog ''
	fi

	if use zsh; then
		elog 'To enable Powerline under zsh, add the following line to "~/.zshrc":'
		elog "    source ${EROOT}/usr/share/zsh/site-contrib/powerline.zsh"
		elog ''
	fi
}

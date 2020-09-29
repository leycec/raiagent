# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python2_7 python3_{6..9} pypy{,3} )

# Since default phase functions defined by "distutils-r1" take precedence over
# those defined by "readme.gentoo-r1", inherit the latter later.
inherit eutils readme.gentoo-r1 distutils-r1

DESCRIPTION="Python-based statusline/prompt utility"
HOMEPAGE="https://pypi.python.org/pypi/powerline-status"

LICENSE="MIT"
SLOT="0"
IUSE="
	awesome busybox bash dash doc extra fish fonts i3bar lemonbar man mksh rc
	qtile tmux vim zsh
"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

# Some optional dependencies are only available for a limited subset of
# architectures supported by this ebuild. For example, "app-shells/rc" is only
# available for amd64 and x86 architectures. These dependencies are explicitly
# masked in this overlay's "profiles/arch/${ARCH}/package.use.mask" files.
BDEPEND="dev-python/setuptools[${PYTHON_USEDEP}]"
DEPEND="${PYTHON_DEPS}
	doc? ( dev-python/sphinx[${PYTHON_USEDEP}] )
	man? ( dev-python/sphinx[${PYTHON_USEDEP}] )
"
RDEPEND="${PYTHON_DEPS}
	media-fonts/powerline-symbols
	awesome? ( >=x11-wm/awesome-3.5.1 )
	bash? ( app-shells/bash )
	busybox? ( sys-apps/busybox )
	dash? ( app-shells/dash )
	extra? (
		dev-python/netifaces[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
	)
	fish? ( >=app-shells/fish-2.1 )
	fonts? ( media-fonts/powerline-fonts )
	i3bar? ( || ( x11-wm/i3 x11-wm/i3-gaps ) )
	lemonbar? ( x11-misc/lemonbar )
	mksh? ( app-shells/mksh )
	qtile? ( >=x11-wm/qtile-0.6 )
	rc? ( app-shells/rc )
	vim? ( ~app-vim/powerline-vim-${PV}[${PYTHON_USEDEP}] )
	zsh? ( app-shells/zsh )
"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/powerline/powerline"
	EGIT_BRANCH="develop"
	SRC_URI=""
	KEYWORDS=""

	# Only the live repository currently provides tests, complicating our life.
	IUSE+=" test"
	DEPEND+="
	test? (
		dev-python/pexpect[${PYTHON_USEDEP}]
		dev-python/psutil[${PYTHON_USEDEP}]
		|| (
			dev-libs/libvterm
			dev-libs/libvterm-neovim
		)
	)"
else
	MY_PN="powerline-status"
	MY_P="${MY_PN}-${PV}"
	SRC_URI="mirror://pypi/p/${MY_PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"
fi

# Source directory containing application-specific Powerline bindings, from
# which all non-Python files will be removed. See python_prepare_all().
POWERLINE_SRC_BINDINGS_PYTHON_DIR="${S}"/powerline/bindings

# Temporary directory housing application-specific Powerline bindings, from
# which most Python files except those explicitly matching a well-defined
# whitelist will be removed. See python_prepare_all().
POWERLINE_TMP_BINDINGS_NONPYTHON_DIR="${T}"/bindings

# Temporary directory housing application-specific Powerline bindings, from
# which all *NO* files will be removed. See python_prepare_all().
POWERLINE_TMP_BINDINGS_DIR="${T}"/bindings-full

# Target directory for system-wide assets.
POWERLINE_HOME=/usr/share/powerline
POWERLINE_HOME_EROOTED="${EROOT}${POWERLINE_HOME}"

# Target directory for system-wide configuration.
POWERLINE_CONF_HOME=/etc/xdg
POWERLINE_CONF_HOME_EROOTED="${EROOT}${POWERLINE_CONF_HOME}"

# Powerline's Travis-specific continuous integration repository.
TEST_EGIT_REPO_URI="https://github.com/powerline/bot-ci"
TEST_EGIT_BRANCH="master"

if [[ ${PV} == 9999 ]]; then
	src_fetch() {
		git-r3_src_fetch

		# If testing, fetch Powerline's Travis-specific continuous integration
		# repository. Powerline requires these files from this repository when
		# testing:
		# * "scripts/common/main.sh".
		if use test; then
			EGIT_REPO_URI="${TEST_EGIT_REPO_URI}" \
			EGIT_BRANCH="${TEST_EGIT_BRANCH}" \
				git-r3_src_fetch
		fi
	}

	src_unpack() {
		git-r3_src_unpack

		# If testing, clone the previously fetched repository directly into
		# Powerline's test tree.
		if use test; then
			EGIT_REPO_URI="${TEST_EGIT_REPO_URI}" \
			EGIT_BRANCH="${TEST_EGIT_BRANCH}" \
			EGIT_CHECKOUT_DIR="${S}/tests/bot-ci" \
				git-r3_src_unpack
		fi
	}

	python_test() {
		# Temporarily replace the source bindings directory currently
		# containing only Python files with the temporary bindings directory
		# containing all original files. (Tests require unmodified bindings.)
		mv "${POWERLINE_SRC_BINDINGS_PYTHON_DIR}"{,.bak} || die
		cp -R \
			"${POWERLINE_TMP_BINDINGS_DIR}" \
			"${POWERLINE_SRC_BINDINGS_PYTHON_DIR}" || die

		#FIXME: This is pretty terrible, and will definitely prevent Powerline
		#from being added to Portage. Can the tests be improved so as not to
		#break ebuild sandboxing? If not, would it be possible to disable those
		#tests breaking ebuild sandboxing? Even that would probably be
		#preferable to the current approach. Sandboxing is crucial. It should
		#not be circumvented for *ANY* reason -- even reasons as ostensibly
		#valid as this.

		# Circumvent Portage's ${LD_PRELOAD}-based ebuild sandbox for the
		# duration of Powerline shell tests, which currently break sandboxing.
		env -i\
			USER="${USER}"\
			HOME="${HOME}"\
			LANG=en_US.UTF-8\
			PATH="${PATH}"\
			PYTHON="${PYTHON}"\
			"${S}"/tests/test.sh || die 'Tests failed.'

		# Revert the source bindings directory to only contain Python files.
		rm -r "${POWERLINE_SRC_BINDINGS_PYTHON_DIR}" || die
		mv "${POWERLINE_SRC_BINDINGS_PYTHON_DIR}"{.bak,} || die
	}
fi

# void powerline_set_config_var_to_value(
#     string variable_name, string variable_value)
#
# Globally replace each string assigned to the passed Python variable in
# Powerline's Python configuration with the passed string.
powerline_set_config_var_to_value() {
	(( ${#} == 2 )) || die 'Expected one variable name and one variable value.'
	sed -i -e 's~^\('${1}' = \).*~\1'"'"${2}"'~" "${S}"/powerline/config.py ||
		die
}

python_prepare_all() {
	# Replace nonstandard system paths in Powerline's Python configuration.
	powerline_set_config_var_to_value \
		DEFAULT_SYSTEM_CONFIG_DIR "${POWERLINE_CONF_HOME_EROOTED}"
	powerline_set_config_var_to_value \
		BINDINGS_DIRECTORY "${POWERLINE_HOME_EROOTED}"

	# Copy application-specific Powerline bindings to a temporary directory.
	# Since these bindings provide both Python and non-Python files, failing to
	# remove the latter causes distutils to install non-Python files into
	# Powerline's Python module directory. To safely remove these files *AND*
	# permit their installation after the main distutils-based installation, we
	# copy them to a temporary directory and remove them from the original
	# directory that distutils operates upon.
	cp -R \
		"${POWERLINE_SRC_BINDINGS_PYTHON_DIR}" \
		"${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}" || die

	# If testing...
	if [[ ${PV} == 9999 ]] && use test; then
		# Additionally copy these bindings to a second temporary directory.
		# Since tests require all bindings *AND* since subsequent logic removes
		# files from the first such directory, no such files will be removed
		# from the second such directory. Ugh.
		cp -R \
			"${POWERLINE_SRC_BINDINGS_PYTHON_DIR}" \
			"${POWERLINE_TMP_BINDINGS_DIR}" || die
	fi

	# Remove all non-Python files from the original tree.
	find "${POWERLINE_SRC_BINDINGS_PYTHON_DIR}" \
		-type f \
		-not -name '*.py' \
		-delete

	# Remove all Python files from the copied tree, for safety. Most such files
	# relate to Powerline's distutils-based install process. Exclude the
	# unrelated Python files whose basename matches the glob "powerline-*.py",
	# including:
	#
	# * "powerline-awesome.py", an awesome-specific integration script.
	# * "powerline-i3.py", an i3bar-specific integration script.
	# * "powerline-lemonbar.py", a lemonbar-specific integration script.
	find "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}" \
		-type f \
		-name '*.py' \
		-not -name 'powerline-*.py' \
		-delete

	# Continue with the default behaviour.
	distutils-r1_python_prepare_all
}

python_compile_all() {
	# Build documentation, if both available *AND* requested by the user. 
	if use doc && [[ -d "${S}"/docs ]]; then
		einfo 'Generating documentation'
		sphinx-build -b html "${S}"/docs/source docs_output ||
			die 'HTML documentation compilation failed.'
		HTML_DOCS=( docs_output/. )
	fi

	# Build man pages.
	if use man; then
		einfo 'Generating man pages'
		sphinx-build -b man "${S}"/docs/source man_pages ||
			die 'Manpage compilation failed.'
	fi
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
		newins "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/awesome/powerline.lua init.lua
		exeinto "${AWESOME_LIB_DIR}"
		doexe "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/awesome/powerline-awesome.py

		DOC_CONTENTS+="
	To enable Powerline under awesome, add the following lines to \"~/.config/awesome/rc.lua\" (assuming you originally copied that file from \"${POWERLINE_CONF_HOME_EROOTED}/awesome/rc.lua\"):\\n
	\\trequire(\"powerline\")\\n
	\\tright_layout:add(powerline_widget)\\n\\n"
	fi

	if use bash; then
		insinto "${POWERLINE_HOME}"/bash
		doins   "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/bash/powerline.sh

		DOC_CONTENTS+="
	To enable Powerline under bash, add the following line to either \"~/.bashrc\" or \"~/.profile\":\\n
	\\tsource ${POWERLINE_HOME_EROOTED}/bash/powerline.sh\\n\\n"
	fi

	if use busybox; then
		insinto "${POWERLINE_HOME}"/busybox
		doins   "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/shell/powerline.sh

		DOC_CONTENTS+="
	To enable Powerline under interactive sessions of BusyBox's ash shell, interactively run this command:\\n
	\\t. ${POWERLINE_HOME_EROOTED}/busybox/powerline.sh\\n\\n"
	fi

	if use dash; then
		insinto "${POWERLINE_HOME}"/dash
		doins   "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/shell/powerline.sh

		DOC_CONTENTS+="
	To enable Powerline under dash, add the following line to the file referenced by environment variable \${ENV}:\\n
	\\t. ${POWERLINE_HOME_EROOTED}/dash/powerline.sh\\n
	If that variable does not exist, you may need to manually create that file.\\n\\n"
	fi

	if use fish; then
		insinto /usr/share/fish/functions
		doins "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/fish/powerline-setup.fish

		DOC_CONTENTS+="
	To enable Powerline under fish, add the following line to \"~/.config/fish/config.fish\":\\n
	\\tpowerline-setup\\n\\n"
	fi

	if use i3bar; then
		insinto "${POWERLINE_HOME}"/i3
		doins   "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/i3/powerline-i3.py

		DOC_CONTENTS+="
	To enable Powerline under i3bar, add the following to \"~/.config/i3/config\" after replacing the placeholder substrings \"\${POWERLINE_FONT_NAME}\" and \"\${POWERLINE_FONT_SIZE}\" with the pango-compatible name and size in pt (points) of a Powerline-patched font installed by the \"media-fonts/powerline-fonts\" package (e.g., \"font pango:Source Code Pro for Powerline 11\" after running \"USE='sourcecodepro' emerge powerline-fonts\"):\\n
	\\tbar {\\n
	\\t\\tstatus_command python ${POWERLINE_HOME_EROOTED}/i3/powerline-i3.py\\n
	\\t\\tfont pango:\${POWERLINE_FONT_NAME} \${POWERLINE_FONT_SIZE}\\n
	\\t}\\n\\n"
	fi

	if use lemonbar; then
		insinto "${POWERLINE_HOME}"/lemonbar
		doins   "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/lemonbar/powerline-lemonbar.py

		DOC_CONTENTS+="
	To enable Powerline under lemonbar, run lemonbar with the following command after replacing the placeholder substring \"\${LEMONBAR_HEIGHT}\" with the desired height in pixels for this lemonbar *AND* replacing the placeholder substrings \"\${POWERLINE_FONT_NAME}\" and \"\${POWERLINE_FONT_SIZE}\" with the pango-compatible name and size in pt (points) of a Powerline-patched font installed by the \"media-fonts/powerline-fonts\" package (e.g., \"Source Code Pro for Powerline-11\" after running \"USE='sourcecodepro' emerge powerline-fonts\"):\\n
	\\tpython ${POWERLINE_HOME_EROOTED}/lemonbar/powerline-lemonbar.py -height \${LEMONBAR_HEIGHT} -- -f \"\${POWERLINE_FONT_NAME}-\${POWERLINE_FONT_SIZE}\"\\n
	To enable Powerline under lemonbar under i3, add the following to \"~/.config/i3/config\":\\n
	\\texec python ${POWERLINE_HOME_EROOTED}/lemonbar/powerline-lemonbar.py -i3 -height \${LEMONBAR_HEIGHT} -- -f \"\${POWERLINE_FONT_NAME}-\${POWERLINE_FONT_SIZE}\"\\n\\n"
	fi

	if use mksh; then
		insinto "${POWERLINE_HOME}"/mksh
		doins   "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/shell/powerline.sh

		DOC_CONTENTS+="
	To enable Powerline under mksh, add the following line to \"~/.mkshrc\":\\n
	\\t. ${POWERLINE_HOME_EROOTED}/mksh/powerline.sh\\n\\n"
	fi

	if use qtile; then
		DOC_CONTENTS+="
	To enable powerline under qtile, add the following to \"~/.config/qtile/config.py\":\\n
	\\tfrom libqtile.bar import Bar\\n
	\\tfrom libqtile.config import Screen\\n
	\\tfrom libqtile.widget import Spacer\\n
	\\t\\n
	\\tfrom powerline.bindings.qtile.widget import PowerlineTextBox\\n
	\\t\\n
	\\tscreens = [\\n
	\\t   Screen(\\n
	\\t       top=Bar([\\n
	\\t               PowerlineTextBox(timeout=2, side='left'),\\n
	\\t               Spacer(),\\n
	\\t               PowerlineTextBox(timeout=2, side='right'),\\n
	\\t           ],\\n
	\\t           35\\n
	\\t       ),\\n
	\\t   ),\\n
	\\t]\\n\\n"
	fi

	if use rc; then
		insinto "${POWERLINE_HOME}"/rc
		doins   "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/rc/powerline.rc

		DOC_CONTENTS+="
	To enable Powerline under rc shell, add the following line to \"~/.rcrc\":\\n
	\\t. ${POWERLINE_HOME_EROOTED}/rc/powerline.rc\\n\\n"
	fi

	if use tmux; then
		insinto "${POWERLINE_HOME}"/tmux
		doins   "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/tmux/powerline*.conf

		DOC_CONTENTS+="
	To enable Powerline under tmux, add the following line to \"~/.tmux.conf\":\\n
	\\tsource ${POWERLINE_HOME_EROOTED}/tmux/powerline.conf\\n\\n"
	fi

	if use zsh; then
		insinto /usr/share/zsh/site-contrib
		doins "${POWERLINE_TMP_BINDINGS_NONPYTHON_DIR}"/zsh/powerline.zsh

		DOC_CONTENTS+="
	To enable Powerline under zsh, add the following line to \"~/.zshrc\":\\n
	\\tsource ${EROOT}usr/share/zsh/site-contrib/powerline.zsh\\n\\n"
	fi

	# Install Powerline configuration files.
	insinto "${POWERLINE_CONF_HOME}"/powerline
	doins -r "${S}"/powerline/config_files/*

	# If no USE flags were enabled, ${DOC_CONTENTS} will be empty, in which
	# case calling readme.gentoo_create_doc() throws the following fatal error:
	#
	#     "You are not specifying README.gentoo contents!"
	#
	# Avoid this by defaulting ${DOC_CONTENTS} to a non-empty string if empty.
	DOC_CONTENTS=${DOC_CONTENTS:-All Powerline USE flags were disabled.}

	# Install Gentoo-specific documentation.
	readme.gentoo_create_doc

	# Install the "powerline' Python package.
	distutils-r1_python_install_all
}

# On first installation, print the above Gentoo-specific documentation.
pkg_postinst() {
	readme.gentoo_print_elog
}

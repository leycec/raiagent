# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

# Since eclasses cannot be conditionally inherited, this ebuild remains
# distinct from "app-misc/powerline", the core Powerline ebuild.
PYTHON_COMPAT=( python3_{8..9} pypy3 )

# inherit python-any-r1 vim-plugin
inherit python-r1 vim-plugin

DESCRIPTION="Vim plugin for Python-based Powerline"
HOMEPAGE="https://pypi.python.org/pypi/powerline-status"

LICENSE="MIT"
SLOT="0"

#FIXME: Ideally, we would also enforce ${PYTHON_USEDEP} on "vim" and "gvim"
#(e.g., as ">=app-editors/vim-7.2[python,${PYTHON_USEDEP}]". Sadly, doing so
#coercively disables the user's desired ${PYTHON_SINGLE_TARGET}: e.g.,
#    The following USE changes are necessary to proceed:
#     (see "package.use" in the portage(5) man page for more details)
#    # required by app-vim/powerline-vim-9999-r1::raiagent
#    # required by powerline-vim (argument)
#    >=app-editors/vim-8.1.1486 -python_single_target_python3_6
#FIXME: Is the above still true? Something seems a bit off here.
#FIXME: Shouldn't this ebuild depend on "distutils-r1" instead?
DEPEND="${PYTHON_DEPS}
	|| (
		>=app-editors/vim-7.2[python]
		>=app-editors/gvim-7.2[python]
	)
"
RDEPEND="${DEPEND}
	~app-misc/powerline-${PV}[${PYTHON_USEDEP}]
"

# Basename of this plugin's help file.
VIM_PLUGIN_HELPFILES="Powerline"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/powerline/powerline"
	EGIT_BRANCH="develop"
	KEYWORDS=""
else
	MY_PN="powerline-status"
	MY_P="${MY_PN}-${PV}"
	SRC_URI="mirror://pypi/p/${MY_PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"
fi

src_prepare() {
	default

	# As we are installing Powerline only for Python 3.x, notify this Vim
	# plugin. Failing to do so raises an absurd error at runtime resembling:
	#
	#     $ vim
	#     Traceback (most recent call last):
	#       File "<string>", line 8, in <module>
	#     ImportError: No module named powerline.vim
	#     An error occurred while importing powerline module.
	#     This could be caused by invalid sys.path setting,
	#     or by an incompatible Python version (powerline requires
	#     Python 2.6, 2.7 or 3.2 and later to work). Please consult
	#     the troubleshooting section in the documentation for
	#     possible solutions.
	#     If powerline on your system is installed for python 3 only you
	#     should set g:powerline_pycmd to "py3" to make it load correctly.
	#     Unable to import powerline, is it installed?
	#     Press ENTER or type command to continue
	sed -i -e \
		"/if exists('g:powerline_pycmd')/i \\let g:powerline_pycmd = 'py3'" \
		"${S}"/powerline/bindings/vim/plugin/powerline.vim || die

	# vim-plugin_src_install() expects ${S} to be the top-level directory for
	# the Vim plugin installed at "/usr/share/vim/vimfiles". To guarantee this,
	# that directory is moved to "${T}/vim", everything else under ${S} is
	# moved to "${T}/ignore", and that directory is moved back into ${S}.
	mkdir "${T}"/ignore || die
	mv    "${S}"/powerline/bindings/vim "${T}" || die
	mv *  "${T}"/ignore || die
	mv    "${T}"/vim/* "${S}" || die

	# Remove all remaining Java and Python files to prevent
	# vim-plugin_src_install() from installing such files as documentation.
	# Which, if you think about it, is a pretty terrible default behaviour.
	find . -type f '(' -name '*.class' -o -name '*.py' ')' -delete || die

	# Remove nonstandard paths from this plugin's implementation.
	sed -i -e '/sys\.path\.append/d' "${S}"/plugin/powerline.vim || die
}

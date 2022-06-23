# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..10} )

inherit distutils-r1

DESCRIPTION="Open source UI framework written in Python"
HOMEPAGE="https://kivy.org"

LICENSE="MIT"
SLOT="0"
IUSE="
	X +buildozer +cython doc examples gles2 highlight +imaging opengl pango
	pygame pytest gstreamer rst +sdl spell vim-syntax wayland
"
REQUIRED_USE="
	gles2? ( opengl )
	pygame? ( sdl )
"

# All Kivy dependencies (except those enabling "USE_*" environment variables
# exported by the python_compile() phase) are runtime-only. Note that pygame
# and SDL2 are mutually incompatible, as the former assumes SDL1.
BEPEND="
	virtual/pkgconfig
	cython? ( >=dev-python/cython-0.24.0[${PYTHON_USEDEP}] )
"
DEPEND="
	X? (
		x11-libs/libX11
		x11-libs/libXrender
	)
	gstreamer? ( dev-python/gst-python:1.0[${PYTHON_USEDEP}] )
	opengl? ( media-libs/mesa[X?,gles2?,wayland?] )
	pango? ( x11-libs/pango[X?] )
	wayland? ( dev-libs/wayland )
"
RDEPEND="${DEPEND}
	buildozer? ( dev-python/buildozer[${PYTHON_USEDEP}] )
	highlight? ( dev-python/pygments[${PYTHON_USEDEP}] )
	imaging? ( dev-python/pillow[${PYTHON_USEDEP}] )
	pytest? (
		dev-python/pytest[${PYTHON_USEDEP}]
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
	)
	rst? ( dev-python/docutils[${PYTHON_USEDEP}] )
	sdl? (
		pygame? ( dev-python/pygame[X?,opengl?,${PYTHON_USEDEP}] )
		!pygame? (
			media-libs/libsdl2[X?,wayland?]
			media-libs/sdl2-image
			media-libs/sdl2-mixer
			media-libs/sdl2-ttf
		)
	)
	spell? ( dev-python/pyenchant[${PYTHON_USEDEP}] )
"

DISTUTILS_IN_SOURCE_BUILD=

#FIXME: Upstream fails to bundle the "tests/" directory with source tarballs.
# distutils_enable_tests pytest
distutils_enable_sphinx docs

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/kivy/kivy.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	# Strip all underscores from this package's version (e.g., reduce
	# "2.3.0_rc3" to "2.3.0rc3").
	MY_PV=${PV//_}
	MY_P=${PN}-${MY_PV}

	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86"

	S="${WORKDIR}/${MY_P}"
fi

python_prepare_all() {
	# If disabling Cython support, patch away a relevant boolean in "setup.py".
	# See also this open issue: https://github.com/kivy/kivy/issues/7823
	if ! use cython; then
		sed -i -e 's~\(can_use_cython = \)True~\1False~' setup.py || die
	fi

	# If enabling Vim integration, strip all Windows-specific carriage return
	# characters from files subsequently installed by this USE flag.
	if use vim-syntax; then
		sed -i -e 's~'$'\r''~~g' kivy/tools/highlight/kivy.vim || die
	fi

	distutils-r1_python_prepare_all
}

python_compile() {
	#FIXME: Add the following back below *AFTER* upstream resolves this issue:
	#    https://github.com/kivy/kivy/issues/7824
	# USE_MESAGL=$(usex opengl 1 0) \

	# Export environment variables expected by this package's "setup.py"
	# (listed in the same order for maintainability). However, note that:
	# * These variables are almost entirely undocumented. It is what it is.
	# * These variables are listed undercase in "setup.py" but *MUST*
	#   nonetheless be declared as uppercase here. It is what it is.
	# * The values of these variables *MUST* be either:
	#   * "1" to signify a "True" boolean value.
	#   * "0" to signify a "False" boolean value.
	USE_EGL=$(usex opengl 1 0) \
	USE_OPENGL_ES2=$(usex gles2 1 0) \
	USE_SDL2=$(usex sdl 1 0) \
	USE_PANGOFT2=$(usex pango 1 0) \
	USE_X11=$(usex X 1 0) \
	USE_WAYLAND=$(usex wayland 1 0) \
	USE_GSTREAMER=$(usex gstreamer 1 0) \
	KIVY_BUILD_EXAMPLES=$(usex examples 1 0) \
		distutils-r1_python_compile
}

python_install_all() {
	if use vim-syntax; then
		insinto /usr/share/vim/vimfiles/syntax
		doins kivy/tools/highlight/kivy.vim
	fi

	distutils-r1_python_install_all
}

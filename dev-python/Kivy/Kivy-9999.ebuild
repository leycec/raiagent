# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} )

inherit distutils-r1

DESCRIPTION="Open source UI framework written in Python"
HOMEPAGE="https://kivy.org"

LICENSE="MIT"
SLOT="0"
IUSE="
	X doc egl examples gles2 highlight +imaging opengl pango pygame gstreamer
	rst +sdl spell wayland
"
REQUIRED_USE="
	egl? ( opengl )
	gles2? ( opengl )
	pygame? ( sdl )
"

BEPEND="dev-python/cython[${PYTHON_USEDEP}]"
RDEPEND="
	X? ( x11-libs/libX11 )
	gstreamer? ( dev-python/gst-python:1.0[${PYTHON_USEDEP}] )
	highlight? ( dev-python/pygments[${PYTHON_USEDEP}] )
	imaging? ( dev-python/pillow[${PYTHON_USEDEP}] )
	opengl? ( media-libs/mesa[X?,egl?,gles2?,wayland?] )
	pango? ( x11-libs/pango[X?] )
	sdl? (
		pygame? ( dev-python/pygame[X?,opengl?,${PYTHON_USEDEP}] )
		!pygame? (
			media-libs/libsdl2[X?,wayland?]
			media-libs/sdl2-image
			media-libs/sdl2-mixer
			media-libs/sdl2-ttf
		)
	)
	rst? ( dev-python/docutils[${PYTHON_USEDEP}] )
	spell? ( dev-python/pyenchant[${PYTHON_USEDEP}] )
	wayland? ( dev-libs/wayland )
"
DEPEND="${RDEPEND}"

#FIXME: Excise if unneeded.
# S="${WORKDIR}/${P,,}"
# DISTUTILS_IN_SOURCE_BUILD=1

distutils_enable_tests pytest
distutils_enable_sphinx docs

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/kivy/kivy.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

python_compile() {
	# Export environment variables expected by this package's "setup.py"
	# (listed in the same order for maintainability). However, note that:
	# * These variables are almost entirely undocumented. It is what it is.
	# * These variables are listed undercase in "setup.py" but *MUST*
	#   nonetheless be declared as uppercase here. It is what it is.
	# * The values of these variables *MUST* be either:
	#   * "1" to signify a "True" boolean value.
	#   * "0" to signify a "False" boolean value.
	export USE_EGL=$(usex egl 1 0)
	export USE_OPENGL_ES2=$(usex gles2 1 0)
	export USE_SDL2=$(usex sdl 1 0)
	export USE_PANGOFT2=$(usex pango 1 0)
	export USE_MESAGL=$(usex opengl 1 0)
	export USE_X11=$(usex X 1 0)
	export USE_WAYLAND=$(usex wayland 1 0)
	export USE_GSTREAMER=$(usex gstreamer 1 0)

	distutils-r1_python_compile
}

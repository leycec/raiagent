# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake xdg

DESCRIPTION="GUI used to map keyboard buttons and mouse controls to a gamepad"
HOMEPAGE="https://github.com/AntiMicroX/antimicrox"

LICENSE="GPL-3"
SLOT="0"
IUSE="+X doc test udev +uinput xtest"
REQUIRED_USE="udev? ( uinput ) uinput? ( X ) xtest? ( X )"

#FIXME: Report this CMake warning to upstream's issue tracker:
#     CMake Warning (dev) at /usr/share/cmake/Modules/FindPackageHandleStandardArgs.cmake:438 (message):
#       The package name passed to `find_package_handle_standard_args` (SDL2main)
#       does not match the name of the calling package (SDL2).  This can lead to
#       problems in calling code that expects `find_package` result variables
#       (e.g., `_FOUND`) to follow a certain pattern.
#     Call Stack (most recent call first):
#       cmake/modules/FindSDL2.cmake:321 (FIND_PACKAGE_HANDLE_STANDARD_ARGS)
#       CMakeLists.txt:469 (find_package)
#     This warning is for project developers.  Use -Wno-dev to suppress it.

# Minimum version requirements are listed at the head of "CMakeLists.txt".
BDEPEND="
	dev-qt/linguist-tools:5
	dev-util/itstool
	virtual/pkgconfig
	doc? ( app-doc/doxygen )
	>=dev-util/cmake-3.12
"
RDEPEND="
	>=dev-qt/qtgui-5.8.0:5
	>=dev-qt/qtnetwork-5.8.0:5
	>=dev-qt/qtwidgets-5.8.0:5
	>=dev-qt/qtcore-5.8.0:5
	>=media-libs/libsdl2-2.0.6[X=,joystick]
	udev? ( virtual/udev )
	X? (
		x11-libs/libX11
		uinput? ( x11-libs/libXi )
		xtest? ( x11-libs/libXtst )
	)
"
DEPEND="${RDEPEND}"

src_prepare() {
	xdg_environment_reset
	cmake_src_prepare
}

src_configure() {
	#FIXME: Additionally support these CMake flags:
	#    -DAPPDATA=[ON|OFF]
	#    -DTRANS_KEEP_OBSOLETE=[ON|OFF]
	#    -DUPDATE_TRANSLATIONS=[ON|OFF]
	local mycmakeargs=(
		-DBUILD_DOCS=$(usex doc ON OFF)
		-DINSTALL_UINPUT_UDEV_RULES=$(usex udev ON OFF)
		-DWITH_TESTS=$(usex test ON OFF)
		-DWITH_UINPUT=$(usex uinput ON OFF)
		-DWITH_X11=$(usex X ON OFF)
		-DWITH_XTEST=$(usex xtest ON OFF)
		-DCHECK_FOR_UPDATES=OFF
	)

	cmake_src_configure
}

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/AntiMicroX/antimicrox.git"
	EGIT_BRANCH="master"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="https://github.com/AntiMicroX/antimicrox/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/setuptools/setuptools-9999.ebuild,v 1.1 2013/01/11 09:59:31 mgorny Exp $
EAPI="5"

# Enforce Bash scrictness.
set -e

inherit java-pkg-2 java-ant-2

DESCRIPTION="JavaScript and CSS compressor"
HOMEPAGE="http://yui.github.io/yuicompressor/"
SRC_URI="https://github.com/yui/yuicompressor/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD MPL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

# YUI Compressor also requires a YUI Compressor-specific version of the Rhino
# library, for which it provides custom ".java" files. While we *COULD* and
# probably *SHOULD* compile such version from source, doing so requires also
# downloading the corresponding version of Rhino, interleaving its source
# into the YUI Compressor tree in a manner preserving the custom files provided
# by YUI Compressor, and then compiling such source. While certainly feasible,
# this is somewhat outside the scope of this modest ebuild. Instead, we preserve
# the custom .jar" file of the Rhino library bundled in the above archive.
COMMON_DEPS=">=dev-java/jargs-1.0"
DEPEND="${COMMON_DEPS}
	>=virtual/jdk-1.5"
RDEPEND="${COMMON_DEPS}
	>=virtual/jre-1.5"

EANT_BUILD_TARGET="build.jar"

# Called by eclass "java-utils-2" during the src_prepare() phase.
java_prepare() {
	rm -v -- lib/jargs-1.0.jar
	java-pkg_jar-from jargs jargs.jar lib/jargs-1.0.jar
}

src_install() {
	java-pkg_newjar build/${P}.jar ${PN}.jar
	java-pkg_dolauncher
	dodoc README.md doc/CHANGELOG
}

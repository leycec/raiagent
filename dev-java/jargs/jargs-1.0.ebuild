# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/setuptools/setuptools-9999.ebuild,v 1.1 2013/01/11 09:59:31 mgorny Exp $
EAPI="5"

# With thanks to Sebastian Pipping <sping@gentoo.org> and Peter Stuge
# <peter@stuge.se>, this ebuild is derivative of:
#     http://data.gpo.zugaina.org/betagarden/dev-java/jargs/jargs-1.0.ebuild

# Enforce Bash scrictness.
set -e

inherit java-pkg-2 java-ant-2

DESCRIPTION="Java classes that implement parsing of command-line options"
HOMEPAGE="http://jargs.sourceforge.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=">=virtual/jdk-1.3"
RDEPEND=">=virtual/jre-1.3"

EANT_BUILD_TARGET="compile runtimejar"
EANT_DOC_TARGET="javadoc"

src_install() {
	java-pkg_dojar "lib/${PN}.jar"
}

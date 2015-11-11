# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

PYTHON_COMPAT=( python{2_7,3_2,3_3,3_4} pypy{,3} )

inherit distutils-r1

MY_PN="ruamel.std.argparse"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Enhancements to argparse"
HOMEPAGE="https://pypi.python.org/pypi/ruamel.std.argparse"
SRC_URI="mirror://pypi/r/${MY_PN}/${MY_P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}"
DEPEND="${RDEPEND}
	test? ( dev-python/pytest[${PYTHON_USEDEP}] )
"

S="${WORKDIR}/${MY_P}"
DOCS="README.rst"

# Run tests with verbose output failing on the first failing test.
python_test() {
	py.test -vvx test || die "Tests fail under ${EPYTHON}."
}

python_install_all() {
	distutils-r1_python_install_all

	# Define ${PYTHON_SITEDIR}, a string global expanding to the absolute path
	# of the "site-packages" subdirectory for the current Python implementation.
	python_export PYTHON_SITEDIR

	# Absolute path of the "ruamel/__init__.py" file shared by all Python
	# modules in the "ruamel" namespace.
	local ruamel_namespace_filename="${PYTHON_SITEDIR}"/ruamel/__init__.py

	# If such file has already been installed, prevent such file from being
	# reinstalled and hence triggering a "Detected file collision(s)" error.
	if [[ -f "${ruamel_namespace_filename}" &&\
		  -f "${D}${ruamel_namespace_filename}" ]]; then
		rm   "${D}${ruamel_namespace_filename}"
	fi
}

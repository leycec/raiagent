# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

#FIXME: While ruamel.yaml technically supports Python 2.7, such support
#conditionally requires an additional as-yet-unimplemented ebuild:
#"ruamel.ordereddict". On adding such ebuild to the overlay, add "python2_7"
#back to ${PYTHON_COMPAT} below *AND* add the following conditional
#dependency to ${RDEPEND}:
#    $(python_gen_cond_dep 'dev-python/ruamel_ordereddict[${PYTHON_USEDEP}]' 'python2*'

# ruamel.yaml requires either Python 2.7 or >= 3.3.
PYTHON_COMPAT=( python{3_3,3_4} pypy{,3} )

inherit distutils-r1

MY_PN="ruamel.yaml"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="YAML parser/emitter that supports roundtrip comment preservation"
HOMEPAGE="https://pypi.python.org/pypi/ruamel.yaml"
SRC_URI="mirror://pypi/r/${MY_PN}/${MY_P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
	dev-libs/libyaml
	dev-python/ruamel_std_argparse[${PYTHON_USEDEP}]
"
#FIXME: Unfortunately, we currently receive "repoman" errors when attempting to
#enable ${PYTHON_USEDEP} on "dev-python/cython". This probably is *NOT* our
#fault. Enable the following dependency when working:
#    dev-python/cython[${PYTHON_USEDEP}]

DEPEND="${RDEPEND}
	!dev-python/pyyaml[libyaml]
	dev-python/cython
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

# Likewise, pypy3 appears to *NOT* be currently supported by cython and is hence
# omitted.

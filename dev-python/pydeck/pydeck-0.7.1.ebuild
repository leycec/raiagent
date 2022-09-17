# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Note that a live git-managed "9999" version is intentionally *NOT* provided.
# This Python package is embedded in a larger JavaScript "deck.gl" package,
# significantly complicating installation from the GitHub repository. See also:
#     https://github.com/visgl/deck.gl/tree/master/bindings/pydeck

#FIXME: pydeck's "setup.py" appears to be improperly configured and is currently
#emitting Gentoo QA warnings. Although they appear to all be fairly ignorable,
#submit an upstream deck.gl issue requesting an upstream resolution.
#FIXME: pydeck's "setup.py" also provides a facility for building a widget
#frontend (whatever that is). Sadly, doing so appears extremely non-trivial;
#indeed, it's unclear whether the published source tarball supports building
#this frontend, as doing so appears to require the full deck.gl git repository.

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..11} )

inherit distutils-r1

DESCRIPTION="Large-scale interactive data visualization"
HOMEPAGE="https://pydeck.gl"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"

# Dependencies derive from the "setup.py".
#
# Note that Jinja2 appears to be required at build time, oddly. *shrug*
BDEPEND="
	>=dev-python/jinja-2.10.1[${PYTHON_USEDEP}]
	test? (
		dev-python/pandas[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
		>=dev-python/pytest-4.0.2[${PYTHON_USEDEP}]
	)
"
RDEPEND="
	>=dev-python/ipykernel-5.1.2[${PYTHON_USEDEP}]
	>=dev-python/ipywidgets-7.0.0[${PYTHON_USEDEP}]
	>=dev-python/jinja-2.10.1[${PYTHON_USEDEP}]
	>=dev-python/numpy-1.16.4[${PYTHON_USEDEP}]
	>=dev-python/traitlets-4.3.2[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"

distutils_enable_tests pytest

python_prepare_all() {
	#FIXME: *REMOVE THIS ENTIRE COMMAND ON THE NEXT PACKAGE BUMP.* Upstream has
	#already resolved both of these issues.
	# Patch the broken "pyproject.toml" as follows:
	# * Replace the incorrect version with the current version.
	# * Prepend the "requires =" setting with the mandatory "[build-system]".
	sed -i \
		-e "s~0.3.0~${PN}~" \
		-e '4i [build-system]' \
		pyproject.toml || die '"sed" failed.'

	# Delete the line in "setup.py" erroneously installing a pydeck-specific
	# configuration file to the non-standard "/usr/etc/" directory.
	sed -i -e '\~"etc/jupyter/nbconfig/notebook.d"~d' setup.py ||
		die '"sed" failed.'

	distutils-r1_python_prepare_all
}

python_install_all() {
	[[ -d examples ]] && dodoc -r examples

	# Install the pydeck-specific configuration file to the standard "/etc/"
	# directory. See the related "sed" patch above.
	insinto /etc/jupyter/nbconfig/notebook.d
	doins pydeck.json

	distutils-r1_python_install_all
}

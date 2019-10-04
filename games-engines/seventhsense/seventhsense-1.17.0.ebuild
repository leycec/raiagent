# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic

# URL for the directory containing all Seventh Sense-specific book data.
DATA_URL="https://projectaon.org/staff/david/Books/"

DESCRIPTION="Playing aid for Project Aon editions of Lone Wolf adventure books"
HOMEPAGE="https://www.projectaon.org/staff/david"

# Prefix book zipfiles by ${PN} for disambiguity.
SRC_URI="
	https://www.projectaon.org/staff/david/Seventh%20Sense%20Source.zip
	data? (
		${DATA_URL}/01fftd.zip  -> ${PN}-01fftd.zip
		${DATA_URL}/02fotw.zip  -> ${PN}-02fotw.zip
		${DATA_URL}/03tcok.zip  -> ${PN}-03tcok.zip
		${DATA_URL}/04tcod.zip  -> ${PN}-04tcod.zip
		${DATA_URL}/05sots.zip  -> ${PN}-05sots.zip
		${DATA_URL}/06tkot.zip  -> ${PN}-06tkot.zip
		${DATA_URL}/07cd.zip    -> ${PN}-07cd.zip
		${DATA_URL}/08tjoh.zip  -> ${PN}-08tjoh.zip
		${DATA_URL}/09tcof.zip  -> ${PN}-09tcof.zip
		${DATA_URL}/10tdot.zip  -> ${PN}-10tdot.zip
		${DATA_URL}/11tpot.zip  -> ${PN}-11tpot.zip
		${DATA_URL}/12tmod.zip  -> ${PN}-12tmod.zip
		${DATA_URL}/13tplor.zip -> ${PN}-13tplor.zip
		${DATA_URL}/14tcok.zip  -> ${PN}-14tcok.zip
		${DATA_URL}/15tdc.zip   -> ${PN}-15tdc.zip
		${DATA_URL}/16tlov.zip  -> ${PN}-16tlov.zip
		${DATA_URL}/17tdoi.zip  -> ${PN}-17tdoi.zip
		${DATA_URL}/18dotd.zip  -> ${PN}-18dotd.zip
		${DATA_URL}/19wb.zip    -> ${PN}-19wb.zip
		${DATA_URL}/20tcon.zip  -> ${PN}-20tcon.zip
	)
"

LICENSE="seventh-sense"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+data debug editor"
REQUIRED_USE=""

BDEPEND="
	sys-devel/make
"
DEPEND="
	dev-games/physfs
	media-libs/sdl-image
	media-libs/sdl-ttf
"
RDEPEND="${DEPEND}
	app-shells/bash
"

S="${WORKDIR}/SeventhSense-${PV}"

src_prepare() {
	# Munge the top-level makefile. Specifically:
	#
	# * Preserve Gentoo-specific ${CXXFLAGS}.
	# * Strip hardcoded optimization (e.g., "-O2").
	# * Patch the include directory to refer to the standard include directory.
	sed -i\
		-e 's~\b\(OPTIMIZE := \)-O2\b~\1$(CXXFLAGS)~'\
		-e 's~-I/usr/local/include\b~-I'"${EROOT}"'/usr/include~'\
		Makefile || die '"sed" failed.'

	# Replace hardcoded non-standard directories with standard dot directories.
	sed -i -e 's~"Documents/Seventh Sense/"~".seventhsense/"~'\
		src/loader.cpp || die '"sed" failed.'

	# Apply user-specific patches and all patches added to ${PATCHES} above.
	default
}

src_compile() {
	# For each enabled USE flag, append a "gcc" directive defining a trivial
	# C preprocessor macro masquerading as a boolean flag. See "COMPILING.txt".
	use debug  && append-cxxflags $(test-flags-CXX -D_DEBUG)
	use editor && append-cxxflags $(test-flags-CXX -DEDITOR)

	emake
}

src_install() {
	local SEVENTHSENSE_HOME="/usr/share/${PN}"

	# Install Seventh Sense's executable.
	exeinto "${SEVENTHSENSE_HOME}"
	doexe LoneWolf

	# Install Seventh Sense's data directory.
	insinto "${SEVENTHSENSE_HOME}"
	doins -r data

	# Dynamically create and install an executable wrapper. Since directory
	# restoration is unavailable via Bourne shell, this uses Bash instead.
	cat <<EOF > "${T}"/${PN}
#!/usr/bin/env bash

# Switch to Seventh Sense's home directory.
pushd "${SEVENTHSENSE_HOME}" >/dev/null || {
	echo "\"${SEVENTHSENSE_HOME}\" not found."
	exit 1
}

# Run Seventh Sense, capturing its exit code.
./LoneWolf "\${@}"
exit_code=\${?}

# Switch back to the prior directory.
popd >/dev/null

# Report this exit code as our own.
exit \${exit_code}
EOF
	dobin "${T}"/${PN}

	# If installing book data...
	if use data; then
		# Substring prefixing the dirnames of all book data subdirectories.
		local SEVENTHSENSE_BOOK_PREFIX="${ED}${SEVENTHSENSE_HOME}/data/books/book"
		local\
			SEVENTHSENSE_BOOK_SRC_FILE\
			SEVENTHSENSE_BOOK_TRG_FILE\
			SEVENTHSENSE_BOOK_BASENAME\
			SEVENTHSENSE_BOOK_BASENAME_OLD\
			SEVENTHSENSE_BOOK_VOLUME

		# For each downloaded book data zipfile...
		for SEVENTHSENSE_BOOK_SRC_FILE in "${DISTDIR}"/${PN}*.zip; do
			# Strip the basename from the absolute filename of this zipfile.
			SEVENTHSENSE_BOOK_BASENAME="${SEVENTHSENSE_BOOK_SRC_FILE##*/}"

			# Strip the package name prefixing this basename.
			SEVENTHSENSE_BOOK_BASENAME_OLD="${SEVENTHSENSE_BOOK_BASENAME#${PN}-}"

			# Strip the volume (i.e., two digit identifier) from this basename.
			SEVENTHSENSE_BOOK_VOLUME="${SEVENTHSENSE_BOOK_BASENAME_OLD:0:2}"

			# Strip the leading "0" from this volume if any.
			SEVENTHSENSE_BOOK_VOLUME="${SEVENTHSENSE_BOOK_VOLUME#0}"

			# Absolute filename to copy this zipfile to.
			SEVENTHSENSE_BOOK_TRG_FILE="${SEVENTHSENSE_BOOK_PREFIX}${SEVENTHSENSE_BOOK_VOLUME}/${SEVENTHSENSE_BOOK_BASENAME_OLD}"

			# Copy this zipfile into a subdirectory specific to this volume.
			cp "${SEVENTHSENSE_BOOK_SRC_FILE}" "${SEVENTHSENSE_BOOK_TRG_FILE}"\
				|| '"cp" failed.'
		done
	fi
}

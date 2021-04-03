# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit font git-r3

DESCRIPTION="Monospaced fonts pre-patched with Powerline symbols"
HOMEPAGE="https://github.com/powerline/fonts"
EGIT_REPO_URI="https://github.com/powerline/fonts"

LICENSE="
	3270? ( || ( BSD CC-BY-SA-3.0 ) )
	anonymouspro? ( OFL-1.1 )
	arimo? ( Apache-2.0 )
	cousine? ( Apache-2.0 )
	dejavusansmono? ( BitstreamVera )
	droidsansmono? ( Apache-2.0 )
	droidsansmonodotted? ( Apache-2.0 )
	droidsansmonoslashed? ( Apache-2.0 )
	firamono? ( OFL-1.1 )
	gomono? ( BSD )
	hack? ( OFL-1.1 )
	inconsolata? ( OFL )
	inconsolatadz? ( OFL )
	inconsolata-g? ( OFL )
	liberationmono? ( OFL-1.1 )
	meslodotted? ( Apache-2.0 )
	mesloslashed? ( Apache-2.0 )
	monofur? ( free-noncomm )
	notomono? ( OFL-1.1 )
	novamono? ( free-noncomm )
	profont? ( MIT )
	robotomono? ( Apache-2.0 )
	sourcecodepro? ( OFL-1.1 )
	spacemono? ( OFL-1.1 )
	symbolneu? ( Apache-2.0 )
	terminus_pcf? ( OFL-1.1 )
	tinos? ( Apache-2.0 )
	ubuntumono? ( UbuntuFontLicense-1.0 )
"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86"

#FIXME: Add support for all additional fonts supported by the repository.

# src_install() expects USE flags to be the lowercase basenames of the
# corresponding font directories. See src_install_font() for details.
IUSE_FLAGS=(
	3270
	anonymouspro
	arimo
	cousine
	dejavusansmono
	droidsansmono
	droidsansmonodotted
	droidsansmonoslashed
	firamono
	gomono
	hack
	inconsolata
	inconsolatadz
	inconsolata-g
	liberationmono
	meslodotted
	mesloslashed
	monofur
	notomono
	novamono
	profont
	robotomono
	sourcecodepro
	spacemono
	symbolneu
	terminus_pcf
	tinos
	ubuntumono
)
IUSE="${IUSE_FLAGS[*]}"

# If no such USE flags were enabled, fail.
REQUIRED_USE="|| ( ${IUSE_FLAGS[*]} )"

# List of the basenames of all subdirectories containing OTF-formatted fonts.
OTF_DIRNAMES=(
	DroidSansMono
	FiraMono
	Inconsolata
	InconsolataDz
	Inconsolata-g
	SourceCodePro
)

# List of the basenames of all subdirectories containing TTF-formatted fonts.
TTF_DIRNAMES=(
	3270
	AnonymousPro
	Arimo
	Cousine
	DejaVuSansMono
	DroidSansMonoDotted
	DroidSansMonoSlashed
	GoMono
	Hack
	LiberationMono
	'Meslo Dotted'
	'Meslo Slashed'
	Monofur
	NotoMono
	NovaMono
	ProFont
	RobotoMono
	SpaceMono
	SymbolNeu
	Tinos
	UbuntuMono
)

# Temporary directory to which all fonts to be installed will be copied.
# Ideally, such fonts could simply be installed from their default directories;
# sadly, eclass "font" assumes such fonts always reside in a single directory.
FONT_S="${S}/fonts"
DOCS="README.rst"

src_install() {
	# Map of all font filetypes to be installed and hence appended to eclass
	# "font" string global ${FONT_SUFFIX} below. Since we only leverage this
	# map for its keys (e.g., as an unordered set or bag), all keys are mapped
	# to the empty string for simplicity.
	declare -A font_filetypes
	local otf_dirname ttf_dirname

	# Create the temporary directory containing all fonts to be installed.
	mkdir -p "${FONT_S}" || die '"mkdir" failed.'

	# Copy all fonts in the passed directory with the passed filetype to a
	# temporary directory for subsequent installation if the corresponding USE
	# flag is enabled or return silently otherwise.
	src_install_font() {
		(( ${#} == 2 )) || die 'Expected one dirname and one filetype.'
		local dirname="${1}" filetype="${2}" flag_name doc_filename

		# Name of the USE flag converted from the passed directory as follows:
		#
		# * "${...,,}", lowercasing this directory.
		# * "${...//[[:space:]]/}", stripping whitespace from this directory.
		flag_name="${dirname,,}"
		flag_name="${flag_name//[[:space:]]/}"

		# If this font's USE flag is enabled...
		if use "${flag_name}"; then
			# Install all fonts of this filetype in this subdirectory.
			mv "${dirname}"/*.${filetype} "${FONT_S}" || die '"mv" failed.'

			# Register this filetype with the "font" eclass below.
			font_filetypes[${filetype}]=

			# Install this font's documentation (if available) to a file with
			# the same basename as this directory with whitespace stripped.
			doc_filename="${dirname}/README.rst"
			if [[ -f "${doc_filename}" ]]; then
				newdoc "${doc_filename}" README_${dirname//[[:space:]]/}.rst
			fi
		fi
	}

	# Copy all OTF-formatted fonts to be installed into a temporary directory.
	for otf_dirname in "${OTF_DIRNAMES[@]}"; do
		src_install_font "${otf_dirname}" otf
	done

	# Copy all TTF-formatted fonts to be installed into a temporary directory.
	for ttf_dirname in "${TTF_DIRNAMES[@]}"; do
		src_install_font "${ttf_dirname}" ttf
	done

	# Terminus is a bitmap- rather than vector-based font and hence requires
	# unique handling. In particular, the repository provides three variants of
	# such patched font: in BDF, PCF, and PSF format. Since X.org is
	# incompatible with PSF-formatted fonts and since PCF-formatted fonts are
	# more space efficient than BDF-formatted fonts, install only the Terminus
	# fonts in PCF format. This corresponds to the "terminus" ebuild, as well.
	if use terminus_pcf; then
		mv Terminus/PCF/*.pcf.gz "${FONT_S}" || die '"mv" failed.'
		font_filetypes[pcf.gz]=
		newdoc Terminus/README.rst README_Terminus.rst
	fi

	# Convert the above map of all font filetypes to be installed into the
	# whitespace-delimited string global accepted by the "font" eclass.
	FONT_SUFFIX="${!font_filetypes[@]}"

	# Install these fonts.
	font_src_install
}

# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-power/phc-k8/phc-k8-0.4.4.ebuild,v 1.1 2011/11/18 08:45:18 xmw Exp $
EAPI=5

# Enforce Bash strictness.
set -e

inherit linux-info linux-mod readme.gentoo

# The most recent version of "phc-k8" is typically available from:
#     http://www.linux-phc.org/forum/viewtopic.php?f=13&t=38
DESCRIPTION="Processor Hardware Control for AMD K8 CPUs"
HOMEPAGE="http://www.linux-phc.org"
SRC_URI="http://www.linux-phc.org/forum/download/file.php?id=164 -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

S="${WORKDIR}/${PN}_v${PV/_beta/b}"

#FIXME: If "portage" does *NOT* have permissions to read
#"/usr/src/linux/include/generated/utsrelease.h", the "phc-k8" Makefile
#typically fails with:
#
#  "Makefile:25: *** Kernel version not found, maybe you need to install
#   appropriate kernel-headers or run make with KERNELSRC parameter, e.g.: make
#   KERNELSRC=/usr/src/linux.  Stop."
#
#Uninformative error messages must go. To correct this, verify such file to be
#readable if such file exists.

pkg_setup() {
	linux-mod_pkg_setup

	# If the current kernel has *NOT* been properly configured for "phc-k8",
	# print nonfatal warnings.
	if linux_config_exists; then
		if ! linux_chkconfig_module X86_POWERNOW_K8; then
			ewarn 'Kernel configuration option "X86_POWERNOW_K8" must be compiled as a'
			ewarn 'module rather than into the kernel itself.'
		fi
	else
		ewarn 'Your kernel is unconfigured (i.e., "'${KV_OUT_DIR}'/.config" not found).'
		ewarn 'Kernel configuration option "X86_POWERNOW_K8" must be compiled as a'
		ewarn 'module rather than into the kernel itself.'
	fi

	# Basename of the module to be built with mandatory suffix "()".
	MODULE_NAMES="phc-k8()"

	# The makefile assumes kernel sources to reside under
	# "/lib/modules/`uname -r`/build/", by default. Since such directory does
	# not necessarily correspond to that of the currently installed kernel,
	# replace such default with ${KERNEL_DIR}, the absolute path of such kernel
	# as set by eclass "linux-info". (Whew!)
	BUILD_PARAMS="KERNELSRC=\"${KERNEL_DIR}\" -j1"

	# Makefile target to be executed, cleanly building such module.
	BUILD_TARGETS="all"
}

src_prepare() {
	# If such kernel is a 2.x rather than 3.x kernel, such kernel provides no
	# files matching mperf.{c,h,ko,o}. In such case, instruct the makefile to
	# provide such files by setting ${BUILD_MPERF} to a non-empty string.
	if kernel_is le 2 6 32; then
		BUILD_PARAMS+=' BUILD_MPERF=1'
	# Else, use the mperf.{c,h,ko) files provided by the current kernel.
	else
		sed -e '/^MODULES/s:mperf.ko::' \
			-e '/^obj-m/s:mperf.o::' \
			-i Makefile || die
	fi
}

src_install() {
	linux-mod_src_install

	dodoc Changelog README
	newconfd "${FILESDIR}/conf" "${PN}"
	newinitd "${FILESDIR}/init" "${PN}"

	# Contents of the "/usr/share/doc/${P}/README.gentoo" file to be installed.
	DOC_CONTENTS="
After determining the highest stable vids (i.e., lowest stable voltages)
supported by your system, configure \"${EROOT}/etc/conf.d/${PN}\" accordingly
and add \"${PN}\" to the boot runlevel: e.g.,\\n
	rc-update add ${PN} boot"

	# Install such document.
	readme.gentoo_create_doc
}

pkg_postinst() {
	linux-mod_pkg_postinst

	# On first installations of this package, elog the contents of the
	# previously installed "/usr/share/doc/${P}/README.gentoo" file.
	readme.gentoo_print_elog
}

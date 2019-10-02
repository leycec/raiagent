raiagent —————[ …it is possibly good ]—————
===========================================

<!---
FIXME: Uncomment the following preferred document title, assuming we finally
crush all outstanding Travis-CI issues -- a *VERY* large assumption, indeed.

raiagent —————————[ [![Build Status](https://travis-ci.org/leycec/raiagent.svg?branch=master)](https://travis-ci.org/leycec/raiagent) ]—————————
===========
--->

**Welcome to `raiagent`,** the third-party Gentoo overlay where [Raia](https://en.wikipedia.org/wiki/Raja_%28genus%29) and gentlemanly conduct collide.

<img src="https://cloud.githubusercontent.com/assets/217028/7741975/ce3e814a-ff55-11e4-84d9-7fe8f2fab2f0.png" width="128" height="64"/> **+** <img src="https://cloud.githubusercontent.com/assets/217028/7742504/0d4c7394-ff5e-11e4-9352-9a30362fb37c.png" width="64" height="96"/> **=** `raiagent`

## Installation

`raiagent` is trivially installable via the [post-modern `eselect repository`
module](https://wiki.gentoo.org/wiki/Eselect/Repository), which now supersedes
the [antiquated `layman` command](https://wiki.gentoo.org/wiki/Layman):

* Install the `eselect repository` module (*if needed*).

        $ emerge --ask app-eselect/eselect-repository
        $ mkdir -p /etc/portage/repos.conf

* Add and synchronize this overlay.

        $ eselect repository enable raiagent
        $ emerge --sync raiagent

* Prepare for Gentoo-based winnage.

## Motivation

`raiagent` publishes well-documented ebuilds unabashedly biased toward technological self-empowerment.<sup>1</sup>

<sup>1. We *actually* believe most of the specious doggerel tastelessly defibrillating this sentence.</sup>

### CLI

Notable command-line interface (CLI) ebuilds include:

* **[Powerline](https://github.com/powerline/powerline)**, a general-purpose CLI statusline theme with cross-application support (e.g., `bash`, `tmux`, `vim`, `zsh`). `raiagent` [officially hosts](https://powerline.readthedocs.org/en/latest/installation/linux.html) Powerline ebuilds, co-maintained by a [frequent Powerline committer](https://github.com/ZyX-I).
* [fishman](https://github.com/fishman)'s [exuberant-ctags fork](https://github.com/fishman/ctags), an actively maintained [ctags](https://en.wikipedia.org/wiki/Ctags) variant with modern language support (e.g., CSS, Objective-C). `raiagent` unofficially hosts live ctags ebuilds in lieu of an official release.

### P2P

Notable peer-to-peer (P2P) ebuilds include:

* **[ZeroNet](https://zeronet.io)**, a peer-to-peer web hosting network brokered
  with demonetized [BitCoin](https://en.wikipedia.org/wiki/Bitcoin) blockchain
  semantics distributed over the decentralized
  [BitTorrent](https://en.wikipedia.org/wiki/BitTorrent) protocol complete with
  optional Tor-based traffic anonymization. *Yeah.* It's pretty special.
  `raiagent` [officially hosts](https://github.com/HelloZeroNet/ZeroNet) ZeroNet
  ebuilds.

### Python

Notable Python ebuilds include:

* **[PySide2](https://wiki.qt.io/Qt_for_Python)** (AKA, "Qt for
  Python;" AKA, `pyside-setup-everywhere-src`; AKA, The Package Formerly Known
  as PySide2),<sup>*don't ask*</sup> the official LGPL-licensed Qt bindings for
  Python. `raiagent` [officially hosts](https://bugs.gentoo.org/624682) ebuilds
  installing the full PySide2 stack: i.e., PySide2 **+** pyside2-tools **+**
  shiboken2 **+** Qt.
* **[pytest-xvfb](https://github.com/The-Compiler/pytest-xvfb)**, a
  third-party Python package integrating the [popular pytest
  framework](https://pytest.org) with the [Xvfb (X virtual
  framebuffer)](https://en.wikipedia.org/wiki/Xvfb) for automated headless
  testing of graphical Python applications. `raiagent` officially hosts
  ebuilds installing the full pytest-xvfb stack: i.e., `pytest-xvfb` **+**
  `pytest` **+** `Xvfb` **+** `PyVirtualDisplay` **+** `EasyProcess`.

### Retro

Notable "enthusiast" ebuilds include:

* **[Munt](https://github.com/munt/munt)**, a cross-platform software
  synthesiser emulating pre-GM Roland MIDI devices (e.g.,
  [MT-32](https://en.wikipedia.org/wiki/Roland_MT-32)) commonly supported by
  MS-DOS-era games. `raiagent` unofficially hosts Munt ebuilds.
* **[VGMPlay](http://vgmrips.net/forum/viewtopic.php?t=112)**, a cross-platform
  audio player and converter effectively emulating all sequenced video game
  sound chips and hence supporting all sequenced video game music – ever. As
  [RetroArch](https://www.libretro.com/index.php/retroarch-2) is to game
  emulation, VGMPlay is to game *audio* emulation. `raiagent` unofficially hosts
  VGMPlay ebuilds.

### Ricing

Notable **ricing** (i.e., soft- and/or hardware performance tweaking) ebuilds include:

* [phc-k8](http://www.linux-phc.org/forum/viewtopic.php?f=13&t=2), an out-of-tree Linux kernel module supporting [undervolting](https://en.wikipedia.org/wiki/Dynamic_voltage_scaling) of AMD chipsets. Portage's [official `phc-k8` ebuilds](https://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/sys-power/phc-k8/) are [several years out-of-date](https://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/sys-power/phc-k8/ChangeLog?view=markup) and, unsurprisingly, fail to build against modern Linux kernels. `raiagent` unofficially hosts well-maintained phc-k8 ebuilds successfully building against all stable [gentoo-sources](https://wiki.gentoo.org/wiki/Kernel/Overview#General_purpose:_gentoo-sources) kernels, complete with user-configurable OpenRC startup script and configuration file.

### Roguelike

Notable **roguelike** (i.e., games featuring permanent death as a prominent mechanic) ebuilds include:

* [Cataclysm: Dark Days Ahead (C:DDA)](https://cataclysmdda.org/), a post-apocalyptic survival horror roguelike. `raiagent` [officially hosts](https://cddawiki.chezzo.com/cdda_wiki/index.php?title=How_to_compile#Gentoo) C:DDA ebuilds.
* [UnReal World (URW)](http://www.unrealworld.fi), a Finnish Iron-Age wilderness survival roguelike. `raiagent` [unofficially hosts](http://z3.invisionfree.com/UrW_forum/index.php?showtopic=3551) URW ebuilds.

### Science

Notable scientifical ebuilds include:

* **[BETSE](https://gitlab.com/betse/betse)** (**B**io **E**lectric **T**issue
  **S**imulation **E**ngine), a cross-platform pure-Python CLI-based finite
  volume simulator for 2D computational multiphysics problems in the life
  sciences coauthored by [the author](https://github.com/leycec) of this
  overlay.  Needless to say, `raiagent` [officially
  hosts](https://gitlab.com/betse/betse/blob/master/doc/md/INSTALL.md) BETSE
  ebuilds.
* **[BETSEE](https://gitlab.com/betse/betsee)** (**B**io **E**lectric **T**issue
  **S**imulation **E**ngine **E**nvironment), a cross-platform pure-Python
  [PySide2](https://wiki.qt.io/PySide2)-based [Qt 5](https://www.qt.io) GUI for
  [BETSE](https://gitlab.com/betse/betse) coauthored by [the
  author](https://github.com/leycec) of this overlay. Again, `raiagent`
  officially hosts BETSEE ebuilds.

## Contributors

`raiagent` is thanks to the concerted efforts of numerous
[committers](https://github.com/leycec/raiagent/graphs/contributors) and
[issue reporters](https://github.com/leycec/raiagent/issues) – especially:

* Nikolai Aleksandrovich Pavlov ([ZyX-I](https://github.com/ZyX-I)), whose
  gracious contributions to the suite of [Powerline
  ebuilds](https://github.com/leycec/raiagent/tree/master/app-misc) has been
  immeasurably invaluable. Thanks, Nikolai. Your Sisyphean efforts will not go
  unremembered.

## See Also

[`leycec`](https://github.com/leycec), the principal maintainer of `raiagent`,
actively contributes to various other first- and third-party Gentoo overlays –
including:

* The [official Qt overlay](https://github.com/gentoo/qt), notably the
  [PySide2](https://wiki.qt.io/PySide2), PySide2-tools, and shiboken2 packages.
* [stefan-gr](https://github.com/stefan-gr)'s 
  [unofficial `abendbrot` overlay](https://github.com/stefan-gr/abendbrot),
  emphasizing emulation frontends (e.g.,
  [EmulationStation](http://www.emulationstation.org),
  [RetroArch](http://www.libretro.com)).

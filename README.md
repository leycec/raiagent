raiagent ———[ …it is possibly good ]———
=======================================

<!---
FIXME: Uncomment the following preferred document title, assuming we finally
crush all outstanding Travis-CI issues -- a *VERY* large assumption, indeed.

raiagent —————————[ [![Build Status](https://api.travis-ci.org/leycec/raiagent.svg?branch=master)](https://travis-ci.org/leycec/raiagent) ]—————————
===========
--->

**Welcome to `raiagent`,** the third-party Gentoo overlay where [Raia](https://en.wikipedia.org/wiki/Raja_%28genus%29) and gentlemanly conduct collide.

<img src="https://cloud.githubusercontent.com/assets/217028/7741975/ce3e814a-ff55-11e4-84d9-7fe8f2fab2f0.png" width="128" height="64"/> **+** <img src="https://cloud.githubusercontent.com/assets/217028/7742504/0d4c7394-ff5e-11e4-9352-9a30362fb37c.png" width="64" height="96"/> **=** `raiagent`

## Installation

`raiagent` is installable via the [post-modern `eselect repository`
module](https://wiki.gentoo.org/wiki/Eselect/Repository), superseding the
[antiquated `layman` command](https://wiki.gentoo.org/wiki/Layman):

* Install the `eselect repository` module (*if needed*).

        $ emerge --ask app-eselect/eselect-repository
        $ mkdir -p /etc/portage/repos.conf

* Add and synchronize this overlay.

        $ eselect repository enable raiagent
        $ emerge --sync raiagent

* Prepare for Gentoo-based winnage.

## Motivation

`raiagent` publishes well-documented ebuilds unabashedly biased toward technological self-empowerment.<sup>1</sup>

<sup>1. We *actually* believe most of the specious doggerel tastelessly defibrillating that sentence.</sup>

### CLI

Notable command-line interface (CLI) ebuilds include:

* **[Powerline](https://github.com/powerline/powerline)**, a general-purpose CLI
  statusline theme with cross-application support (e.g., `bash`, `tmux`, `vim`,
  `zsh`). `raiagent` [officially
  hosts](https://powerline.readthedocs.org/en/latest/installation/linux.html)
  Powerline ebuilds, co-maintained by a [frequent Powerline
  committer](https://github.com/ZyX-I).
* [fishman](https://github.com/fishman)'s **[exuberant-ctags
  fork](https://github.com/fishman/ctags)**, an actively maintained
  [ctags](https://en.wikipedia.org/wiki/Ctags) variant with modern language
  support (e.g., CSS, Objective-C). `raiagent` unofficially hosts live ctags
  ebuilds in lieu of an official release.

### P2P

Notable peer-to-peer (P2P) ebuilds include:

* **[ZeroNet](https://zeronet.io)**, a peer-to-peer web hosting network
  brokered with demonetized [BitCoin](https://en.wikipedia.org/wiki/Bitcoin)
  blockchain semantics distributed over the decentralized
  [BitTorrent](https://en.wikipedia.org/wiki/BitTorrent) protocol complete with
  optional Tor-based traffic anonymization. *Yeah.* It's pretty special.
  `raiagent` [officially hosts](https://github.com/HelloZeroNet/ZeroNet)
  ZeroNet ebuilds.

### Perl 5

Notable Perl 5 ebuilds include:

* **[Minilla](https://metacpan.org/pod/Minilla)**, a command automating the
  production and distribution of CPAN modules. Minilla is a lightweight drop-in
  replacement for [Dist::Milla](https://metacpan.org/pod/Dist::Milla), the
  heavyweight older brother that should probably start hitting his local gym.
  `raiagent` unofficially hosts ebuilds installing the full Minilla stack.

### Python

Notable Python ebuilds include:

* **[PySide2](https://wiki.qt.io/Qt_for_Python)** (AKA, "Qt for
  Python;" AKA, `pyside-setup-everywhere-src`; AKA, The Package Formerly Known
  as PySide2),<sup>*don't ask*</sup> the official LGPL-licensed Qt bindings for
  Python. `raiagent` [officially hosts](https://bugs.gentoo.org/624682) ebuilds
  installing the full PySide2 stack: i.e., PySide2 **+** pyside2-tools **+**
  shiboken2 **+** Qt.
* Pure-Python [PEP-compliant](https://www.python.org/dev/peps/pep-0484) runtime
  type checkers:
  * **[beartype](https://github.com/beartype/beartype)**, the un:bear:ably fast
    runtime type checker guaranteeing `O(1)` time complexity, coauthored by
    [the author of this overlay](https://github.com/leycec). Unsurprisingly,
    `raiagent` [officially
    hosts beartype](https://github.com/beartype/beartype#features) ebuilds.
  * **[typeguard](https://github.com/agronholm/typeguard)**, a
    [*mostly* fully PEP-compliant](https://www.python.org/dev/peps/pep-0484)
    runtime type checker. `raiagent` unofficially hosts
    [typeguard](https://github.com/agronholm/typeguard) ebuilds. [See these
    timings first](https://github.com/beartype/beartype#timings), though.

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

### Roguelike

Notable **roguelike** (i.e., games featuring permanent death as a prominent mechanic) ebuilds include:

* **[Cataclysm: Dark Days Ahead (C:DDA)](https://cataclysmdda.org)**, a
  post-apocalyptic survival horror roguelike. `raiagent` [officially
  hosts](https://cddawiki.chezzo.com/cdda_wiki/index.php?title=How_to_compile#Gentoo)
  C:DDA ebuilds.
* **[UnReal World (URW)](http://www.unrealworld.fi)**, a Finnish Iron-Age
  wilderness survival roguelike. `raiagent` [unofficially
  hosts](http://z3.invisionfree.com/UrW_forum/index.php?showtopic=3551) URW ebuilds.

### Interactive Fiction (IF)

Notable **interactive fiction** (i.e., parser games featuring text-based control schemes) ebuilds include:

* **[Gargoyle (garglk)](http://ccxvii.net/gargoyle)**, the ultimate back- and
  frontend GUI supporting *most* (but inevitably not all) works of interactive
  fiction authored over the past several decades. Whereas Portage and the
  [equally awesome `interactive-fiction`
  overlay](https://repo.or.cz/w/gentoo-interactive-fiction.git) only host
  [Gargoyle's nearly decade-old 2011.1
  release](https://github.com/garglk/garglk/releases), `raiagent` [unofficially
  hosts](https://intfiction.org/t/gargoyle-2019-1-for-gentoo-linux-for-great-justice/43384)
  ebuilds for *most* modern Gargoyle releases.
* **[Seventh Sense](https://www.projectaon.org/staff/david)**, [David
  Olsen](https://www.projectaon.org/staff/david/donate.php)'s phenomenal back-
  and frontend GUI for [Joe](https://en.wikipedia.org/wiki/Joe_Dever) and [Ben
  Dever](https://gamebooknews.com/tag/ben-dever)'s *[Lone
  Wolf](https://en.wikipedia.org/wiki/Lone_Wolf_\(gamebooks\))* franchise of
  80's-era high-fantasy roguelike gamebooks. `raiagent` unofficially hosts
  Seventh Sense ebuilds. USE flags include:
  * `data` (enabled by default): automatically downloads and installs all data
    needed to play *Lone Wolf* 1—18. Thanks to [Joe's voluntary relinquishment
    of all prior copyright to Project
    Aon](https://www.projectaon.org/en/Main/Home), these gamebooks are freely
    (as in both beer and speech) playable... *for Sommerlund and the Kai!*
  * `editor` (*not* enabled by default): enables Seventh Sense's in-game WYSIWG
    editor for modifying existing gamebooks and creating new gamebooks under
    the *Lone Wolf* system.

### Science

Notable scientifical ebuilds include:

* **[BETSE](https://gitlab.com/betse/betse)** (**B**io **E**lectric **T**issue
  **S**imulation **E**ngine), a cross-platform pure-Python CLI-based finite
  volume simulator for 2D computational multiphysics problems in the life
  sciences coauthored by [the author of this
  overlay](https://github.com/leycec). Needless to say, `raiagent` [officially
  hosts](https://gitlab.com/betse/betse/blob/master/doc/md/INSTALL.md) BETSE
  ebuilds.
* **[BETSEE](https://gitlab.com/betse/betsee)** (**B**io **E**lectric **T**issue
  **S**imulation **E**ngine **E**nvironment), a cross-platform pure-Python
  [PySide2](https://wiki.qt.io/PySide2)-based [Qt 5](https://www.qt.io) GUI for
  [BETSE](https://gitlab.com/betse/betse) coauthored by [the author of this
  overlay](https://github.com/leycec). Again, `raiagent` officially hosts
  BETSEE ebuilds.

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

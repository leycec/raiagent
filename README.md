raiagent ——[ …it is possibly good ]——
=====================================

<!---
FIXME: Uncomment the following preferred document title, assuming we finally
crush all outstanding Travis-CI issues.

raiagent —————————[ [![Build Status](https://api.travis-ci.org/leycec/raiagent.svg?branch=master)](https://travis-ci.org/leycec/raiagent) ]—————————
===========
--->

**Welcome to `raiagent`,** the third-party Gentoo overlay where
[Raia](https://en.wikipedia.org/wiki/Raja_%28genus%29) and gentlemanly conduct
collide.

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

`raiagent` publishes well-documented ebuilds unabashedly biased toward
technological self-empowerment.<sup>1</sup>

<sup>1. We *actually* believe most of the specious doggerel tastelessly
defibrillating that sentence.</sup>

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

### Japan

Notable Japanese-centric ebuilds include:

* **[`mangal`](https://github.com/metafates/mangal),** a low-level terminal user
  interface (TUI) for finding, fetching, and locally reading Japanese manga –
  complete with Vi[M]-like key bindings. `raiagent` unofficially hosts `mangal`
  ebuilds.

### P2P

Notable peer-to-peer (P2P) ebuilds include:

* ~~**[ZeroNet](https://zeronet.io)**, a peer-to-peer web hosting network
  brokered with demonetized [BitCoin](https://en.wikipedia.org/wiki/Bitcoin)
  blockchain semantics distributed over the decentralized
  [BitTorrent](https://en.wikipedia.org/wiki/BitTorrent) protocol complete with
  optional Tor-based traffic anonymization. *Yeah.* It's pretty special.
  `raiagent` [officially hosts](https://github.com/HelloZeroNet/ZeroNet)
  ZeroNet ebuilds.~~ Tragically, **[ZeroNet is no longer actively
  maintained](https://github.com/HelloZeroNet/ZeroNet/issues/2749).** Until
  someone sufficiently young and idealistic creates a well-maintained friendly
  fork supporting the modern Python ecosystem, we have *no* choice but to
  remove all traces of ZeroNet from `::raiagent`.

### Python

Notable Python ebuilds include:

* Pure-Python profilers, including:
  * **[tuna](https://github.com/nschloe/tuna)**, a newer browser-based UI for
    visualizing files produced by deterministic Python profilers. Although
    comparable to SnakeViz, tuna output is more factual than SnakeViz output
    and thus recommended for modern profiling workflows. `raiagent`
    unofficially hosts tuna ebuilds.
* Pure-Python [PEP-compliant](https://www.python.org/dev/peps/pep-0621) build
  systems, including:
  * **[Hatch](https://hatch.pypa.io)**, the increasingly popular project
    management toolchain recently embraced by the Python Packaging Authority
    (PyPA). `raiagent` unofficially hosts Hatch ebuilds.
* Pure-Python [PEP-compliant](https://www.python.org/dev/peps/pep-0484) runtime
  type checkers, including:
  * **[beartype](https://github.com/beartype/beartype)**, the un:bear:ably fast
    runtime type checker guaranteeing `O(1)` time complexity, coauthored by
    [the author of this overlay](https://github.com/leycec). Unsurprisingly,
    `raiagent` [officially hosts
    beartype](https://github.com/beartype/beartype#features) ebuilds.
  * **[pyright](https://github.com/microsoft/pyright)**, Microsoft's
    permissively licensed open-source static type checker. Due to its strong
    performance guarantees, `pyright` is typically the default static
    type-checking solution for Python in Interactive Development Environments
    (IDEs) as diverse as VSCode and Vim. `raiagent` unofficially hosts pyright
    ebuilds.
* **[Bluetooth Low Energy platform Agnostic Klient
  (BLEAK)](https://github.com/hbldh/bleak)**, a popular `asyncio`-based
  Bluetooth Low Energy (BLE) framework with extensive platform-portable native
  support for both mobile and non-mobile app stacks. `raiagent` unofficially
  hosts BLEAK ebuilds.
* The **[full Kivy stack](https://kivy.org)**, including:
  * **[Kivy itself](https://kivy.org)**, a popular user interface (UI)
    framework with extensive platform-portable support for both desktop and
    mobile devices. Thanks to Portage sadly last-riting Kivy several years ago,
    `raiagent` [officially hosts Kivy
    ebuilds](https://kivy.org/doc/stable/installation/installation-linux.html#gentoo).
  * **[KivyMD](https://github.com/kivymd/KivyMD)**, an aesthetically pleasing
    suite of Google Material Design (MD)-compliant Kivy widgets. `raiagent`
    [officially hosts KivyMD
    ebuilds](https://kivy.org/doc/stable/installation/installation-linux.html#gentoo).
  * **[Buildozer](https://buildozer.readthedocs.io)**, Kivy's officially
    supported toolchain for cross-compiling self-contained executable apps.
    `raiagent` [officially hosts Buildozer ebuilds *and* ebuilds for optional
    runtime dependencies of Buildozer targeting various platforms
    ebuilds](https://kivy.org/doc/stable/installation/installation-linux.html#gentoo)–
    including:
    * **[`python-for-android`](https://python-for-android.readthedocs.io)**, a
      toolchain for cross-compiling self-contained executable apps as Android
      APKs and Android App Bundles (AABs).
* **[Streamlit](https://streamlit.io)**, a popular web dashboarding framework
  oriented towards data science and machine learning. `raiagent` [officially
  hosts Streamlit
  ebuilds](https://github.com/streamlit/streamlit/discussions/5411).

### (Micro|Circuit)Python

Notable MicroPython and/or CircuitPython ebuilds include:

* Remote CLI-based controllers, REPLs, and shells – including:
  * **[mpremote](https://docs.micropython.org/en/latest/reference/mpremote.html)**,
    MicroPython's official first-party remote controller that also
    transparently supports CircuitPython. `raiagent` unofficially hosts
    `mpremote` ebuilds.
  * **[rshell](https://github.com/dhylands/rshell)**, a once-popular
    MicroPython-specific remote shell largely superseded by
    [`mpremote`](https://docs.micropython.org/en/latest/reference/mpremote.html).
    Nonetheless, `raiagent` unofficially hosts `rshell` ebuilds.

### Retro

Notable "enthusiast" ebuilds include:

* **[AntiMicroX](https://github.com/AntiMicroX/antimicrox)**, a cross-platform
  gamepad->{keyboard,mouse} GUI enabling gamepad support in arbitrary games
  lacking native gamepad support. `raiagent` unofficially hosts AntiMicroX
  ebuilds.
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

Notable **roguelike** (i.e., games featuring permanent death as a prominent
mechanic) ebuilds include:

* **[Cataclysm: Dark Days Ahead (C:DDA)](https://cataclysmdda.org)**, a
  post-apocalyptic survival horror roguelike. `raiagent` [officially
  hosts](https://cddawiki.chezzo.com/cdda_wiki/index.php?title=How_to_compile#Gentoo)
  C:DDA ebuilds.
* **[The Slimy Lichmummy
  (TSL)](http://www.happyponyland.net/the-slimy-lichmummy)**, a classic
  dungeon-crawling roguelike from the Golden Age of Roguelikes (GAOR).
* **[UnReal World (URW)](http://www.unrealworld.fi)**, a Finnish Iron-Age
  wilderness survival roguelike. `raiagent` [unofficially
  hosts](http://z3.invisionfree.com/UrW_forum/index.php?showtopic=3551) URW ebuilds.

### Interactive Fiction (IF)

Notable **interactive fiction** (i.e., parser games featuring text-based
control schemes) ebuilds include:

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

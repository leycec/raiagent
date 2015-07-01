raiagent
===========

**Welcome to `raiagent`,** the third-party Gentoo overlay where [Raia](https://en.wikipedia.org/wiki/Raja_%28genus%29) and gentlemanly conduct collide.

![image](https://cloud.githubusercontent.com/assets/217028/7741975/ce3e814a-ff55-11e4-84d9-7fe8f2fab2f0.png)

**+**

![image](https://cloud.githubusercontent.com/assets/217028/7742504/0d4c7394-ff5e-11e4-9352-9a30362fb37c.png)

**=**

`raiagent`

## Motivation

`raiagent` publishes well-documented ebuilds unabashedly biased toward technological self-empowerment.

Yes, we believe most of the specious doggerel underflowing the prior sentence.

### CLI

Notable command-line interface (CLI) ebuilds include:

* [Powerline](https://github.com/powerline/powerline), a general-purpose CLI statusline theme with cross-application support (e.g., `bash`, `tmux`, `vim`, `zsh`). `raiagent` [officially hosts](https://powerline.readthedocs.org/en/latest/installation/linux.html) Powerline ebuilds, co-maintained by a [frequent Powerline committer](https://github.com/ZyX-I).
* [fishman](https://github.com/fishman)'s [exuberant-ctags fork](https://github.com/fishman/ctags), an actively maintained [ctags](https://en.wikipedia.org/wiki/Ctags) variant with modern language support (e.g., CSS, Objective-C). `raiagent` unofficially hosts live ctags ebuilds in lieu of an official release.

### P2P

Notable peer-to-peer (P2P) ebuilds include:

* [The Invisible Internet Project (I2P)](https://geti2p.net), an anonymous peer-to-peer communication layer colloquially referred to as a "[darknet](https://en.wikipedia.org/wiki/Darknet_\(networking\))." (Think [Tor hidden services](https://en.wikipedia.org/wiki/List_of_Tor_hidden_services) on illict performance-enhancing stimulants.) To safeguard users against deanonymization attacks specific to obsolete I2P releases, `raiagent` unofficially hosts **0-day I2P ebuilds** (i.e., ebuilds *ideally* updated the same day as official I2P updates). For quality assurance, our ebuilds are routinely synchronized against [Portage's older I2P ebuilds](https://packages.gentoo.org/package/net-p2p/i2p). 

### Python

Notable Python-centric ebuilds include:

* [PyInstaller](https://github.com/pyinstaller/pyinstaller)'s [Python 3 branch](https://github.com/pyinstaller/pyinstaller/tree/python3), a cross-platform Python freezing utility. `raiagent` unofficially hosts PyInstaller ebuilds, as well as [frequently committing]((https://github.com/leycec/pyinstaller)) to the official PyInstaller codebase.

### Roguelike

Notable **roguelike** (i.e., games featuring permanent death as a prominent mechanic) ebuilds include:

* [Cataclysm: Dark Days Ahead (C:DDA)](http://en.cataclysmdda.com), a post-apocalyptic survival horror roguelike. `raiagent` [officially hosts](http://www.wiki.cataclysmdda.com/index.php?title=How_to_compile#Gentoo) C:DDA ebuilds.
* [UnReal World (URW)](http://www.unrealworld.fi), a Finnish Iron-Age wilderness survival roguelike. `raiagent` [unofficially hosts](http://z3.invisionfree.com/UrW_forum/index.php?showtopic=3551) URW ebuilds.

### Tweaking

Notable hardware tweaking ebuilds include:

* [phc-k8](http://www.linux-phc.org/forum/viewtopic.php?f=13&t=2), an out-of-tree Linux kernel module supportting [undervolting](https://en.wikipedia.org/wiki/Dynamic_voltage_scaling) of AMD chipsets. Portage's [official `phc-k8` ebuilds](https://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/sys-power/phc-k8/) are [several years out-of-date](https://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/sys-power/phc-k8/ChangeLog?view=markup) and, unsurprisingly, fail to build against modern Linux kernels. `raiagent` unofficially hosts well-maintained phc-k8 ebuilds successfully building against all stable [gentoo-sources](https://wiki.gentoo.org/wiki/Kernel/Overview#General_purpose:_gentoo-sources) kernels, complete with user-configurable OpenRC startup script and configuration file.

## Installation

`raiagent` is installable in the usual way. Assuming use of `emerge` (and not
that *other* [disreputable fellow](http://paludis.exherbo.org)), this is:

* Install [`layman`](https://wiki.gentoo.org/wiki/Layman), Gentoo's official
  overlay manager.

        $ emerge layman
        $ echo 'source /var/lib/layman/make.conf' >> /etc/portage/make.conf

* Add the `raiagent` overlay.

        $ layman -a raiagent

* Synchronize overlays.

        $ layman -S

## Contributors

`raiagent` is thanks to the concerted efforts of numerous
[committers](https://github.com/leycec/raiagent/graphs/contributors) and
[issue reporters](https://github.com/leycec/raiagent/issues) – especially:

* Nikolai Aleksandrovich Pavlov ([ZyX-I](https://github.com/ZyX-I)), whose
  gracious contributions to the suite of [Powerline ebuilds](https://github.com/leycec/raiagent/tree/master/app-misc) has been unutterably invaluable. Thanks,
  Nikolai. Your Sisyphean efforts will not go unremembered.

## See Also

[`leycec`](https://github.com/leycec), the principal maintainer of `raiagent`,
actively contributes to numerous other third-party Gentoo overlays – especially:

* [stefan-gr](https://github.com/stefan-gr)'s
  [`abendbrot`](https://github.com/stefan-gr/abendbrot) overlay, emphasizing
  emulation frontends (e.g., [EmulationStation](http://www.emulationstation.org),
  [RetroArch](http://www.libretro.com)).

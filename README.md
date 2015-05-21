raiagent
===========

Welcome to `raiagent`, the third-party Gentoo overlay where
[Raia](https://en.wikipedia.org/wiki/Raja_%28genus%29) and gentlemanly conduct
collide.

![image](https://cloud.githubusercontent.com/assets/217028/7741975/ce3e814a-ff55-11e4-84d9-7fe8f2fab2f0.png)

**+**

![image](https://cloud.githubusercontent.com/assets/217028/7742504/0d4c7394-ff5e-11e4-9352-9a30362fb37c.png)

**=**

`raiagent`

## Motivation

`raiagent` publishes well-documented ebuilds unabashadly biased towards the CLI,
Python, cryptography, emulation, and roguelikes. Prominent ebuilds include:

* [Powerline](https://github.com/powerline/powerline), a general-purpose
  statusline theme. `raiagent`
  [officially hosts](https://powerline.readthedocs.org/en/latest/installation/linux.html)
  Powerline ebuilds, co-maintained by a [frequent Powerline
  committer](https://github.com/ZyX-I/powerline).
* [PyInstaller](https://github.com/pyinstaller/pyinstaller)'s [Python 3
  branch](https://github.com/pyinstaller/pyinstaller/tree/python3), a
  cross-platform Python freezing utility. `raiagent` unofficially hosts
  PyInstaller ebuilds, as well as frequently committing to the [PyInstaller
  codebase](https://github.com/leycec/pyinstaller).
* [Cataclysm: Dark Days Ahead](http://en.cataclysmdda.com), a post-apocalyptic
  survival horror roguelike. `raiagent`
  [officially hosts](http://www.wiki.cataclysmdda.com/index.php?title=How_to_compile#Gentoo)
  C:DDA ebuilds.
* [UnReal World](http://www.unrealworld.fi), a Finnish Iron-Age survival
  roguelike. `raiagent` [unofficially hosts](http://z3.invisionfree.com/UrW_forum/index.php?showtopic=3551) URW ebuilds.
* [fishman](https://github.com/fishman)'s [exuberant-ctags
  fork](https://github.com/fishman/ctags), an actively maintained ctags variant
  with modern language support (e.g., CSS, Objective-C). `raiagent` unofficially
  hosts live ctags ebuilds.
* [phc-k8](http://www.linux-phc.org/forum/viewtopic.php?f=13&t=2), an
  out-of-tree Linux kernel module for undervolting AMD chipsets. Portage's
  [official phc-kw
  ebuilds](https://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/sys-power/phc-k8/)
  are [several years
  out-of-date](https://sources.gentoo.org/cgi-bin/viewvc.cgi/gentoo-x86/sys-power/phc-k8/ChangeLog?view=markup)
  and, unsurprisingly, fail to build against modern Linux kernels. `raiagent`
  unofficially hosts well-maintained phc-k8 ebuilds successfully building
  against all stable
  [gentoo-sources](https://wiki.gentoo.org/wiki/Kernel/Overview#General_purpose:_gentoo-sources)
  kernels, complete with a user-configurable OpenRC startup script.

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

`raiagent` is thanks to the concerted efforts of [numerous
committers](https://github.com/leycec/raiagent/graphs/contributors), including
(...but hardly limited to):

* Nikolai Aleksandrovich Pavlov ([ZyX-I](https://github.com/ZyX-I)), whose
  gracious contributions to the suite of [Powerline ebuilds](https://github.com/leycec/raiagent/tree/master/app-misc) has been *utterly* invaluable. Thanks,
  Nikolai. Your Sisyphean efforts will not go unremembered.

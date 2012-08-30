raiagent
===========

_RaiaGent_ :: the frumious Gentoo overlay from Raiazome and fellows.

## Synopsis

Well-documented ebuilds en-route to a bandersnatch near you.

## Usage

#### Install `layman`, the Gentoo overlay manager.

    emerge layman
    echo 'source /var/lib/layman/make.conf' >> /etc/make.conf

#### Add the `raiagent` overlay.

    layman -o https://raw.github.com/leycec/raiagent/master/overlay.xml -f -a raiagent

#### Add all `raiagent` ebuilds.

    layman -S

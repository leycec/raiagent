raiagent
===========

_RaiaGent_ :: a frumious Gentoo overlay from Raiazome et al.

## Synopsis

Well-documented ebuilds en-route to a bandersnatch near you.

## Usage

* Install `layman`, the Gentoo overlay manager.
<code><pre><code>emerge layman
    echo 'source /var/lib/layman/make.conf' >> /etc/make.conf</code></pre></code>
* Add the `raiagent` overlay.
<code><pre><code>layman -o https://raw.github.com/leycec/raiagent/master/overlay.xml -f -a raiagent</code></pre></code>
* Retrieve the added overlay.
<code><pre><code>layman -S</code></pre></code>

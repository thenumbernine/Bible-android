[![Donate via Stripe](https://img.shields.io/badge/Donate-Stripe-green.svg)](https://buy.stripe.com/00gbJZ0OdcNs9zi288)<br>
[![BuyMeACoffee](https://img.shields.io/badge/BuyMeA-Coffee-tan.svg)](https://buymeacoffee.com/thenumbernine)<br>

This will be built off of my [LuaJIT-Android](https://github.com/thenumbernine/LuaJIT-android) repo.

# But Why?

I got tired of bloat and spam and popups asking me to rate apps 5 stars and everything other than a Bible app, so I made this to be absolutely nothing more than a Bible app.

# How To Build?

1) `git submodule update --init --recursive`
2) `cd LuaJIT && ./rename.rua && ./icon.rua ../icon.png` ... renames the LuaJIT repo to this repo and updates the icon.
3) `./make.rua install` from Bible project root folder.

How to in GNU Make?  I'm working on that...

# Repo Design

I'm still not sure how I want to use that repo in the future.
Should LuaJIT be the parent and this repo forked off of it?
Should LuaJIT be a submodule of this repo?
Should LuaJIT be a separate project that is permuted and packaged via my [lua-dist](https://github.com/thenumbernine/lua-dist) project?

Currently it is set up as a submodule.  I do hate submodules though, because to hold N repos with submodules that all are interdependent of each other, you end up with O(N^2) copies of everything.  So expect this to change.

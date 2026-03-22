[![Donate via Stripe](https://img.shields.io/badge/Donate-Stripe-green.svg)](https://buy.stripe.com/00gbJZ0OdcNs9zi288)<br>
[![BuyMeACoffee](https://img.shields.io/badge/BuyMeA-Coffee-tan.svg)](https://buymeacoffee.com/thenumbernine)<br>

This will be built off of my [LuaJIT-Android](https://github.com/thenumbernine/LuaJIT-android) repo.

I'm still not sure how I want to use that repo in the future, as a submodule (in this project), or as a separate project that is permuted and packaged via my [lua-dist](https://github.com/thenumbernine/lua-dist) project.

I do hate submodules, because to hold N repos with submodules that all are interdependent of each other, you end up with O(N^2) copies of everything.  So expect this to change.

# How To Build?

1) `git submodule update --init --recursive`
2) `cd LuaJIT && ./rename.rua` ... renames the LuaJIT repo to this repo

2.5) I still have this one line I need to wedge in for new LuaJIT projects:

```
copyAssets(
	path'../assets_patch',
	path'app/src/main/assets')
```

3) `./make.rua install` ... yes from the LuaJIT folder

How to in GNU Make?  I'm working on that...

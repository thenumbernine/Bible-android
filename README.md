This will be built off of my [LuaJIT-Android](https://github.com/thenumbernine/LuaJIT-android) repo.

I'm still not sure how I want to use that repo in the future, as a submodule (in this project), or as a separate project that is permuted and packaged via my [lua-dist](https://github.com/thenumbernine/lua-dist) project.

I do hate submodules, because to hold N repos with submodules that all are interdependent of each other, you end up with O(N^2) copies of everything.  So expect this to change.

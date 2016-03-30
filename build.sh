#!/usr/bin/env zsh

if hash stack 2>/dev/null; then
    stack ghc -- -odir build -hidir build compile.hs -O2
else
    print -- "Please install 'stack' (http://haskellstack.org)"
fi

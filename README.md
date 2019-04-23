> This project has two homes.
> It is ok to work in github, still, for a better decentralized web
> please consider contributing (issues, PR, etc...) throught:
>
> https://gitlab.esy.fun/yogsototh/mkdocs

---


---
theme: metropolis
---
# No Brainer Markdown to HTML & PDF

For each markdown files it will generate:

- an HTML Document: [example](https://yogsototh.github.io/mkdocs/druid/druid.html)
- an HTML Presentation (using reveal.js): [example](https://yogsototh.github.com/mkdocs/druid/druid.reveal.html)
- a PDF Document (using XeLaTeX): [example](https://yogsototh.github.io/mkdocs/druid/druid.pdf)
- a PDF Presentation (using Beamer): [example](https://yogsototh.github.io/mkdocs/druid/druid.beamer.pdf)

~~~
./compile.sh
~~~

If you want to be the 1337, install [`stack`](http://haskellstack.org)
and

~~~
./build.sh
./compile
~~~

## Dependencies

- [pandoc](http://pandoc.org) -- Tested with pandoc 1.15.0.6 & 1.17.2
- [XeLaTeX](http://xelatex.org) -- Tested with XeTeX 3.14159265-2.6-0.99992 (TeX Live 2015)
- [metropolis](https://github.com/matze/mtheme)
  Beamer theme (working forked version here:
  [`https://github.com/yogsototh/mtheme`](https://github.com/yogsototh/mtheme))

---
theme: metropolis
---
# No Brainer Markdown to HTML & PDF

For each markdown files it will generate:

- an HTML Document: [example](https://github.com/yogsototh/mkdocs/druid/druid.html)
- an HTML Presentation (using reveal.js): [example](https://github.com/yogsototh/mkdocs/druid/druid.reveal.html)
- a PDF Document (using XeLaTeX): [example](https://github.com/yogsototh/mkdocs/druid/druid.pdf)
- a PDF Presentation (using Beamer): [example](https://github.com/yogsototh/mkdocs/druid/druid.beamer.pdf)

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

- [pandoc](http://pandoc.org) -- Tested with pandoc 1.15.0.6
- [XeLaTeX](http://xelatex.org) -- Tested with XeTeX 3.14159265-2.6-0.99992 (TeX Live 2015)
- [metropolis](https://github.com/matze/mtheme)
  Beamer theme (working forked version here:
  [`https://github.com/yogsototh/mtheme`](https://github.com/yogsototh/mtheme))

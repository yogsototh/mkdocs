#!/usr/bin/env zsh

for fic in **/*.md(.); do
    print -n -- ${fic:r}.html
    prefix=$(print -- $fic|perl -pe 's#[^/]*/#../#g;s#[^/]*$##')
    pandoc -s -S --toc --css "${prefix}styling.css" \
        -V lang=en \
        -V highlighting-css= --mathjax \
        --smart --to=html5 -A footer.html \
        -o "${fic:r}.html" \
        $fic
    print " [DONE]"

    print -n -- ${fic:r}.pdf
    pandoc -s -S -N --toc \
        --template=template.latex \
        --variable mainfont="Hoefler Text" \
        --variable sansfont="Futura" \
        --variable monofont="Menlo" \
        --variable fontsize=14pt \
        --variable linkcolor=orange \
        --variable urlcolor=orange \
        --latex-engine=xelatex \
        -o ${fic:r}.pdf \
        $fic
    print " [DONE]"
done

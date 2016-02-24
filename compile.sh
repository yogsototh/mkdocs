#!/usr/bin/env zsh

if (($#==0)); then
    filelist=( **/*.md(.) )
else
    filelist=( $* )
fi

# init colors
autoload colors
colors
for COLOR in RED GREEN YELLOW BLUE MAGENTA CYAN BLACK WHITE; do
    eval $COLOR='$fg_no_bold[${(L)COLOR}]'
    eval BOLD_$COLOR='$fg_bold[${(L)COLOR}]'
done
eval RESET='$reset_color'

mainDir=$PWD
for src in $filelist; do
    cd ${src:h}
    fic=${src:t}
    print -- "-- ${YELLOW}$src${RESET} --"
    print -n -- ${src:r}.html
    prefix=$(print -- $fic|perl -pe 's#[^/]*/#../#g;s#[^/]*$##')
    pandoc -s -S --toc --css "${prefix}styling.css" \
        -V lang=en \
        -V highlighting-css= --mathjax \
        --smart --to=html5 -A ${mainDir}/footer.html \
        -o "${fic:r}.html" \
        $fic
    print " ${GREEN}[DONE]${RESET}"

    print -n -- ${src:r}.pdf
    # --variable mainfont="Hoefler Text" \
    # --variable sansfont="Futura" \
    # --variable monofont="Menlo" \
    pandoc -s -S -N --toc \
        --template=${mainDir}/template.latex \
        --variable fontsize=14pt \
        --variable linkcolor=orange \
        --variable urlcolor=orange \
        --latex-engine=xelatex \
        -o ${fic:r}.pdf \
        $fic
    print " ${GREEN}[DONE]${RESET}"

    print -n -- ${src:r}-pres.pdf
    slide_level=$(perl -ne 'if (/^slide_level: (.*)/) { print $1."\n"; }' <$fic)
    if [[ $slide_level = "" ]]; then slide_level=1 fi
    pandoc -s -S -N \
        -t beamer \
        --slide-level=$slide_level \
        --variable fontsize=14pt \
        --variable linkcolor=orange \
        --variable urlcolor=orange \
        --latex-engine=xelatex \
        -o ${fic:r}-pres.pdf \
        $fic
    print " ${GREEN}[DONE]${RESET}"
    print
    cd $mainDir
done

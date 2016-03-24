#!/usr/bin/env zsh

local -a help pdf web beamer reveal
zparseopts h=help -help=help \
            p=pdf -pdf=pdf \
            w=web -web=web \
            b=beamer -beamer=beamer \
            r=reveal -reveal=reveal

cmdname=${0:t}
print_help(){
    print -- "$cmdname [-dhvpwbr] [FILES]"
    print -- "\t-d --debug\tdebug mode"
    print -- "\t-h --help\tHelp message"
    print -- "\t-p --pdf\texport to pdf"
    print -- "\t-w --web\texport to html"
    print -- "\t-b --beamer\texport to pdf presentation using beamer"
    print -- "\t-r --reveal\texport to html presentation using reveal.js"
}

[[ -n $help ]] && { print_help; exit }

# Don't count parameters
while [[ ${1[1]} = '-' ]]; do
    shift
done

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

tohtml() {
    local src=$1
    local fic=${src:t}
    local dst=${fic:r}.html
    print -n -- ${src:r}.html
    prefix=$(print -- $src|perl -pe 's#[^/]*/#../#g;s#[^/]*$##')
    pandoc -s -S --toc --css "${prefix}styling.css" \
        -V lang=en \
        -V highlighting-css= --mathjax \
        --smart --to=html5 -A ${mainDir}/footer.html \
        -o "$dst" \
        $fic
    print " ${GREEN}[DONE]${RESET}"
}

topdf () {
    local src=$1
    local fic=${src:t}
    local dst=${fic:r}.pdf
    print -n -- ${src:r}.pdf
    pandoc -s -S -N --toc \
        --template=${mainDir}/template.latex \
        --variable fontsize=14pt \
        --variable linkcolor=orange \
        --variable urlcolor=orange \
        --latex-engine=xelatex \
        -o $dst \
        $fic
    print " ${GREEN}[DONE]${RESET}"
}

topdfpres () {
    local src=$1
    local fic=${src:t}
    local dst=${fic:r}-pres.pdf
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
        -o $dst \
        $fic
    print " ${GREEN}[DONE]${RESET}"
    print
}

tohtmlpres () {
    local src=$1
    local fic=${src:t}
    local dst=${fic:r}-pres.html
    print -n -- ${src:r}-pres.html
    slide_level=$(perl -ne 'if (/^slide_level: (.*)/) { print $1."\n"; }' <$fic)
    prefix=$(print -- $src|perl -pe 's#[^/]*/#../#g;s#[^/]*$##')
    if [[ $slide_level = "" ]]; then slide_level=1 fi
    pandoc -s --mathjax \
        -t html5 --template=${prefix}template-revealjs.html \
        --section-divs \
        --variable transition="linear" \
        --variable prefix="$prefix" \
        -o $dst \
        $fic
    print " ${GREEN}[DONE]${RESET}"
    print
}

mainDir=$PWD
for src in $filelist; do
    cd ${src:h}
    fic=${src:t}
    print -- "-- ${YELLOW}$src${RESET} --"

    [[ -n $web ]]    && tohtml $src
    [[ -n $reveal ]] && tohtmlpres $src
    [[ -n $pdf ]]    && topdf $src
    [[ -n $beamer ]] && topdfpres $src

    cd $mainDir
done

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

reveal() {
    local src=$1
    local fic=$2
    dst=${fic:r}-pres.html
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

    reveal $src $fic

    cd $mainDir
done

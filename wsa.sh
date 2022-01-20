#!/bin/sh
# ex: ai:sw=4:ts=4
# vim: ai:ft=sh:sw=4:ts=4:ff=unix:sts=4:et:fenc=utf8
# -*- sh; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4;
# atom: set usesofttabs tabLength=4 encoding=utf-8 lineEnding=lf grammar=shell;
# mode: shell; tabsoft; tab:4; encoding: utf-8; coding: utf-8;
##########################################################################
# $1: guess with correct (green) letters
# $2: guess with misplaced (yellow) letters
# $3: excluded (gray) letters list

_flagI='s'
_flagD='0'
while getopts 'DIdi' _opt
do
    case $_opt in
        [iI]) _flagI='is' ;;
        [dD]) _flagD='1' ;;
    esac
done
shift $((OPTIND -1))

if test $# -lt 2
then
    echo "Please enter your guess but with only correctly placed letters."
    echo "E.g, write BA--- when only those two are green for BAULD"
    printf '%s\t' "Good Catch?"
    read -r _start
else
    _start="$1"
fi
_start=$( echo "$_start....." |
    awk '{ gsub(/[^[:alpha:]]/, ".", $0); print tolower(substr($0,0,5)); }' )

if test -z "$2"
then
    echo "Please enter your guess but with only badly placed letters."
    echo "E.g, write EA when only those two are yellow for WEAVE"
    printf '%s\t' "Good Guess?"
    read -r _where
else
    _where="$2"
fi
_where=$( echo "$_where" |
    awk '{ gsub(/[^[:alpha:]]/, ".", $0); print tolower($0); }' )

if test -z "$3"
then
    echo "Please list together all known not used letters."
    echo "E.g, write SCRP when those four are greyed for SCRAP"
    printf '%s\t' "Bad Letters?"
    read -r _avoid
else
    _avoid="$3"
fi
_avoid=$( echo "$_avoid" |
    awk '{ gsub(/[^[:alpha:]]/, "", $0); print tolower($0); }' )

if test -n "$_avoid"
then
    _where=$( echo "$_where....." |
        awk "{ gsub(/[$_avoid]/, \"\", \$0); print substr(\$0,0,5); }" )
else
    _where=$( echo "$_where....." |
        awk '{ print substr($0,0,5); }' )
fi
_where=$( echo "$_where" |
    awk '{ gsub(/[^[:alpha:]]/, ".", $0); gsub(/[^.]/, "[^&]", $0); print $0; }' )
_there=$( echo "$_where" |
    awk '{ gsub(/[^[:alpha:]]/, "", $0); print tolower($0); }' )

if test -z "$WORDLE_LIST"
then
    for _file in american-english words
    do
        WORDLE_LIST="/usr/share/dict/$_file"
        if test -f "$WORDLE_LIST"
        then
            break
        fi
    done
fi
if ! test -r "$WORDLE_LIST"
then
    echo "Fatal, can't read $WORDLE_LIST" >&2
    exit 2
fi

if test $((WORDLE_SHOW)) -lt 1
then
    WORDLE_SHOW=15
fi

_infos()
{
    if test $((_flagD)) -gt 0
    then
        echo "[INFO] seeking: $1"
        echo "[INFO] using: $(wc -l "$WORDLE_LIST")"
        test -n "$2" &&
            echo "[INFO] scenario: $2"
        echo "next trial candidates:"
    fi
}

if test "$_start" = "$_where" &&
    test "$_avoid" = "$_there"
then
    # Case of first attempt, where:
    # - $_avoid and $_there are both '' and
    # - $_start and $_where are both '.....'
    # So we have to choose some random words from our list.
    # Let's filter letters according to their frequencies...
    # https://en.wikipedia.org/wiki/Etaoin_shrdlu
    # > e t a o i n  s h r d l u  c m f w y p  v b g k q j  x z
    # ...but as they appear in a dictionary and avoid less used
    # https://en.wikipedia.org/wiki/Letter_frequency
    # > e s i a r n  t o l c d u  g p m k h b  y f v w z x  q j
    _there='esiarntolcdugpmkhbyfvw'
    _avoid='zxqj'
    _infos "$_start [$_there] [^$_avoid]" 'nothing yet'
    # It's not mentionned, but we also avoid consecutive letters
    grep -w$_flagI "$_start" "$WORDLE_LIST" |
        grep -isv "[$_avoid]" |
        grep -Eisv '.*([a-z])\1.*' |
        grep -$_flagI "[$_there]" |
        sort -fR | head -n $WORDLE_SHOW
    # Note: `shuf` isn't POSIX so we go with `sort` and `head`
elif test -n "$_there" &&
    test -n "$_avoid"
then
    # Case of second and following generic attempts
    _infos "$_start $_where [$_there] [^$_avoid]" 'green yellow gray'
    grep -w$_flagI "$_start" "$WORDLE_LIST" |
        grep -isv "[$_avoid]" | grep -$_flagI "[$_there]" |
        grep -is -m $WORDLE_SHOW "$_where"
elif test ${#_there} -eq 5 &&
    test -z "$_avoid"
then
    # We have only misplaced letters, so let's focus on them.
    _infos "$_start $_where [$_there]" 'yellow only'
    grep -w$_flagI "$_start" "$WORDLE_LIST" |
        grep -$_flagI "[$_there]" |
        grep -is -m $WORDLE_SHOW "$_where"
elif test ${#_avoid} -eq 5 &&
    test -z "$_there"
then
    # We have only invalid letters, so rerun avoiding them.
    _infos "$_start [^$_avoid]" 'gray only'
    grep -v$_flagI "[$_avoid]" "$WORDLE_LIST" |
        grep -w$_flagI -m $WORDLE_SHOW "$_start"
elif echo "$_start" | grep -qsv -f '.' &&
    test "$_avoid" = "$_there"
then
    # Really? Aren't you kidding the script?
    _infos "$_start" 'green only'
    grep -w$_flagI "$_start" -m $WORDLE_SHOW "$WORDLE_LIST"
else
    # Hmm, this part shouldn't never be reached. Debug is needed.
    _infos "$_start/$_where/$_there/$_avoid" 'unknown'
    echo "Fatal, can't process this. Please fill an issue." >&2
fi

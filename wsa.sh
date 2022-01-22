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

_flagD='0'
_flagI='s'
_flagS='R'
while getopts 'DISdis' _opt
do
    case $_opt in
        [iI]) _flagI='is' ;;
        [dD]) _flagD='1' ;;
        [sS]) _flagS='d' ;;
    esac
done
shift $((OPTIND -1))
test "$_flagI" = 'is' &&
    _flagS="f$_flagS"

if test $# -lt 2
then
    echo "Please enter your guess but with only correctly placed letters."
    echo "E.g, write BA... when only those two are green for BAULD"
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
    echo "E.g, write .EA... when only those two are yellow for MEANS"
    echo "But write .E[AY]... if Y can't be in third position either."
    printf '%s\t' "Good Guess?"
    read -r _where
else
    _where="$2"
fi
_where=$( echo "$_where" |
    awk '{ gsub(/[^[:alpha:]\[\]]/, ".", $0); print tolower($0); }' )

if test -z "$3"
then
    echo "Please list together all known not used letters."
    echo "E.g, write SCRP when those four are greyed for SCRAP"
    echo "But write SCRPGKL if GKL was previously greyed also."
    printf '%s\t' "Bad Letters?"
    read -r _avoid
else
    _avoid="$3"
fi
_avoid=$( echo "$_avoid" |
    awk '{ gsub(/[^[:alpha:]]/, "", $0); print tolower($0); }' |
    tr -s '[a-z]' )

_limit=$( echo "$_where" | grep -os '\[\|\]' | grep -c '.' )
if test -n "$_avoid"
then
    _where=$( echo "$_where....." |
        awk "{ gsub(/[$_avoid]/, \"\", \$0); print substr(\$0,0,$(( _limit + 6 ))); }" )
else
    _where=$( echo "$_where....." |
        awk -v L=$(( _limit + 6 )) '{ print substr($0,0,L); }' )
fi
# note: AWK doesn't support look-ahead or look-behind since it uses POSIX ERE
# to work with captured-groups GAWK has `gensub()` which is not POSIX helas
# in another hand, back-references are POSIX BRE feature not in POSIX ERE...
# (it's strange and funny that busybox awk does support that feature)
_fixup=''
_limit=0
for _char1 in $( echo "$_where" | grep -os '.' )
do
    case "$_char1" in
        '[')
            _limit=$(( _limit + 1 ))
            _fixup="$_fixup["
            ;;
        ']')
            _limit=$(( _limit - 1 ))
            _fixup="$_fixup]"
            ;;
        [.-])
            _fixup="$_fixup."
            ;;
        *)
            if test $((_limit)) -gt 0
            then
                _fixup="$_fixup$_char1"
            else
                _fixup="$_fixup[$_char1]"
            fi
            ;;
    esac
done
unset _limit
_where=$( echo "$_fixup" |
    awk '{ gsub(/\[\]/, ".", $0); gsub(/\[/, "[^", $0); print $0; }' )
unset _fixup
_there=$( echo "$_where" |
    awk '{ gsub(/[^[:alpha:]]/, "", $0); print tolower($0); }' |
    tr -s '[a-z]' )

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
        printf "[INFO] max results limit count:\t%d\t" "$WORDLE_SHOW"
        case $_flagS in
            fR|R) echo "Random" ;;
            fd|d) echo "Sorted" ;;
        esac
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
    _infos "^$_start\$ [$_there] [^$_avoid]" 'nothing yet'
    # It's not mentionned, but we also avoid consecutive letters
    sort -b$_flagS "$WORDLE_LIST" |
        grep -w$_flagI "$_start" |
        grep -isv "[$_avoid]" |
        grep -Eisv '.*([a-z])\1.*' |
        grep -$_flagI -m $WORDLE_SHOW "[$_there]"
    # Note: `shuf` isn't POSIX so we go with `sort` and `head`
elif test -n "$_there" &&
    test -n "$_avoid"
then
    # Case of second and following generic attempts
    _needs=''
    _query="sort -b$_flagS '$WORDLE_LIST' | grep -w$_flagI '$_start'"
    _query="$_query | grep -isv '[$_avoid]'"
    for _char1 in $( echo "$_there" | grep -os '.' )
    do
        _needs="$_needs $_char1"
        _query="$_query | grep -$_flagI '$_char1'"
    done
    _infos "^$_start\$ $_where$_needs [^$_avoid]" 'traffic lights'
    unset _needs
    # `eval`ing is bad practice because of security concerns; but
    # > sort -b$_flagS "$WORDLE_LIST" |
    # >    grep -w$_flagI "$_start" | $_query |
    # >    grep -is -m $WORDLE_SHOW "$_where"
    # and similar aren't working (`cmd | $var | $var` is OK by itself.
    # Pipe in variables however make the thing fail. shell pitfails...)
    _where=$( echo "$_where" | tr -d '^' )
    eval "$_query | grep -isv -m $WORDLE_SHOW '$_where'"
    unset _query
elif test ${#_there} -eq 5 &&
    test -z "$_avoid"
then
    # We have only misplaced letters, so let's focus on them.
    _needs=''
    for _char1 in $( echo "$_there" | grep -o '.' )
    do
        _needs="$_needs $_char1"
    done
    _infos "^$_start\$ $_where$_needs" 'yellow only'
    unset _needs
    grep -w$_flagI "$_start" "$WORDLE_LIST" |
        grep -v$_flagI "[^$_there]" |
        grep -is -m $WORDLE_SHOW "$_where"
elif test -n "$_avoid" &&
    test -z "$_there"
then
    # We have only invalid letters, so rerun avoiding them.
    # Or well placed and invalid letters, same recipe then.
    _infos "^$_start\$ [^$_avoid]" 'no yellow'
    sort -b$_flagS "$WORDLE_LIST" |
        grep -ivs "[$_avoid]" |
        grep -w$_flagI -m $WORDLE_SHOW "$_start"
elif echo "$_start" | grep -qsv -f '.' &&
    test "$_avoid" = "$_there"
then
    # Really? Aren't you kidding the script?
    _infos "^$_start\$" 'green only'
    grep -w$_flagI "$_start" -m $WORDLE_SHOW "$WORDLE_LIST"
else
    # Hmm, this part shouldn't never be reached. Debug is needed.
    _infos "^$_start\$ $_where [$_there] [^$_avoid]" 'unknown'
    echo "Fatal, can't process this. Please fill an issue." >&2
fi

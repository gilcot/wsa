# Wordle & Lingo Solving Assistant

This works follow [Jim Hall's post on Solving Wordle using the GNU/Linux
commands](https://opensource.com/article/22/1/word-game-linux-command-line).
It automates the `grep`ing processes and should work with any POSIX shell.

Table of contents:

  - [Where to play?](#where)
  - [How to setup this script?](#install)
  - [How to use the script?](#usage)
  - [Miscellaneous thoughts](#misc)

For other concerns, bugs submission and features requierement, go the
tracker. You are also encouraged to clone this project, work on it, then
make a merge request. Also feel free to distribute it. In any case,
respect the [GPLv3 license](LICENSE).

## Where

The concept of Wordle can be found on many websites. Here is an not
exhaustive list:

  - [www.PowerLanguage.co.uk/wordle/](https://www.powerlanguage.co.uk/wordle/)
    is the official website of Wordle and it alows a play per day.
  - [www.DailyWordle.com](https://www.dailywordle.com/) with same interface as
    PowerLanguage and a word to guess each day.
  - [HelloWordl.net](https://hellowordl.net/) allow many length words…
  - [WordleGame.org](https://wordlegame.org/) allow many length words and other
    languages (english, french, german, spanish) with no limitation on plays.
  - [wheelsrpgs.itch.io/wheeldle](https://wheelsrpgs.itch.io/wheeldle) is said
    to be an infinite Wordle by WheelsRPGs
  - [sutom.nocle.fr](https://sutom.nocle.fr/) is for french Motus (unaccentued
    french word of seven letters that starts with the given one and to found
    within less than six tries.) One play per day.
  - [motus.absolu-puzzle.com](https://motus.absolu-puzzle.com/) is french Motus
    too (word of eigh unaccentued letters and seven tries.) No play limitation.
  - [www.cokogames.com/lingo/play/](https://www.cokogames.com/lingo/play/)
    five or six letters without limitation
  - [speellingo.nl](https://speellingo.nl/) Netherland version, three levels
    with five to seven letters and four time limited rounds.
  - [www.spel.nl/spel/lingo](https://www.spel.nl/spel/lingo) same interface as
    SpeelLingo plus age validation.

Tips and history about the game can be found
[here](https://heavy.com/news/wordle-game-how-where-to-play/) and
[there](https://www.theguardian.com/games/2021/dec/23/what-is-wordle-the-new-viral-word-game-delighting-the-internet)
[etc.](https://www.elitedaily.com/news/get-starbucks-good-vibe-messenger-text-2022)
Wordle isn't so new… [Motus in
France](https://fr.wikipedia.org/wiki/Motus_%28jeu_t%C3%A9l%C3%A9vis%C3%A9%29)
and [Lingo in United
Kingdom](https://en.wikipedia.org/wiki/Lingo_%28British_game_show%29) and
[many other
countries](https://en.wikipedia.org/wiki/Lingo_%28American_game_show%29)
predate it. Those games are also available for your desktop operating system
or your smartphone. If you enjoy such game, [there are some others you may
appreciate
too](https://www.polygon.com/essentials/22870790/games-like-wordle-puzzle-scrabble-games)
except that this script won't be helpful for them.

## Install

Either clone the repository:
```sh
git clone https://github.com/gilcot/wsa.git
ln $(pwd)/wsa/wsa.sh ~/bin/wsa.sh
```
or just download the script and make it executable:
```sh
cd ~/bin
wget https://raw.githubusercontent.com/gilcot/wsa/main/wsa.sh
chmod +x wsa.sh
```
In both case, ensure the script is in your path (i.e. `~/bin` here.)

## Usage

The script uses three arguments:

  1. Well placed letters, e.g `BA...` after the second try
  2. Misplaced letters, e.g `..L..` or `A....` after the second or first try
  3. The list of letters that don't exist in the word, e.g `CRES` at first try

When launched without one of the arguments, it swithes to interactively
inputing them.

Before starting, prepare your restricted words list, then put it's path
into the environment variable `WORDLE_LIST` prior. Example:
```sh
grep '^[a-z][a-z][a-z][a-z][a-z]$' /usr/share/dict/words > myguess
WORDLE_LIST=myguess wsa.sh
```
Note that:

  - Your words list should be all lowercase… otherwise use `-i` to make the
    searches case insentive.
  - If this environment variable is empty or unset, the script will go with
    system global dictionary which also contains names with title-case. That
    leads to some strange results that cannot be easely fixed.
  - You may use `-d` to display some internal informations before the results.
  - Results are often shuffled. Use `-s` to sort them alphabetically.

By the same way, you can change the number of propositions displayed with
the environment variable `WORDLE_SHOW`.
To play some other variant, set the length into the environment variable
`WORDLE_SIZE` and that's all.

Here, with `myguess` having 8497 entries (but without: bailo, bauld and
baulk), the arguments `'ba...' '..l..' 'cresmy'` found out:
```txt
babul
bakal
bakli
banal
```
Have fun.

## Misc



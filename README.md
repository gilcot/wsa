# Wordle Solving Assistant

This works follow [Jim Hall's post on Solving Wordle using the GNU/Linux
commands](https://opensource.com/article/22/1/word-game-linux-command-line).
It automates the `grep`ing processes and should work with any POSIX shell.

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

  1. Well placed letters, e.g `BA---` after the second try
  2. Misplaced letters, e.g `--L--` or `A----` after the second or first try
  3. The list of letters that don't exist in the word, e.g `CRES` at first try

When launched without one of the arguments, it swithes to interactively
inputing them.

If you want to use your restricted words list, put it's path into the
environment variable `WORDLE_LIST` prior. Example:
```sh
grep '^[a-z][a-z][a-z][a-z][a-z]$' /usr/share/dict/words > myguess
WORDLE_LIST=myguess wsa.sh
```
By the same way, you can change the number of propositions displayed with
the environment variable `WORDLE_SHOW`.

Here, with `myguess` having 8497 entries (but without: bailo, bauld and
baulk), the arguments `'ba---' '--l--' 'cresmy'` found out:
```txt
babul
bakal
bakli
banal
```
Have fun.

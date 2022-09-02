#!/bin/sh

WORDLIST="$HOME/.local/share/gen-passphrase-words.txt"

WORD_ID_CLASS='1-6'
WORD_ID_LEN=5

CAPITALIZE=1

WORD_DELIM='-'
PHRASE_LEN=6

USAGE="Usage: gen-passphrase.sh [-l length] [-d delimiter] [-f wordfile]
[-c] [-C class]

    -l length     Length of passphrase in words (default: $PHRASE_LEN
    -d delimiter  Delimiter to be used to separate words (default: $WORD_DELIM)
    -f wordfile   Specify the word list file (default: $WORDLIST)
                  This should be a diceware-style wordlist.
    -c            Do not capitalize each word
    -C class      Specify the character class of the 'word ID' used to select a
                  word from the word file (default: $WORD_ID_CLASS)"

help() {
    echo "$USAGE"
    exit 0
}

# Parse options
while getopts hcl:d:f:C: OPT; do
    case $OPT in
        l) PHRASE_LEN=$OPTARG ;;
        d) WORD_DELIM=$OPTARG ;;
        f) WORDLIST=$OPTARG ;;
        c) CAPITALIZE=0 ;;
        C) WORD_ID_CLASS=$OPTARG ;;
        h) help ;;
        \?)help ;;
    esac
done

# Echo first parameter with first character uppercased
capitalize() {
    echo $(echo "$1" | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }')
}

# Gets a $WORD_ID_LEN-digit number from /dev/urandom
getNum() {
    echo $(tr -dc $WORD_ID_CLASS </dev/urandom | head -c $WORD_ID_LEN)
}

# Gets a word from the wordlist based on word ID generated by getNum()
getWord() {
    echo $(grep "^$(getNum)" "$WORDLIST" | sed "s/^[0-9]*[ \\t]*//")
}

# Generate the passphrase:

i=$PHRASE_LEN
if [ $CAPITALIZE -eq 0 ]; then

    # Start with one word
    PASSPHRASE=$(getWord)
    # Add $PHRASE_LEN - 1 words to the passphrase
    while [ $i -gt 1 ]; do
        PASSPHRASE="$PASSPHRASE$WORD_DELIM$(getWord)"
        i=$(( $i - 1 ))
    done

else

    # Start with one word
    PASSPHRASE=$(capitalize $(getWord))
    # Add $PHRASE_LEN - 1 words to the passphrase
    while [ $i -gt 1 ]; do
        PASSPHRASE="$PASSPHRASE$WORD_DELIM$(capitalize $(getWord))"
        i=$(( $i - 1 ))
    done

fi

echo $PASSPHRASE
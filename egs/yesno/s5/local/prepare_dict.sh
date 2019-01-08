#!/bin/bash

mkdir -p data/local/dict

cp input/lexicon_nosil.txt data/local/dict/lexicon_words.txt
#Content of lexicon_words.txt YES Y, NO N

cp input/lexicon.txt data/local/dict/lexicon.txt
#include <SIL> SIL also in lexicon.txt

cat input/phones.txt | grep -v SIL > data/local/dict/nonsilence_phones.txt
#Put all lines not matching (-v) to SIL to nonsilence_phones.txt

echo "SIL" > data/local/dict/silence_phones.txt
#Put SIL to silence_phones.txt

echo "SIL" > data/local/dict/optional_silence.txt
#Put SIL to optional_silence.txt

echo "Dictionary preparation succeeded"

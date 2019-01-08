#!/bin/bash

train_cmd="utils/run.pl"
decode_cmd="utils/run.pl"

if [ ! -d waves_yesno ]; then
  wget http://www.openslr.org/resources/1/waves_yesno.tar.gz || exit 1;
  # was:
  # wget http://sourceforge.net/projects/kaldi/files/waves_yesno.tar.gz || exit 1;
  tar -xvzf waves_yesno.tar.gz || exit 1;
fi

train_yesno=train_yesno
test_base_name=test_yesno

rm -rf data exp mfcc

# Data preparation

local/prepare_data.sh waves_yesno
# Outputs in data/train_yesno and data/test_yesno
# 1. wav.scp - fileID -> file location mapping 
# 2. text - file ID -> text labels mapping
# 3. utt2spk - file ID -> speaker mapping
# 4. spk2utt - speaker -> file ID mapping

local/prepare_dict.sh
# Generate lexicon files inside data/local/dict/
# 1. lexicon_words.txt -> Word -> Pronounciation/class/model mapping
# 2. lexicon.txt -> Include SIL model also along with the word -> model mapping
# 3. nonsilence_phones.txt -> Include all non silence phonemes/models
# 4. silence_phones.txt -> Include all silence phonemes/models
# 5. optional_silence -> Include the optional silence models

utils/prepare_lang.sh --position-dependent-phones false data/local/dict "<SIL>" data/local/lang data/lang
# utils/prepare_lang.sh --position-dependent-phones false data/local/dict <SIL> data/local/lang data/lang
# Validate the above files for data format and allowed white spaces.
# Validates the outout directories data/lang and  data/lang/phones/
# Checks for disjointness of silence/nonsilence and disambig
# Check data/lang/topo
# Create data/lang/L.fst and data/lang/L_disambig.fst

local/prepare_lm.sh
#Preparing language model FST G.fst

# Feature extraction
for x in train_yesno test_yesno; do 
 #create mfcc for data/train_yesno and store in mfcc & logs in exp/make_mfcc/train_yesno
 #create mfcc for data/test_yesno and store in mfcc & logs in exp/make_mfcc/test_yesno 
 steps/make_mfcc.sh --nj 1 data/$x exp/make_mfcc/$x mfcc
 ## Compute cepstral mean and variance statistics per speaker.
 steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
 utils/fix_data_dir.sh data/$x
done

# Mono training
steps/train_mono.sh --nj 1 --cmd "$train_cmd" \
  --totgauss 400 \
  data/train_yesno data/lang exp/mono0a #Data/Language/trained data directories

# Graph compilation  
utils/mkgraph.sh data/lang_test_tg exp/mono0a exp/mono0a/graph_tgpr

# Decoding
steps/decode.sh --nj 1 --cmd "$decode_cmd" \
    exp/mono0a/graph_tgpr data/test_yesno exp/mono0a/decode_test_yesno

for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done

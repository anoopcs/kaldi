#!/bin/bash

mkdir -p data/local
local=`pwd`/local
scripts=`pwd`/scripts

export PATH=$PATH:`pwd`/../../../tools/irstlm/bin

echo "Preparing train and test data"

train_base_name=train_yesno
test_base_name=test_yesno
waves_dir=$1 #$1=waves_yesno

ls -1 $waves_dir > data/local/waves_all.list

cd data/local

#Split the first half of wavefiles to training set and remaining half to test set
../../local/create_yesno_waves_test_train.pl waves_all.list waves.test waves.train

#Create test_yesno_wav.scp file with content fileID<Space>location. File ID is filename without extension
../../local/create_yesno_wav_scp.pl ${waves_dir} waves.test > ${test_base_name}_wav.scp

#Create train_yesno_wav.scp file with content fileID<Space>location. File ID is filename without extension
../../local/create_yesno_wav_scp.pl ${waves_dir} waves.train > ${train_base_name}_wav.scp

#From test files listing at waves.test generates the labels 1-->YES & 0-->NO. List the correspondence between file ID and label in Output file test_yesno.txt
../../local/create_yesno_txt.pl waves.test > ${test_base_name}.txt

#From test files listing at waves.train generates the labels 1-->YES & 0-->NO. List the correspondence between file ID and label in Output file train_yesno.txt
../../local/create_yesno_txt.pl waves.train > ${train_base_name}.txt

#Copy task.arpabo file to data/local as lm_tg.arpa
cp ../../input/task.arpabo lm_tg.arpa

#Back to s5 directory
cd ../..

# This stage was copied from WSJ example

for x in train_yesno test_yesno; do 

  #Make the directories train_yesno and test_yesno under data
  mkdir -p data/$x

  #Copy the train_yesno_wav.scp, test_yesno_wav.scp to 
  #data/train_yesno and data/test_yesno folders respectively
  cp data/local/${x}_wav.scp data/$x/wav.scp

  #Copy the train_yesno.txt, test_yesno.txt to 
  #data/train_yesno and data/test_yesno folders respectively
  cp data/local/$x.txt data/$x/text

  #Sample utt2spk content after cat operation: 0_0_0_0_1_1_1_1 global
  cat data/$x/text | awk '{printf("%s global\n", $1);}' > data/$x/utt2spk
  
  #Mapping speakers to utterances
  utils/utt2spk_to_spk2utt.pl <data/$x/utt2spk >data/$x/spk2utt
done


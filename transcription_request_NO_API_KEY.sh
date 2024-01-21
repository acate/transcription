#!/usr/bin/bash

# transcription_request.sh
#
# Takes one input arg.: file name of audio to be transcribed
#   Must be one of flac, mp3, mp4, mpeg, mpga, m4a, ogg, wav, or webm.
#
# Outputs: text file (*.txt) where * is name of audio file (including extension)
#
# 2023-12-30 by adc

# Uses code from:
#   https://platform.openai.com/docs/api-reference/audio/createTranscription


# Define constants
#-----------------

OPENAI_API_KEY=[KEY GOES HERE, without brackets]

AUDIO_FILE=$1



# Clean up problematic characters in case they're present
outFileStr=$(echo $AUDIO_FILE | sed "s/'//g")
outFileStr=$(echo $outFileStr | sed 's/\?//g')

# Replace spaces with underscores
outFileStr=$(echo $outFileStr | sed 's/ /_/g')


# Function that makes request of openai using curl
#-------------------------------------------------

curl https://api.openai.com/v1/audio/transcriptions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: multipart/form-data" \
  -F file="@"$AUDIO_FILE \
  -F model="whisper-1" \
  -F response_format="text" \
  -o $outFileStr.txt
    







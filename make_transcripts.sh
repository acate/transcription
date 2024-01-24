#!/usr/bin/bash

# make_transcripts.sh
#
# Requires:
#
# -i followed by .mp3 input file name 
#
# Optional flags:
#
# -p  sPlit mp3 file into 10 minute chunks
# -t  Transcribe mp3 file(s) to txt file(s)
# -s  Summarize txt files
#       Requires summary type arg:
#       notes, points, paras, parasOrg, or parasSum

# begun 2024-01-23 by adc

#-----------------------------------
# System prompts for the llm command
#-----------------------------------

# These first two go together; they represent the two steps in making a summary of each paragraph of the transcript.

PROMPT_PARAS="Organize this transcript into paragraphs.  Do not change any of the words, only insert line breaks and empty lines between paragraphs"

PROMPT_SUMMARIZE_PARAS="Summarize each one of these paragraphs separately with one sentence each"


# These are the remaining two types of prompt

PROMPT_NOTES="Turn this college lecture transcript into a set of lecture notes, complete with section headings"

PROMPT_POINTS="Summarize the main points in this college lecture transcription, and then, below each main point, make a bulleted list of the evidence described for each point."




#--------------------------
# Read input argument flags
#--------------------------

# Set these variables to "false" here so that they can be set to "true" by an input argument
SPLIT_MP3_FLAG=false
TRANSCRIBE_FLAG=false

while test $# -gt 0; do
    case "$1" in
	-i)
	    shift
	    if test $# -gt 0; then
		export MP3_IN=$1
	    else
		echo "No mp3 file specified"
		exit 1
	    fi
	    shift
	    ;;
	-p)
	    export SPLIT_MP3_FLAG=true
	    shift
	    ;;
	-t)
	    export TRANSCRIBE_FLAG=true
	    shift
	    ;;	
	-s)
	    shift
	    if test $# -gt 0; then
		export PROMPT_TYPE=$1
	    else
		echo "No summary type specified"
		exit 1
	    fi
	    shift
	    ;;
	*)
	    break
	    ;;
    esac
done


#------------------------------------------------------
# Check whether necessary variables have been defined
# Test expression evaluates as true if var. NOT defined
#------------------------------------------------------

if [ -z ${MP3_IN+x} ]; then
    echo "Please add -i input_file.mp3 to the command"
    exit 1
fi



#--------------------------------------------------------
# Split large mp3 file into 10 minute chunks using ffmpeg
#   Because OpenAI's Whisper will only take files < 25 MB
#--------------------------------------------------------

if $SPLIT_MP3_FLAG; then

    # -segment_time arg is in seconds
    #
    # Can handle up to 100 chunks, so 1000 minutes = 16.66 hours
    #   before filenames cease to be unique

    ffmpeg -i $MP3_IN -f segment -segment_time 600 -c copy ${MP3_IN%.mp3}_%02d.mp3

fi



#------------------------------------------------------------------
# Run transcription_request.sh in a loop on all the 10-minute files
#------------------------------------------------------------------

if $TRANSCRIBE_FLAG; then

    for f in $(ls ${MP3_IN%.mp3}_*.mp3); do
	
	echo "Transcribing $f";

	transcription_request.sh $f
	
    done

fi

#-----------------------------------------------------------
# Analyze the transcript with chatGPT using the llm CLI tool
#-----------------------------------------------------------

# NOTE: NEED to have spaces separated the equals sign from the other characters around it!
# [ "a" = "b" ] is OK; [ "a"="b" ] is BAD, it will always eval. as true.

if [ "$PROMPT_TYPE" = "points" ]; then

    for f in $(ls ${MP3_IN%.mp3}_*.mp3.txt); do

	echo "Generating main points of $f";

	cat $f | llm -s "$PROMPT_POINTS" > ${f%.mp3.txt}_GPT_POINTS.txt 

    done

fi


if [ "$PROMPT_TYPE" = "notes" ]; then

    for f in $(ls ${MP3_IN%.mp3}_*.mp3.txt); do

	echo "Generating lecture notes from $f";

	cat $f | llm -s "$PROMPT_NOTES" > ${f%.mp3.txt}_GPT_NOTES.txt 

    done

fi





if [ "$PROMPT_TYPE" = "paras" ]; then

    for f in $(ls ${MP3_IN%.mp3}_*.mp3.txt); do

	echo "Organizing $f into paragraphs";

	cat $f | llm -s "$PROMPT_PARAS" > ${f%.mp3.txt}_GPT_PARAS.txt

    done

    
    for f in $(ls ${MP3_IN%.mp3}_*_GPT_PARAS.txt); do

	echo "Summarizing each paragraph of $f ";

	cat $f | llm -s "$PROMPT_SUMMARIZE_PARAS" > ${f%.txt}_SUMMARY.txt

    done
    

fi


# If want to organize into paragraphs ONLY

if [ "$PROMPT_TYPE" = "parasOrg" ]; then

    for f in $(ls ${MP3_IN%.mp3}_*.mp3.txt); do

	echo "Organizing $f into paragraphs";

	cat $f | llm -s "$PROMPT_PARAS" > ${f%.mp3.txt}_GPT_PARAS.txt

    done

fi




# If want to REDO the paragraph summaries only, not the organizing into paragraphs

if [ "$PROMPT_TYPE" = "parasSum" ]; then

    for f in $(ls ${MP3_IN%.mp3}_*_GPT_PARAS.txt); do

	echo "Summarizing each paragraph of $f ";

	cat $f | llm -s "$PROMPT_SUMMARIZE_PARAS" > ${f%.txt}_SUMMARY.txt

    done
    

fi














############################
# UNUSED CODE
############################

# Will have no trailing /
#THIS_DIR=$(pwd)

#------------------------------------------------
# Count number of files made by the splitting up
#------------------------------------------------

#n_split=$(echo "$(ls $THIS_DIR/${MP3_IN%.mp3}_*.mp3)" | wc | gawk '{print $2}')
#echo $n_split

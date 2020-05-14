#!/bin/bash

goodaudio=("5.1" "6.1" "7.1" "6 channels")

PARAMS=""
while (( "$#" )); do
	case "$1" in
		-h|--help)
			echo -e "Video Audio Checking Tool by MrChip53\n\nThis tool checks video files for certain audio types.\nIf they do not match it logs them.\n\nUsage: scan_movie_audio.sh MOVIE_PATH [OPTIONS]\n\n-h|--help\t-\tThis menu.\n \
				\n-a|--allowed-audio\t-\tAllowed audio types"
			exit
			;;
		-a|--allowed-audio)
			if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
				customaudio=$2
				if grep -q ","<<<$customaudio;
				then
					IFS=',' read -ra goodaudio <<< "$customaudio"
				else
					goodaudio=($customaudio)
				fi
				shift 2
			else
				echo "Error: Argument for $1 is missing" >&2
				exit 1
			fi
			;;
		-*|--*=) # unsupported flags
			echo "Error: Unsupported flag $1" >&2
			exit 1
			;;
		*) # preserve positional arguments
			PARAMS="$PARAMS $1"
			shift
			;;
	esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

if [ ! -d "${PARAMS:1}" ]; then
	echo "${PARAMS:1} directory does not exist!"
	exit 1
fi

rm -f movie_audio.txt

allmovies=()

while IFS= read -r -d '' line; do 
	allmovies+=( "$line" )
done < <(find ${PARAMS:1} -type f -print0)

echo "Totsl Movies: ${#allmovies[@]}";

for ((i = 0; i < ${#allmovies[@]}; i++))
do
	movienum=$(($i+1))
	moviestat="$movienum/${#allmovies[@]}";
	moviestatlen=${#moviestat}

	progressbar=""

	numofhash=$(($i / ${#allmovies[@]}))
	cols=$(tput cols)
	for ((i2 = 0; i2 < cols - moviestatlen - 3; i2++))
	do
		if [ $i2 -le $numofhash ]
		then
			progressbar="${progressbar}#"
		else
			progressbar="${progressbar} "
		fi
	done
	echo -ne "[$progressbar] $moviestat\r"
	sleep 2
	hb_out=$(HandBrakeCLI -i "${allmovies[$i]}" --scan 2>&1 | grep Audio:)
	#echo "$hb_out";

	has_good_audio=0
	for val in "${goodaudio[@]}"
	do
		if grep -q "$val"<<<$hb_out;
		then
			has_good_audio=1
		fi
	done

	if [ $has_good_audio -eq 0 ]
	then
		echo -e "${allmovies[$i]} FAILED:\n$hb_out\n\n" >> movie_audio.txt
	fi

done

echo "Done scanning";

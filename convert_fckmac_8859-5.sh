#!/bin/bash

#Get path to file using arg -p [path]
while getopts ":p:" opt; do
	case $opt in
	    p)
		    path=$OPTARG >&2
		    ;;
        \?)
		    echo "Invalid option $OPTARG" >&2
		    exit 1
		    ;;
	    :)
		    echo "Option $OPTARG requires an rgument"
		    exit 1
		    ;;
	esac
done

#Ddictionaries
list_of_fck_hex=("41" "61" "42" "62" "56" 
				  "76" "48" "68" "44" "64" 
				  "45" "65" "E4" "AB" "F3" 
				  "BD" "5A" "7A" "59" "79" 
				  "49" "69" "81" "5D" "4A" 
				  "6A" "4B" "6B" "4C" "6C" 
				  "4D" "6D" "4E" "6E" "4F" 
				  "6F" "50" "70" "52" "72" 
				  "53" "73" "54" "74" "55" 
				  "75" "46" "66" "58" "78" 
				  "43" "63" "82" "8D" "EA" 
				  "A7" "57" "77" "51" "71" 
				  "7B" "5B" "81" "8C" "C7"
				  "C8")

list_of_8859_hex=("B0" "D0" "B1" "D1" "B2" 
				  "D2" "B3" "D3" "B4" "D4" 
				  "B5" "D5" "A4" "F4" "B6" 
				  "D6" "B7" "D7" "B8" "D8" 
				  "A6" "F6" "A7" "F7" "B9" 
				  "D9" "BA" "DA" "BB" "DB" 
				  "BC" "DC" "BD" "DD" "BE" 
				  "DE" "BF" "DF" "C0" "E0" 
				  "C1" "E1" "C2" "E2" "C3" 
				  "E3" "C4" "E4" "C5" "E5" 
			 	  "C6" "E6" "C7" "E7" "C8" 
				  "E8" "C9" "E9" "CC" "EC" 
				  "CE" "EE" "CF" "EF" "3C"
				  "3E")

list_of_file_hex=($(xxd -u -c 1 -p $path))
new_list_of_file_hex=("${list_of_file_hex[@]}")

#Encoding
for i in "${!list_of_file_hex[@]}"; do
	for j in "${!list_of_fck_hex[@]}"; do	
		if [ "${list_of_file_hex[$i]}" == "${list_of_fck_hex[$j]}" ]; then
			new_list_of_file_hex[$i]="${list_of_8859_hex[$j]}"
			echo "${list_of_file_hex[$i]} -- ${list_of_fck_hex[$j]}" 
		fi
	done
done

#Writing in file
new_file_in_hex=$( printf "x%s" "${new_list_of_file_hex[@]}" )
new_file_in_hex=$( echo "$new_file_in_hex" | sed 's/x/\\x/g' )
echo -e -n "$new_file_in_hex" > $path"dec"


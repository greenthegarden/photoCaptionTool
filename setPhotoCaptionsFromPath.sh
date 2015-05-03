#!/usr/bin/env sh

######
#
# shell script to add captions to a selected set of photographs, where the
# photographs to be captioned are specified in a csv file.
#
# Script requires imagemagick 'caption' routine to produce captions
#
# get a list of files with full paths using
# find $PWD -type f -name "*.jpg"
#
# photo directories are labelled as
# YYYY-MM-DD_trip-label_event-label
# extract event-label and use as caption
#
# the file database is a csv file with three, or four, columns
# optional fourth column can be used to specify a caption
# first column set to non zero value if photo to be captioned and used as a rating
# second column is the full filename of pictures (generated using method above)
# third column is the location used in caption
# fourth column is optional caption
# fifth column is optional list of keywords for photograph (semi-colon separated)
# sixth column is optional list of people in photograph (semi-colon separated)
# i.e.
# rating, full-file-path, location, (caption), (keyword1; keyword2), (name1; name2),
#
# For example:
#
# 1,/Users/family/Pictures/vietnam-2014-trip/2014-10-23_hoi-an_river-in-hoi-an/034-IMG_7539.jpg,Vietnam
# 0,/Users/family/Pictures/vietnam-2014-trip/2014-10-23_hoi-an_river-and-lake/035-IMG_7540.jpg,Vietnam
# 1,/Users/family/Pictures/vietnam-2014-trip/2014-10-23_hoi-an_river-in-flood/036-IMG_7437.jpg,Vietnam,Danger! River in Flood
#
# First image will be captioned with "River In Hoi An, Vietnam" and saved to ${output_dir}/034-IMG_7539_captioned.jpg
# Second image will not be captioned (not processed)
# Third image will be captioned with "Danger! River in Flood, Vietnam" and saved to ${output_dir}/034-IMG_7539_captioned.jpg
#
######


# function to remove leading and trailing whitespace from a variable
# source for trim:
# http://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-bash-variable
trimmed=""
trim() {
    local var="$@"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
#    echo -n "$var"
    trimmed="${var}"
}

cleaned=""
cleanup() {
	local var="$@"
	# replace hyphens with spaces
	var=${var//-/ }
	# capitalise first letter
	var="$(tr '[:lower:]' '[:upper:]' <<< ${var:0:1})${var:1}"
	# capitalise first letter of each word
	var=$( echo "${var}" | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
#    echo -n "${var}"
	cleaned="$var"
}

textsize=128
textpadding=16

# the output_dir variable should be set as an input variable else
#output_dir="/Users/family/Pictures/vietnam/captions/"
#output_dir="/Users/family/Pictures/christmas2014/captioned/"
output_dir="/Volumes/CVFAMPICS/vietnam/captioned/"
#output_dir="/Volumes/CVFAMPICS/cairns-caravan-trip/captioned/"

# TO DO: convert to using command line variables
caption_filename="$1"

echo "Using captions from file ${caption_filename}"

#height=$(expr ${textsize} + 2 \* ${textpadding})

#event_caption=""

while IFS=, read col1 col2 col3 col4 col5 col6
do
	# col1 is picture rating. Only process picture if rating is greater than 0
	trim "${col1}";
	caption_picture="${trimmed}";

	# col3 is the location caption. Get is here to add it as a keyword
	trim "${col3}";
	if [ ${#trimmed} -gt 0 ] ;
	then
		location_caption="${trimmed}";
		echo "location_caption is ${location_caption}"
	fi

	# col5 is list of keywords, separated by semi-colons
	trim "${col5}"
	if [ ${#trimmed} -gt 0 ] ;
	then
		IFS=';' read -a keywords_array <<< "${trimmed}"
		keywords_array=(${keywords_array[@]} ${location_caption})
		echo "keywords: ${keywords_array[@]}"
	fi

	# col6 is list of people, separated by semi-colons
	trim "${col6}"
	if [ ${#trimmed} -gt 0 ] ;
	then
		IFS=';' read -a people_array <<< "${trimmed}"
		echo "people: ${people_array[@]}"
	fi

	if [ "${caption_picture}" -gt 0 ] ;
	then

		trim "${col2}"
		photo_fullpath_filename="${trimmed}";

		# only continue processing if file exists and is readable
		if [ -r "${photo_fullpath_filename}" ] ;
		then

			echo "photo_fullpath_filename: ${photo_fullpath_filename}"

			# process path to extract caption
			IFS='/' read -a filename_array <<< "${photo_fullpath_filename}"

			# get filename for when saving image
			idx=$(expr ${#filename_array[@]} - 1)
			filename="${filename_array[$idx]}"

			# check if a caption was specified otherwise extract from filename
			trim "${col4}";
			if [ ${#trimmed} -gt 0 ] ;
			then

				event_caption="${trimmed}"
				echo "event_caption (from db) is ${event_caption}"

			else

				# want the information in the second to last element (file directory)
				idx=$(expr ${#filename_array[@]} - 2)
				echo "info: ${filename_array[$idx]}"

				date_str=""
				trip_label=""
				location_label=""
				event_label=""

				# again store data in array
				IFS='_' read -a info_array <<< "${filename_array[$idx]}"

				# extract elements of directory label
				idx=0
				while [ $idx -lt ${#info_array[@]} ]
				do
					if [ $idx -eq 0 ] ; then
					  date_str=${info_array[$idx]}
					elif [ $idx -eq 1 ] ; then
					  trip_label=${info_array[$idx]}
					elif [ $idx -eq 2 ] ; then
					  location_label=${info_array[$idx]}
					elif [ $idx -eq 3 ] ; then
					  event_label=${info_array[$idx]}
					fi
					((idx++))
				done

				echo "date_str is ${date_str}"
				echo "trip_label is ${trip_label}"
				echo "location_label is ${location_label}"

				cleanup "${location_label}"
				location_label="${cleaned}"

				# add location_label to event_label to create event_caption
				if  [ ${#event_label} -gt 0 ] ;
				then
					echo "event_label is ${event_label}"
					# replace hyphens with spaces
					cleanup "${event_label}"
					event_caption="${cleaned} in ${location_label}"
				else
					event_caption="${location_label}"
				fi

				echo "event_caption (from directory) is ${event_caption}"
			fi

			# create caption
			if [ -n "${location_caption+1}" ] ;
			then
  				caption="${event_caption}, ${location_caption}"
			else
  				caption="${event_caption}"
			fi
#			caption="${event_caption}, ${location_caption}"
			echo "caption: ${caption}"

			# check caption length and adjust height of textbox if necessary
			# for landscape, 4000px, max number of characters is ??
			# for portrait, 3000px, max number of characters is 46
			caption_length=${#caption}
			image_width=`identify -format %w "${photo_fullpath_filename}"`;
			if [ "${image_width}" -lt 3001 ] ;
			then
				max_char=48
			elif [ "${image_width}" -lt 4001 ] ;
			then
				max_char=64
			fi
			echo "image_width = ${image_width}, caption_length = ${caption_length}, max_char = ${max_char}"
			text_rows=$(expr ${caption_length} / ${max_char} + 1)
			height=$[ ${text_rows} * ( ${textsize} + ${textpadding} ) + ${textpadding} ]
			echo "text_rows = ${text_rows}, height = ${height}"

			# ensure filename is lowercase
			filename=$( echo "${filename}" | tr '[:upper:]' '[:lower:]' )

			ofile="${output_dir}${filename%.jpg}_captioned.jpg"
			echo "outfile is: ${ofile}"

#			width=`identify -format %w "${photo_fullpath_filename}"`;

			convert -background '#0008' \
				-fill white \
				-gravity center \
				-size ${image_width}x${height} \
				-pointsize ${textsize} \
				caption:"${caption}" \
				"${photo_fullpath_filename}" +swap -gravity south -composite "${ofile}"

		else	# infile does not exist or not writable

			echo "infile ${photo_fullpath_filename} not found!!"

		fi	# end if picture file exists

	fi	# end if caption_picture

done < "${caption_filename}"

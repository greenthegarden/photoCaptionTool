#!/usr/bin/env bash

input_dir="/Volumes/CVFAMPICS/vietnam/"
output_dir="/Volumes/CVFAMPICS/vietnam/captioned/"

trimmed=""

#source for trim: http://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-bash-variable
trim() {
    local var="$@"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
#    echo -n "$var"
    trimmed="${var}"
}

#get caption from directory name
# caption_from_path() {
# 	local var="$@"
# 	var=
# }

caption_filename="$1"

echo "Using captions from file ${caption_filename}"

textsize=128
textfill=16
height=$(expr ${textsize} + 2 \* ${textfill})
echo "captionsize is ${captionsize}"

while IFS=, read col1 col2 col3 col4
do
	trim "${col1}";
	photo_filename="${trimmed}";
	trim "${col2}";
	event_caption="${trimmed}";
	trim "${col3}";
	picture_caption="${trimmed}";
	trim "${col4}";
	location_caption="${trimmed}";

	ifile="${input_dir}${photo_filename}"

	if [ -f ${ifile} ] ; then
		echo "infile is: ${ifile}"
#    	caption="${event_caption}: ${picture_caption}, ${location_caption}"
		caption="${picture_caption}, ${location_caption}"
		echo "caption is: ${caption}"
		ofile="${output_dir}${photo_filename%.jpg}_captioned.jpg"
		echo "outfile is: ${ofile}"

		width=`identify -format %w ${ifile}`;

		convert -background '#0008' \
			-fill white \
			-gravity center \
			-size ${width}x${height} \
			-pointsize ${textsize} \
			caption:"${caption}" \
			${ifile} +swap -gravity south -composite ${ofile}

	else
		echo "infile ${ifile} not found!!"

	fi


done < "${caption_filename}"

#!/bin/sh
#mogrify -format png *.jpg
#rm *.jpg

#mogrify -format png *.jpeg
#rm *.jpeg

for f in $(find . -name '*@2x.png'); do
    echo "Converting $f..."
	if [ -f $(basename -s '@2x.png' $f).png ]
	then
		echo "Removing $(basename -s '@2x.png' $f).png..."
		rm $(basename -s '@2x.png' $f).png
	fi 
    convert "$f" -resize '50%' "$(dirname $f)/$(basename -s '@2x.png' $f).png"
done

for f in $(find . -name '*@2x.jpg'); do
    echo "Converting $f..."
	if [ -f $(basename -s '@2x.jpg' $f).jpg ]
	then
		echo "Removing $(basename -s '@2x.jpg' $f).jpg..."
		rm $(basename -s '@2x.jpg' $f).jpg
	fi 
    convert "$f" -resize '50%' "$(dirname $f)/$(basename -s '@2x.jpg' $f).jpg"
done
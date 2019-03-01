#!/bin/bash
#Establish Variables
#Pull Variables from Asterisk, comment out if you want to test with local files.
while read VAR && [ -n ${VAR} ] ; do : ; done
#Create array for the list of names to send to google.
nameswhitelist=("")
#Set the directory and file location for the storage of files.
asteriskinput="$1"
directory="/tmp/"
KEY="" #place your google api key in here
FILENAME="$directory""$asteriskinput"".json"
wavloc="$directory""$asteriskinput"".wav"
thisfilebase="$directory""$asteriskinput"".base64"
thisfiletranscript="$directory""$asteriskinput"".txt"
wavloc1="$directory""$asteriskinput""boosted.wav"

#We put the input through sox inorder to normalise the volume. Then save the output
sox $wavloc $wavloc1 gain -n

#get dictionary from mysql for acceptable names and store to a list. It pulls these from the user1 table of names.
mapfile nameswhitelist < <(mysql -uroot foxdex -ss -N -e "SELECT name FROM user1;")
#then we filter out all the boring stuff that makes it readable to us mortals.
namesfinallist=$(echo $(printf '\"%s\", ' "${nameswhitelist[@]}") | sed -r 's/ ",/",/g;s/.$//')

#Generate a JSON for the google api. It lets you suggest phrases so we push the dictionary of names we created earlier and boost the results. We also set the amount of max alternatives to 4. By doing this we recieve 4 suggestions instead of just 1. Saving the end user time.
cat <<EOF > $FILENAME
{
  "config": {
    "encoding":"ENCODING_UNSPECIFIED",
    "sampleRateHertz": 8000,
    "profanityFilter": true,
    "languageCode": "en-US",
    "speechContexts": {
      "phrases": [ $namesfinallist ]
    },
    "maxAlternatives": 4
  },
  "audio": {
    "content":
	}
}
EOF
#now that we have a base json request we can convert our sound to base64 and send it to the json as well.
echo \"$(base64 -w 0 "$wavloc1")\" > "$thisfilebase"
sed -i "$FILENAME" -e "/\"content\":/r $thisfilebase"
#query and store response to variable
returneddata=$(curl -s -X POST -H "Content-Type: application/json" --data-binary @${FILENAME} https://speech.googleapis.com/v1/speech:recognize?key=$KEY)
#Save response variable to file for future testing. 
echo "$returneddata" > "$thisfiletranscript"
FILTERED=$returneddata
#find quantity of results try each of them once againt to mysql for a hit.  
tLen=${#FILTERED[@]}
for (( i=0; i<${tLen}; i++ ));
do
  #filter out everything so we only have the text. 
  testingname=$(cat $thisfiletranscript | jq .results[0].alternatives[$i].transcript)
  if [ -z "$testingname" ] #if the text is blank then do nothing and move on. 
  then 
     :
  else
     num2call=$(mysql -uroot foxdex -ss -N -e "SELECT user1.out FROM user1 where name LIKE $testingname") #if the number doesnt exist we store it in the db of failed transcripts and then move on to the next one. 
     if [ -z "$num2call" ]
     then 
        mysql -uroot foxdex -ss -N -e "INSERT INTO usernotfound (usernotfoundutterance) VALUES ($testingname);"
     else
        rm -f /tmp/$asteriskinput.*
        #if it does exist then we delete all the files related and exit. 
        i=${tLen}
     fi
  fi
done
echo "SET VARIABLE PTY2CALL "\""$nameout"\"""
echo "SET VARIABLE NUM2CALL "\""$num2call"\"""




# FoxDex - Asterisk Voice To Text
A Voice to Text System for asterisk that utilizes Google's voice to text api. 
# Prerequisites
There are a few requirements before you can get this running. This system was tested and running on freepbx
First you must make sure you have the following installed, most operating systems come with these:
```
apt-get install sox
apt-get install jq
apt-get install mapfile
```

Once those are installed you can place the ``` foxdex.sh ``` file in your agi-scripts folder and make your dialplan look something like this:

```
[foxdex]				
;# // BEGIN Call by Name        
exten => 411,1,Answer
exten => 411,n,Background(custom/411short)
exten => 411,n,Set(RANDFILE=${RAND(8000,8599)})
exten => 411,n,Record(/tmp/${RANDFILE}.wav,2,4)
exten => 411,n,AGI(foxdex.sh,${RANDFILE})
exten => 411,n,NoOp(Party to call : ${PTY2CALL})
exten => 411,n,NoOp(Number to call: ${NUM2CALL})
exten => 411,n,GotoIf($["${NUM2CALL}" != ""]?dial)
exten => 411,n(dial),Dial(local/${NUM2CALL})
exten => 411,n,Hangup()
```
A more exact breakdown of the dialplan can be found in the wiki, but the tldr is that you want it to answer and play a noise so the user knows to talk. Then it creates a random file name and and records for 4 seconds max and stores it to a wav. After that it checks through the script if that name is there. If the returned value isnt blank then it dials. Since the average application for this is a virtual assistant, we just have it forward to a local extension. 

After that you will need to setup the mysql database. Just create a database by restoring the provided mysql file. This will create two tables. The table names user1 is where you keep all your users and their extensions. The second table is where it stores the failed transcripts, these are incredibly useful for improving recognition in more niche names. 

Finally you need to setup a google api account. It's free for the first year. We are just using the google text to speech api. Once you have an api key place it in the ``` foxdex.sh ``` file that you placed in your agi-bin folder. 

# Usage
call the extension that you set your dialplan to use and it should work. 
Feel free to donate if you like it:
paypal.me/foximler

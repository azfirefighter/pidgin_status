#!/bin/bash

#screen=`env|grep DISPLAY`
screen="DISPLAY=:0.0"

egrep "DTSTART|DTEND|SUMMARY|STATUS" ~/.thunderbird/Work.ics > /tmp/cleaned

# remove old at jobs
for i in `atq|awk '{print $1}'`
do
   atrm $i
done

while read -r line
do
   summary=`echo $line | tr -d '\r' | grep SUMMARY:`
   if [ "$summary" != "" ]
   then
      summary=`echo $line | tr -d '\r' | cut -d: -f2-`
      summary=`echo "$summary" | sed 's/\"/\\\"/g'`

      read line
      status=`echo $line | tr -d '\r' | cut -d: -f2-`

      read line
      TZ=`echo $line | cut -d= -f2| cut -d: -f1`
      startDay=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f1`
      startDay=`date -d "$startDay" +%m/%d/%y`
      startHour=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f2 | cut -c1-2`
      startMin=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f2 | cut -c3-4`
      startTime=`date --date="TZ=\"$TZ\" $startHour:$startMin" | awk '{print $4}' | cut -d: -f1,2` 
    
      read line
      endDay=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f1`
      endDay=`date -d "$endDay" +%m/%d/%y`
      endTime=`echo $line | tr -d '\r' | cut -d: -f2- | cut -dT -f2 | cut -c1-4`
      endTime=`date --date="TZ=\"$TZ\" $endTime" | awk '{print $4}' | cut -d: -f1,2`
      endTime=`date -d "$endTime 1 min ago" +%R`

      if [ "$status" != "CANCELED" ] 
      then
         # Add new at jobs
         echo "export $screen;/usr/bin/purple-remote setstatus?status=extended_away;/usr/bin/purple-remote setstatus?message=\"$summary\"  | at $startTime $startDay"
         echo "export $screen;/usr/bin/purple-remote setstatus?status=extended_away;/usr/bin/purple-remote setstatus?message=\"$summary\"" | at $startTime $startDay
         echo "export $screen;/usr/bin/purple-remote setstatus?status=available;/usr/bin/purple-remote setstatus?message=" | at $endTime $endDay
      fi
   fi
done < /tmp/cleaned
rm /tmp/cleaned

minute=`date|cut -d: -f2`
if [ `expr $minute % 5` -eq 0 ]
then
   echo "/home/phic/Documents/pidgin_status.sh" | at now + 4 minutes
else
   echo "/home/phic/Documents/pidgin_status.sh" | at now + 5 minutes
fi

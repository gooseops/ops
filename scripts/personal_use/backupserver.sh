#!/bin/bash

killall -w java || echo "No java running"
unset NUMBER
unset BACKUP_OLDEST
unset BACKUP_TOTAL
cp -r /home/$USER/mc/ "/mnt/network/share/$USER/backup_$(date +%s)"
cd /home/$USER/mc/
NUMBER=$(curl https://papermc.io/api/v2/projects/paper/versions/1.18.2/ | grep -o '[0-9]*' | sort -nr | head -1)
echo $NUMBER
curl -o server.jar https://papermc.io/api/v2/projects/paper/versions/1.18.2/builds/"$NUMBER"/downloads/paper-1.18.2-"$NUMBER".jar
BACKUP_OLDEST=$(ls /mnt/network/share/$USER/ | head -1)
BACKUP_TOTAL=$(ls -l /mnt/network/share/$USER | grep -c ^d )
echo $BACKUP_OLDEST
echo $BACKUP_TOTAL
until [ $BACKUP_TOTAL -le 5 ]
do
    rm -r /mnt/network/share/$USER/$BACKUP_OLDEST
    BACKUP_TOTAL=$(ls -l /mnt/network/share/$USER | grep -c ^d )
    BACKUP_OLDEST=$(ls /mnt/network/share/$USER/ | head -1)
    echo $BACKUP_TOTAL
    echo $BACKUP_OLDEST
done
if [[ ! -e eula.txt ]];
then
    echo "eula=true" >> eula.txt
fi
java -Xmx4092M -Xms1024M -jar server.jar nogui

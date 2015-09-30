#!/bin/bash

text1="Found "
text2=" unique IP addresses"
text3="Your IP address is: "

#Delete old files
rm -f ~/.ufwip.blocked > /dev/null
rm -f ~/.ufwip.blocked.rd  > /dev/null
rm -f ~/.ufwip.blocked.old  > /dev/null

#Get the DROPED  connections from syslog
sudo cat /var/log/syslog | grep --color -ohE "UFW BLOCK|SRC=\w*.\w*.\w*.\w*" > ~/.syslogufw.blocked


#Remove lines with unwanted contents
sed '/UFW BLOCK/d' ~/.syslogufw.blocked &> /dev/null
sed '/BLOCK/d' ~/.syslogufw.blocked &> /dev/null

#Remove "SRC="
cut ~/.syslogufw.blocked -c5- | cat > ~/.ufwip.blocked
rm -f ~/.syslogufw.blocked

#Remove duplicates
awk '!a[$0]++' ~/.ufwip.blocked > ~/.ufwip.blocked.rd

#Sort
sort -k +39 ~/.ufwip.blocked.rd > ~/.ufwip.blocked

#Show DROPPED connectrions from iptables
sudo iptables -L -vn | grep --color DROP

#Count unique IPs in blocked list
ipcounter=$(wc -l ~/.ufwip.blocked | grep -Eo '^[^ ]+')
myip=$(echo $SSH_CLIENT | awk '{ print $1}')

#Display
echo -e "\n$text1\e[31m$ipcounter\e[0m$text2"
echo -e "\n$text3\e[31m$myip\e[0m\n"
cat ~/.ufwip.blocked | column

#If your current connection IP is/was blocked from UFW this will activate
if grep -Fxq $myip ~/.ufwip.blocked
then
        echo -e "\nYour current local IP address was \e[31mBLOCKED\e[0m from UFW"
        echo -e "Use \"\x1b[4msudo ufw allow from $myip\x1b[0m\" to unblock it"
fi

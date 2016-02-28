#!/bin/bash
ls dataInput.txt
if [ $? == 0 ]
then
echo "file present"
input="/root/dataInput.txt"
while IFS= read -r var
do
date >> autolog.txt
$var
echo $var "<------RC code------>" $? >> autolog.txt
done < "$input"
else
echo $?
echo "file not present"
fi

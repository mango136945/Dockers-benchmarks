#!/bin/bash

#change backend
backendArr=(overlay devicemapper vfs)
postArr="1"
bws="1"
iopss="1"
runts="1"
slatAvgs="1"
clatAvgs="1"

for i in "${backendArr[@]}"
do
echo $i
backend=$i
dateTime=`date +'%d/%m/%Y %H:%M:%S:%3N'`
sed -i '7s/.*/DOCKER_OPTS=\"--storage-driver='"${backend}"'\"/' /etc/default/docker
#restart docker
service docker restart
#get the container Id
containerId=`docker ps -a | awk '{print $1}' | grep -v 'CONT'`
echo $containerId
readWrite=$2
size=$3
bs=$4
fileName=$backend-$readWrite-$bs
#start docker
docker start $containerId

#run command inside docker
docker exec $containerId bash -c "fio --name=rw --ioengine=libaio --iodepth=1 --rw=$readWrite --bs=$bs --direct=0 --size=$size --numjobs=6 --rwmixread=75 -group_reporting > $fileName;exit"
docker exec $containerId bash -c "rm rw*;exit"
#get the log file from docker
docker cp $containerId:/$fileName  /
FILE=/$fileName

if [ $readWrite == "read" -o $readWrite == "randread" ]
then
        bw=`cat $FILE | grep iops | awk '{print $4}' |  awk -F "=" '{print $2}' | awk -F "K" '{print $1}' | awk -F "M" '{print $1}'`
        iops=`cat $FILE | grep iops | awk '{print $5}' | awk -F "=" '{print $2}' | awk -F "," '{print $1}' | awk -F "K" '{print $1}'`
        runt=`cat $FILE | grep iops | awk '{print $7}' | awk -F "m" '{print $1}'`
        slatAvg=`cat $FILE | grep slat | awk '{print $6}' | awk -F "," '{print $1}' | awk -F "=" '{print $2}'`
        clatAvg=`cat $FILE | grep clat | awk '{print $6}' | awk -F "," '{print $1}' | head -1`
        echo $FILE
        postData=`echo -e "{\"command\":\""read"\", \"bw\":\""$bw"\", \"iops\":\""$iops"\", \"runt\":\""$runt"\", \"slatAvg\":\""$slatAvg"\", \"clatAvg\":\""$clatAvg"\", \"@timestamp\":\""$dateTime"\" }"`
        echo $postData
elif [ $readWrite == "write" -o $readWrite == "randwrite" ]
then
        runt=`cat $FILE | grep iops | awk '{print $6}' | awk -F "m" '{print $1}'`
        if  [ -z "$runt" ]
        then
                runt=`cat $FILE | grep iops | awk '{print $5}' | awk -F "=" '{print $2}' |  awk -F "m" '{print $1}'`
        fi
        iops=`cat $FILE | grep iops | awk '{print $4}' | awk -F "=" '{print $2}' | awk -F "," '{print $1}' | awk -F "K" '{print $1}'`
        bw=`cat $FILE | grep iops | awk '{print $3}' |  awk -F "=" '{print $2}' | awk -F "M" '{print $1}' |  awk -F "K" '{print $1}'`
        slatAvg=`cat $FILE | grep slat | awk '{print $6}' |  awk -F "," '{print $1}' | awk -F "=" '{print $2}'`
        clatAvg=`cat $FILE | grep clat | awk '{print $6}' | awk -F "," '{print $1}' | head -1`
        echo "write"
        postData=`echo -e "{\"command\":\""write"\",\"bw\":\""$bw"\", \"iops\":\""$iops"\", \"runt\":\""$runt"\", \"slatAvg\":\""$slatAvg"\", \"clatAvg\":\""$clatAvg"\", \"@timestamp\":\""$dateTime"\" }"`
        echo $postData
else
        runtRead=`cat $FILE | grep iops | awk '{print $7}' | head -1`
        runtWrite=`cat $FILE | grep iops | awk '{print $6}' | tail -1`
        iopsRead=`cat $FILE | grep iops | awk '{print $5}' | awk -F "=" '{print $2}' | awk -F "," '{print $1}' | head -1`
        iopsWrite=`cat $FILE | grep iops | awk '{print $4}' | awk -F "=" '{print $2}' | awk -F "," '{print $1}' | tail -1`
        bwRead=`cat $FILE | grep iops | awk '{print $4}' |  awk -F "=" '{print $2}' | awk -F "M" '{print $1}' | awk -F "K" '{print $1}' | head -1`
        bwWrite=`cat $FILE | grep iops | awk '{print $3}' |  awk -F "=" '{print $2}' | awk -F "M" '{print $1}' | awk -F "K" '{print $1}' | tail -1`
        slatAvgRead=`cat $FILE | grep slat | awk -F "avg" '{print $2}' |  awk -F "=" '{print $2}' |  awk -F "," '{print $1}' |  awk -F " " '{print $1}' |  head -1`
        slatAvgWrite=`cat $FILE | grep slat | awk -F "avg" '{print $2}' |  awk -F "=" '{print $2}' |  awk -F "," '{print $1}' |  awk -F " " '{print $1}' |  tail -1`
        clatAvgRead=`cat $FILE | grep clat | awk '{print $6}' | awk -F "," '{print $1}' | head -1`
        clatAvgWrite=`cat $FILE | grep clat | awk '{print $6}' | awk -F "," '{print $1}' | tail -2 | head -1`
        echo $runtRead $runtWrite $iopsRead $iopsWrite $bwRead $bwWrite $slatAvgRead $slatAvgWrite $clatAvgRead $clatAvgWrite
        postData=`echo -e "{\"command\":\""readwrite"\", \"runtRead\":\""$runtRead"\", \"runtWrite\":\""$runtWrite"\", \"iopsRead\":\""$iopsRead"\", \"iopsWrite\":\""$iopsWrite"\", \"bwRead\":\""$bwRead"\", \"bwWrite\":\""$bwWrite"\", \"slatAvgRead\":\""$slatAvgRead"\", \"slatAvgWrite\":\""$slatAvgWrite"\", \"clatAvgRead\":\""$clatAvgRead"\", \"clatAvgWrite\":\""$clatAvgWrite"\", \"@timestamp\":\""$dateTime"\"}"`
fi
if [ "$postArr" == 1 ]
        then
                postArr="$postData"
        else
                postArr="$postArr,$postData"
        fi

if [ $readWrite == "read" -o $readWrite == "write" -o  $readWrite == "randread" -o $readWrite == "randwrite" ]
then
        #sed -i '22s/.*/data.addRows\(\[\[\"aufs\", '"$bw"'\],\[\"vfs\", 1500\],\[\"devicemapper\", 3000\]\]\)\;/' ./index.html
#       sed -i '7s/.*/DOCKER_OPTS=\"--storage-driver='"${backend}"'\"/' /etc/default/docker
        if [ "$bws" == "1" ]
        then
                echo $bw
                bws="[\'$backend\', $bw]"
        else
                echo $bw
                bws="$bws, [\'$backend\', $bw]"
        fi
		        if [ "$iopss" == "1" ]
        then
                iopss="[\'$backend\', $iops]"
        else
                iopss="$iopss, [\'$backend\', $iops]"
        fi

        if [ "$runts" == "1" ]
        then
                runts="[\'$backend\', $runt]"
        else
                runts="$runts, [\'$backend\', $runt]"
        fi
        if [ "$slatAvgs" == "1" ]
        then
                slatAvgs="[\'$backend\', $slatAvg]"
        else
                slatAvgs="$slatAvgs, [\'$backend\', $slatAvg]"
        fi
        if [ "$clatAvgs" == "1" ]
        then
                clatAvgs="[\'$backend\', $clatAvg]"
        else
                clatAvgs="$clatAvgs, [\'$backend\', $clatAvg]"
        fi
fi

done
        postArr="{\"object\":[$postArr]}"
        bws="([$bws]);"
        iopss="([$iopss]);"
        runts="([$runts]);"
        slatAvgs="([$slatAvgs]);"
        clatAvgs="([$clatAvgs]);"

        sed -i '22s/.*/data.addRows'"$bws"'/' /index.html
        sed -i '27s/.*/data2.addRows'"$iopss"'/' /index.html
        sed -i '32s/.*/data3.addRows'"$runts"'/' /index.html
        sed -i '37s/.*/data4.addRows'"$slatAvgs"'/' /index.html
        sed -i '42s/.*/data5.addRows'"$clatAvgs"'/' /index.html
        chmod 777 /index.html
#update index file

echo $postArr >> doc.json
echo curl -H "Content-Type: application/json" -X POST -d \'"$postArr"\' http://54.153.5.190:9200/docker/docker
#curl -H "Content-Type: application/json" -X POST -d \'"$postArr"\' http://54.153.5.190:9200/docker/docker
#curl -X POST "http://54.153.5.190:9200/docker/docker" --data-binary @doc.json
if [ $? == 0 ]
then
echo "removing doc.json file"
rm doc.json
else
echo "Fail CURL cmd-- RC --->" $?
fi
                                                          

#!/bin/bash

helper() {
    echo
    echo "Examples:"
    echo "# bash image-exporter.bash [DATA_LIST_PATH] [OUTPUT_PATH?]"
    echo
}

if [ -z "$1" ]; then
    echo
    echo "Could not be opened: parameter is null"
    helper
    exit 1
fi

currentPath=$(pwd)
input="$currentPath/$1"
output="$currentPath/image-exporter"

if [ ! -r $input ]; then
    if [ -r $1 ] 
    then
        input="$1"
    else
        echo
        echo "Could not be opened: '$1'"
        helper
        exit 1
    fi
fi

if [ ! -z "$2" ]; then
    if [ -d $2 ]
    then
        output="$2"
    fi
fi

if [ ! -d $input ]; then
    $(mkdir -p $output)
fi

#### FUNCTION ######################

getImagePath() {
    IFS='/' read -ra token <<< "$1"
    
    local length=${#token[@]}
    let "lastIdx = $length - 1"

    echo "${token[$lastIdx]}"
}

getImageName() {
    IFS=':' read -ra token <<< "$1"

    echo "${token[0]}"
}

getImageVersion() {
    IFS=':' read -ra token <<< "$1"

    echo "${token[1]}"
}

makeTarName() {
    echo "$output/$imagePath.tar"
}

####################################

echo "----------------------------------"
echo "target input: $input"
echo "----------------------------------"

failedList=()

while IFS= read -r line
do
    imageFullPath="$line"
    imagePath=$(getImagePath $line)
    imageName=$(getImageName $imagePath)
    imageVersion=$(getImageVersion $imagePath)
    tarName=$(makeTarName)

    # IMAGE PULL
    sudo ctr image pull $imageFullPath
    if [ $? -gt 0 ]; then
        echo "Could be pull image: $imageFullPath"
        failedList+=("$imageFullPath")
        continue
    fi

    # IMAGE EXPORT
    sudo ctr image export $tarName $imageFullPath
    if [ $? -gt 0 ]; then
        echo "Could be exported image: $imageFullPath"
        failedList+=("$imageFullPath")
        continue
    fi

    echo "imageName: $imageName"
    echo "imageVersion: $imageVersion"
    echo "tarName: $tarName"
    echo "----------------------------------"
done < "$input"

echo "FAILED COUNT: ${#failedList[@]}"

if [ ${#failedList[@]} -gt 0 ]; then
    echo "FAILED LIST" > "$currentPath/result.log"
    echo ${failedList[@]} | sed -r -e 's/\s+/\n/g' >> "$currentPath/result.log"
fi
#!/bin/bash

function isDir {
    local itemName=$1
    
    if [[ "$itemName" == */ ]]
    then
        true
    else
        false
    fi
}

function handleFile {
    local url=$1
    local outDir=$2
    local modTime=$3

    echo $url

    filename=$(basename -- "$url")

    if [ $token ]; then
        curl -s -H "Authorization: Bearer ${token}" $url > ${outDir}/${filename}
    else
        curl -s $url > ${outDir}/${filename}
    fi
    touch -d $modTime ${outDir}/${filename}
}

function handleDirectory {
    local url=$1
    local outDir=$2

    local gemUrl=${url}.gemdrive-ls.tsv

    echo $url

    if [ $token ]; then
        local gemData=$(curl -s -H "Authorization: Bearer ${token}" ${gemUrl})
    else
        local gemData=$(curl -s ${gemUrl})
    fi

    mkdir -p ${outDir}

    while IFS=$'\t' read -r -a gemItem
    do
        local filename="${gemItem[0]}"
        local modTime="${gemItem[1]}"
        local size="${gemItem[2]}"

        if isDir $filename
        then
            handleDirectory ${url}${filename} ${outDir}/${filename}
        else
            handleFile ${url}${filename} ${outDir} ${modTime}
        fi

    done < <(printf "$gemData\n")
}


url=$1
token=$2
outDir=$3


if [ -z $outDir ]
then
    outDir=.
fi

if isDir $url
then
    handleDirectory $url $outDir
else
    handleFile $url $outDir
fi

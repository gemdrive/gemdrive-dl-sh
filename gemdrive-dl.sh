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
    local path=$1
    local outDir=$2
    url=${driveUri}${path}

    echo $driveUri$path

    if [ $token ]; then
        url=${url}?access_token=${token}
    fi

    filename=$(basename -- "$path")
    curl -s $url > ${outDir}/${filename}
}

function handleDirectory {
    local path=$1
    local outDir=$2
    local gemUrl=${driveUri}/gemdrive/meta${path}ls.tsv

    echo $driveUri$path

    if [ $token ]; then
        gemUrl=${gemUrl}?access_token=${token}
    fi

    local gemData=$(curl -s ${gemUrl})

    mkdir -p ${outDir}

    while IFS=$'\t' read -r -a gemItem
    do
        local filename="${gemItem[0]}"
        local modTime="${gemItem[1]}"
        local size="${gemItem[2]}"

        if isDir $filename
        then
            handleDirectory ${path}${filename} ${outDir}/${filename}
        else
            handleFile ${path}${filename} ${outDir}
        fi

    done < <(printf "$gemData\n")
}


driveUri=$1
path=$2
token=$3
outDir=$4


if [ -z $outDir ]
then
    outDir=.
fi

if isDir $path
then
    handleDirectory $path $outDir
else
    handleFile $path $outDir
fi

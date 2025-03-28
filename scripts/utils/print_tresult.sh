#! /bin/bash

path=$1
keywords=$2

result_path=$BASE_PATH"/results/$1"
files=""
for ((rt=0; rt<30; rt++)); do
    files="${files}${result_path}/${rt}_result.txt "
done

cat $files | grep -E $keywords
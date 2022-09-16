#!/bin/sh
for (( i = 0; i < ${1:-10}; i++ ));
do
  echo "$i, $RANDOM" >> inputFile
done

chmod +r inputFile

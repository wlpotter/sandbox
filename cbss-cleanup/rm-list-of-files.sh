#!/bin/bash

echo "Enter the path to a file containing the list of files to delete"

read filename

while read -r line; do
	rm $line
done <$filename

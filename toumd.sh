#!/bin/bash
if [ $# -ne 1 ]
then
	echo "Right Format: \"./toumd yourtitle\""
	echo "Try Again!"
	exit
fi
post="$(pwd)/_posts/$(date +%F)-$1.md"
echo "---">$post
echo "layout: post">>$post
echo "title: ">>$post
echo "---">>$post
echo "touch $post"

#!/bin/bash

LEDPATH=/sys/class/leds

main() {
	
	while true; do
		echo 'Welcome to Led_Konfigurator!'
		echo '============================'
		local ledFiles=()
		local ledFilesCount=0
		for file in $LEDPATH/*; do
			local led=${file##*/}
			ledFiles+=led
			((ledFilesCount++))
			echo "${ledFilesCount}. ${led}"
		done
		local quitNo=$((ledFilesCount+1))
		echo "${quitNo}. Quit"
		read -p "Please enter a number (1-${quitNo}) for the led to configure or quit: " selection
	
		if [[  $selection = $quitNo ]]; then
			echo "Quit"
			exit 0
		fi
	done
}

main

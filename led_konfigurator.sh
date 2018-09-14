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
			ledFiles[ledFilesCount]=${led}
			((ledFilesCount++))
			echo "${ledFilesCount}. ${led}"
		done
		local quitNo=$((ledFilesCount+1))
		echo "${quitNo}. Quit"
		
		local selection
		read -p "Please enter a number (1-${quitNo}) for the led to configure or quit: " selection
		if [[  $selection = $quitNo ]]; then
			echo "Quit"
			exit 0
		fi
		
		ledManipulationMenu ${ledFiles[$((selection-1))]}
	done
}

ledManipulationMenu() {
	local led=$1
	local selection
	
	while true; do
		echo '['"${led}"']'
		echo '=========='
		echo 'What would you like to do with this led?'
		echo '1. Turn On'
		echo '2. Turn Off'
		echo '3. Associate with a system event'
		echo '4. Associate with the performance of a process'
		echo '5. Stop association with a process performance'
		echo '6. Quit to main menu'
		read -p 'Please enter a number (1-6) for your choice: ' selection
	
		case "$selection" in
			1)
				ledTurnOn $led
				;;
			2)
				ledTurnOff $led
				;;
			3|4|5)
				echo 'Unimplemented'
				;;
			6)
				return 0
				;;
		esac
	done
}

ledTurnOff() {
	echo 0 > $LEDPATH/$1/brightness
}

ledTurnOn() {
	echo 1 > $LEDPATH/$1/brightness
}

main

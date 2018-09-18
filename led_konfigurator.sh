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
			3)
				systemEventMenu $led
				;;
			4|5)
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

systemEventMenu() {
	local systemEventSelection
	while true; do
		local pageMenu=()
		pageMenu="${pageMenu}"'Associate Led with a system Event\n'
		pageMenu="${pageMenu}"'=================================\n'
		pageMenu="${pageMenu}"'Available events are:\n'
		pageMenu="${pageMenu}"'---------------------\n'
		local systemEvents=()
		read -r -a systemEvents <<< $(getTriggers $1)
		local counter=0
		for event in "${systemEvents[@]}"; do
			(( counter = counter + 1 ))
			pageMenu="${pageMenu} ${counter}) "
			if [[ $event =~ ^\[.+\]$ ]]; then
				event=$(echo ${event} | sed -r -e 's/\[(.*)\]/\1/')
				pageMenu="${pageMenu}${event}*"'\n'
				systemEvents[$((counter - 1))]=${event}
			else
				pageMenu="${pageMenu}${event}"'\n'
			fi
		done
		echo -e "${pageMenu}" | more
		quitNo=$((counter+1))
		local systemEventSelection
		read -p "Please select an option: (1-${quitNo}): " systemEventSelection
		
		if [[ $systemEventSelection = $quitNo ]]; then
			return 0
		fi
		
		if (( systemEventSelection > 0 && systemEventSelection < quitNo )); then
			setTrigger $1 "${systemEvents[$(($systemEventSelection - 1))]}"
		fi
		
	done
}

getTriggers() {
	cat $LEDPATH/$1/trigger
}

setTrigger() {
	echo $2 > $LEDPATH/$1/trigger
}

main

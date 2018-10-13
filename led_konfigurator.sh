#!/bin/bash

LEDPATH=/sys/class/leds

main() {
	
	# Display the LED Selection Menu
	
	while true; do
		echo 'Welcome to Led_Konfigurator!'
		echo '============================'
		local ledFiles=()
		local ledFilesCount=0
		
		# Get every file that represents an LED
		for file in $LEDPATH/*; do
			# Get the base name of the LED file which is the led name
			local led=${file##*/}
			ledFiles[ledFilesCount]=${led}
			((ledFilesCount++))
			echo "${ledFilesCount}. ${led}"
		done
		local quitNo=$((ledFilesCount+1))
		echo "${quitNo}. Quit"
		
		# Get user's selection
		
		local selection
		read -r -p "Please enter a number (1-${quitNo}) for the led to configure or quit: " selection
		if [[  $selection = "$quitNo" ]]; then
			echo "Quit"
			exit 0
		fi
		
		ledManipulationMenu "${ledFiles[$((selection-1))]}"
	done
}

ledManipulationMenu() {
	
	# Menu to manipulate user selected LED
	
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
		
		# Get user selection
		read -r -p 'Please enter a number (1-6) for your choice: ' selection
	
		case "$selection" in
			1)
				ledTurnOn "$led"
				;;
			2)
				ledTurnOff "$led"
				;;
			3)
				systemEventMenu "$led"
				;;
			4)
				associateProcessMenu "$led"
				;;
			5)
				unassociateProcess
				;;
			6)
				return 0
				;;
		esac
	done
}

ledTurnOff() {
	# Make sure we have manual control of the LED
	# by setting it's trigger to none
	
	setTrigger "$1" "none"
	
	# Value 0 turns the LED off
	echo 0 > $LEDPATH/"$1"/brightness
}

ledTurnOn() {
	# Make sure we have manual control of the LED
	# by setting it's trigger to none
	setTrigger "$1" "none"
	
	# Value 1 turns the LED on
	echo 1 > $LEDPATH/"$1"/brightness
}

systemEventMenu() {
	
	# Menu to change the LED trigger
	# This menu is paged so the menu text is built up in a string
	# and then echoed to more
	
	local systemEventSelection
	while true; do
		local pageMenu=""
		pageMenu="${pageMenu}"'Associate Led with a system Event\n'
		pageMenu="${pageMenu}"'=================================\n'
		pageMenu="${pageMenu}"'Available events are:\n'
		pageMenu="${pageMenu}"'---------------------\n'
		local systemEvents=()
		# Read in the triggers from the triggers file and
		# add them into an array
		read -r -a systemEvents <<< "$(getTriggers "$1")"
		local counter=0
		# Add each trigger to the menu with a number
		# which is it's index in the array + 1
		for event in "${systemEvents[@]}"; do
			(( counter = counter + 1 ))
			pageMenu="${pageMenu}${counter}) "
			# Check if it is the current trigger for the LED
			if [[ $event =~ ^\[.+\]$ ]]; then
				# Remove the square brackets from it's name
				event=$(echo "${event}" | sed -r -e 's/\[(.*)\]/\1/')
				# Add it to the menu with an asterisk
				pageMenu="${pageMenu}${event}*"'\n'
				# Replace the name in the array with the plain name
				# So it can be directly used later
				systemEvents[$((counter - 1))]=${event}
			else
				pageMenu="${pageMenu}${event}"'\n'
			fi
		done
		quitNo=$((counter+1))
		pageMenu="${pageMenu}${quitNo}) Quit to previous menu"
		
		# Page the menu with more
		echo -e "${pageMenu}" | more
		
		# Get the user's selection
		local systemEventSelection
		read -r -p "Please select an option: (1-${quitNo}): " systemEventSelection
		
		if [[ $systemEventSelection = "$quitNo" ]]; then
			return 0
		fi
		
		if (( systemEventSelection > 0 && systemEventSelection < quitNo )); then
			setTrigger "$1" "${systemEvents[$((systemEventSelection - 1))]}"
		fi
		
	done
}

getTriggers() {
	# Read the trigger file to a string
	cat "$LEDPATH/$1/trigger"
}

setTrigger() {
	# Set the trigger by echoing it to the trigger file
	echo "$2" > "$LEDPATH/$1/trigger"
}

associateProcessMenu() {
	
	# Menu to associate the LED with the performance of a process
	
	local processName
	local monitorOption
	local conflictChoice
	local matches=()
	
	echo 'Associate LED with the performance of a process'
	echo '------------------------------------------------'
	read -r -p "Please enter the name of the program to monitor(partial names are ok): " processName
	read -r -p "Do you wish to 1) monitor memory or 2) monitor cpu? [enter memory or cpu]: " monitorOption
	
	# Read the list of processes, get only the process base name,
	# search for the user's entered process name and show
	# it only once if there is more than one of the process.
	# All stored in an array.
	matches=($(ps aux | awk '{ n=split ($11,a,/\//); print a[n] }' | grep "${processName}" | sort -u ))
	processName=${matches[0]}
	# If there is more than one match display the conflict menu
	if ((${#matches[@]} > 1)); then
		echo 'Name Conflict'
		echo '-------------'
		echo 'I have detected a name conflict. Do you want to monitor:'
		local conflictCounter=1
		for match in "${matches[@]}"; do
			echo "${conflictCounter}) ${match}";
			((conflictCounter++));
		done
		echo "${conflictCounter}) Cancel Request";
		
		read -r -p "Please select an option (1-${conflictCounter}): " conflictChoice
		
		if [[ $conflictChoice = "$conflictCounter" ]]; then
			return 0
		fi
		processName=${matches[((conflictChoice-1))]}
	fi
	
	# Start the process monitor in the background with no output
	
	(./process_monitor_led_konfigurator.sh -l "${1}" -m "${monitorOption}" -p "${processName}" 2>&1 &)
	
}

unassociateProcess() {
	local processID
	local psOutput
	
	# Get the process list, find the process monitor and get it's pid
	psOutput=$(ps aux)
	processID=$(echo "${psOutput}" | grep 'process_monitor_led_konfigurator.sh' | grep -v grep | awk '{ print $2 }')
	
	# Kill the process
	kill "$processID"
}

# Display the first menu
main

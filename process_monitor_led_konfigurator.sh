#!/bin/bash

LEDPATH=/sys/class/leds

main() {
	local OPTIND
	local opt
	local processName
	local monitor
	local led
	local usage
	usage="Usage: ${0##*/} [-l led name] [-p process name] [-m montor value]"
	# Use getopts to process the command line options
	while getopts "l:p:m:" opt; do
		case "$opt" in
			l)
				led=$OPTARG
				;;
			p)
				processName=$OPTARG
				;;
			m)
				monitor=$OPTARG
				;;
			?)
				echo "$usage"
				return 1
				;;
		esac
	done
	
	# Check that correct arguments have been passed in
	
	if [ -z "$led" ]; then
		echo 'error: must provide a led name'
		echo "$usage"
		return 1
	fi
	
	if [ -z "$processName" ]; then
		echo 'error: must provide a process name'
		echo "$usage"
		return 1
	fi
	
	if [ -z "$monitor" ]; then
		echo 'error: must provide a monitor'
		echo "$usage"
		return 1
	fi
	
	if [[ $monitor != "cpu" && $monitor != "memory" ]]; then
		echo 'error: monitor value must be cpu or memory'
		echo "$usage"
		return 1
	fi
	
	if [[ $monitor = "cpu" ]]; then
		monitorCPU "$processName" "$led"
	fi
	
	if [[ $monitor = "memory" ]]; then
		monitorMemory "$processName" "$led"
	fi
}

setTrigger() {
	# Set the trigger by echoing it to the trigger file
	echo "$2" > "$LEDPATH/$1/trigger"
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

monitorCPU() {
	# Monitor the CPU usage of all the processes with the name
	# given to the script
	
	setTrigger "$2" "none"
	
	while true; do
		local processCPUUsage
		local processCPUUsageArr
		local psOutput
		
		# Get the process list, find all processes with the correct name
		# get their cpu percentage and store them all in an array
		psOutput=$(ps aux)
		processCPUUsageArr=($(echo "${psOutput}"  | grep "${1}" | grep -v grep | awk '{ n=split ($3,a,/\//); print a[n] }' ))
		
		# Expand the array to a string and then replace the spaces
		# generated between each value with a plus sign so it can
		# be used with bc
		processCPUUsage=${processCPUUsageArr[*]}
		processCPUUsage=${processCPUUsage// /+}
		
		local totalCPUUsage
		# Pass the string processed for bc into bc
		totalCPUUsage=$(echo "scale=2;" "${processCPUUsage}" | bc)
		# 100% = 1 second of sleep
		localSleepTime=$(echo "scale=2; (${totalCPUUsage}/100)" | bc)
		ledTurnOn "$2"
		sleep "$localSleepTime"
		ledTurnOff "$2"
	done
}

monitorMemory() {
	setTrigger "$2" "none"
	while true; do
		local processMemoryUsage
		local processMemoryUsageArr
		local psOutput
		
		# Get the process list, find all processes with the correct name
		# get their memory percentage and store them all in an array
		psOutput=$(ps aux)
		processMemoryUsageArr=($(echo "${psOutput}" | grep "${1}" | grep -v grep | awk '{ n=split ($4,a,/\//); print a[n] }' ))
		
		# Expand the array to a string and then replace the spaces
		# generated between each value with a plus sign so it can
		# be used with bc
		processMemoryUsage=${processMemoryUsageArr[*]}
		processMemoryUsage=${processMemoryUsage// /+}
		
		
		local totalMemoryUsage
		# Pass the string processed for bc into bc
		totalMemoryUsage=$(echo "scale=2;" "${processMemoryUsage}" | bc)
		# 100% = 1 second of sleep
		localSleepTime=$(echo "scale=2; (${totalMemoryUsage}/100)" | bc)
		ledTurnOn "$2"
		sleep "$localSleepTime"
		ledTurnOff "$2"
	done
}

main "$@"

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
	echo "$2" > "$LEDPATH/$1/trigger"
}

ledTurnOff() {
	setTrigger "$1" "none"
	echo 0 > $LEDPATH/"$1"/brightness
}

ledTurnOn() {
	setTrigger "$1" "none"
	echo 1 > $LEDPATH/"$1"/brightness
}

monitorCPU() {
	setTrigger "$2" "none"
	while true; do
		local processCPUUsage
		local processCPUUsageArr
		local psOutput
		psOutput=$(ps aux)
		processCPUUsageArr=($(echo "${psOutput}"  | grep "${1}" | grep -v grep | awk '{ n=split ($3,a,/\//); print a[n] }' ))
		processCPUUsage=${processCPUUsageArr[*]}
		processCPUUsage=${processCPUUsage// /+}
		local totalCPUUsage
		totalCPUUsage=$(echo "scale=2;" "${processCPUUsage}" | bc)
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
		psOutput=$(ps aux)
		processMemoryUsageArr=($(echo "${psOutput}" | grep "${1}" | grep -v grep | awk '{ n=split ($4,a,/\//); print a[n] }' ))
		processMemoryUsage=${processMemoryUsageArr[*]}
		processMemoryUsage=${processMemoryUsage// /+}
		local totalMemoryUsage
		totalMemoryUsage=$(echo "scale=2;" "${processMemoryUsage}" | bc)
		localSleepTime=$(echo "scale=2; (${totalMemoryUsage}/100)" | bc)
		ledTurnOn "$2"
		sleep "$localSleepTime"
		ledTurnOff "$2"
	done
}

main "$@"

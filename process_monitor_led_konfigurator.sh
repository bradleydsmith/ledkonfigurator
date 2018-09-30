#!/bin/bash

main() {
	local OPTIND
	local opt
	local processName
	local monitor
	local led
	local usage=$(echo "Usage:" ${0##*/} "[-l led name] [-p process name] [-m montor value]")
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
				echo "Usage:" ${0##*/} "[-l led name] [-p process name] [-m montor value]"
				return 1
				;;
		esac
	done
	
	if [ -z "$led" ]; then
		echo 'error: must provide a led name'
		echo $usage
		return 1
	fi
	
	if [ -z "$processName" ]; then
		echo 'error: must provide a process name'
		echo $usage
		return 1
	fi
	
	if [ -z "$monitor" ]; then
		echo 'error: must provide a monitor'
		echo $usage
		return 1
	fi
	
	if [[ $monitor != "cpu" && monitor != "memory" ]]; then
		echo 'error: monitor value must be cpu or memory'
		echo $usage
		return 1
	fi
}

main $@

#!/bin/bash
#
# Copyright (c) Authors: https://www.armbian.com/authors
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.

STATE_PATH="$1"
[[ -z "$1" ]] && STATE_PATH="/etc/armbian-leds.conf"

# Regular expression to extract the trigger from the led trigger file
REGEX=$'\[(.*)\]'

CMD_FIND=$(which find)

# Retrieve the trigger for a specific led and stores the entry in a destination state file
# Also retrieve all the writable parameters for a led and stores them in a destination state file
# $1 = base led path
# $2 = path of destination state file
function store_led() {

	PATH="$1"
	TRIGGER_PATH="$1/trigger"
	DESTINATION="$2"

	TRIGGER_CONTENT=$(< $TRIGGER_PATH)

	[[ "$TRIGGER_CONTENT" =~ $REGEX ]]

	TRIGGER_VALUE=${BASH_REMATCH[1]}

	echo "[$LED]" >> $STATE_PATH
	echo "trigger=$TRIGGER_VALUE" >> $DESTINATION

	# In case the trigger is any of the kbd-*, don't store any other parameter
	# This avoids num/scroll/capslock from being restored at startup
	[[ "$TRIGGER_VALUE" =~ kbd-* ]] && return

	COMMAND_PARAMS="$CMD_FIND $PATH/ -maxdepth 1 -type f ! -iname uevent ! -iname trigger -perm /u+w -printf %f\\n"
	PARAMS=$($COMMAND_PARAMS)

	# brightness has two distinct meanings depending on the trigger:
	#   trigger=none  → brightness is config (static value, persist it).
	#   trigger=*     → brightness is the trigger's instantaneous output
	#                   (blink-state at shutdown), persisting it is noise
	#                   and causes ghost-LED bugs on restore (e.g. ":link"
	#                   triggers showed cable-up while unplugged; rtw88
	#                   wifi flapped 0/1 in /etc/armbian-leds.conf on every
	#                   shutdown). Strip for any non-none trigger.
	# Subsumes the earlier ":link"-only workaround (commit 2960ffaff).
	# Forum thread: https://forum.armbian.com/topic/57284-regular-changes-in-file-etcarmbian-ledsconf-on-odroid-n2/
	# Token-safe filter (whole-word match): the previous ${PARAMS//brightness/}
	# substring substitution would also corrupt sibling files like
	# `max_brightness` -> `max_`, breaking the read loop below under set -e.
	# Bash-only (no `awk` etc.) because store_led() reassigns PATH to the
	# sysfs led path, so external commands wouldn't be found here.
	if [[ "$TRIGGER_VALUE" != "none" ]]; then
		declare _filtered=""
		for _p in $PARAMS; do
			[[ "$_p" == "brightness" ]] && continue
			_filtered+="$_p"$'\n'
		done
		PARAMS="$_filtered"
	fi

	for PARAM in $PARAMS; do

		PARAM_PATH="$PATH/$PARAM"
		VALUE=$(< $PARAM_PATH)

		# If the variable contains non-printable characters
		# suppose it contains binary and skip it
		[[ "$VALUE" =~ [[:cntrl:]] ]] && continue

		echo "$PARAM=$VALUE" >> $DESTINATION

	done

}

# zeroing current state file if existing
[[ -f $STATE_PATH ]] && echo -n > $STATE_PATH

for LED in /sys/class/leds/*; do
	[[ -d "$LED" ]] || continue

	# Skip saving state for directories starting with enP e.g. enP1p1s0-0::lan enP2p1s0-2::lan etc. etc.
	[[ "$(/usr/bin/basename "$LED")" == enP* ]] && continue

	store_led $LED $STATE_PATH
	echo >> $STATE_PATH

done

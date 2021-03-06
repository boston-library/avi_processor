#!/bin/bash

#
# cache_clean.sh
# Cron script for maintaining the loris cache size.
#
# CAUTION - This script deletes files. Be careful where you point it!
#
LOG="/var/log/avi/tmp_clean.log"

# Check that the cache directories...
IMG_CACHE_DIR="/tmp"

# ...is below a certain size...
REDUCE_TO=100048576 #10 gb
# REDUCE_TO=1073741824 # 1 TB
# REDUCE_TO=2147483648 # 2 TB

# ...and when it is larger, start deleting files accessed more than a certain 
# number of days ago until the cache is smaller than the configured size.

# Note the name of the variable __REDUCE_TO__: this should not be the total 
# amount of space you can afford for the cache, but instead the total space 
# you can afford MINUS the amount you expect the cache to grow in between 
# executions of this script.

current_usage () {
	du -sk $IMG_CACHE_DIR | cut -f 1
}

delete_total=0
max_age=65 # minutes
usage=$(current_usage)
start_size=$usage
run=1
#while [ $usage -gt $REDUCE_TO ] && [ $max_age -ge -1 ]; do
#run=0	

	# files. loop (instead of -delete) so that we can keep count
	for f in $(find $IMG_CACHE_DIR -maxdepth 1 -name mini* -type f -amin +$max_age); do
                run=0
		rm $f
		let delete_total+=1
	done

	for f in $(find $IMG_CACHE_DIR -maxdepth 1 -name suf* -type f -amin +$max_age); do
                run=0
		rm $f
		let delete_total+=1
	done

	#let max_age-=5
	usage=$(current_usage)
#done

echo -ne "$(date +[%c]) " >> $LOG
if [ $run == 0 ]; then
	echo -ne "Deleted $delete_count files to " >> $LOG
	echo "get cache from $start_size kb to $usage kb." >> $LOG
else
	echo "Cache at $usage kb (no deletes required)." >> $LOG
fi

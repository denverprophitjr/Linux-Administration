#!/bin/sh

# Log rotate script created by Denver Prophit Jr. for cPanel<tm> servers
# https://denverprophit.us
# Version 0.2-beta

# Are we already runnig? Twice runs is bad thing
if [ -f /tmp/domlogs.flag ]; then echo "Already running!"; exit 2; fi

# Flag is indicating, that we running
touch /tmp/domlogs.flag

day=`date +%d`
month=`date +%m`
year=`date +%Y`

# If '/backup' is not present in mtab - trying to mount it. If mount fails - exiting with emergancy status.
# grep '/backup' /etc/mtab || mount /dev/sdb1 /backup || exit 3

# Just creating directory structure, if not exist
if [ ! -d "/backup/domlogs" ]; then mkdir /backup/domlogs; fi
if [ ! -d "/backup/domlogs/${year}" ]; then mkdir /backup/domlogs/${year}; fi
if [ ! -d "/backup/domlogs/${year}/${month}" ]; then mkdir /backup/domlogs/${year}/${month}; fi
if [ ! -d "/backup/domlogs/${year}/${month}/${day}" ]; then mkdir /backup/domlogs/${year}/${month}/${day}; fi

for cp_user in `ls /var/cpanel/users`
	do
	current_time=`date +%H.%M`
	# Archive directory with logs to file
	tar -czf /backup/domlogs/${year}/${month}/${day}/${cp_user}_${year}.${month}.${day}_${current_time}.tar.gz /var/log/apache2/domlogs/${cp_user}/
	# Count statistics and do other cpanel stuff
	/usr/local/cpanel/scripts/runweblogs ${cp_user}
	# Truncate every file without permissions loss
	for file in /var/log/apache2/domlogs/${cp_user}/*
		do
		echo > ${file}
	done
	# Send Apache signal to reload logs
	/usr/local/apache/bin/apachectl -k graceful
	
done

# Apache restart
# /usr/local/cpanel/scripts/restartsrv_httpd

# FTP daemon restart - it doesn't have reload feature
/usr/local/cpanel/scripts/restartsrv_pureftpd

# Trying to umount our backup drive. Remember! Nobody must work with this drive (and lock it). 
# I don't put here forced unmount as a very bad thing at all.
# umount /backup

# We finished
rm -f /tmp/domlogs.flag

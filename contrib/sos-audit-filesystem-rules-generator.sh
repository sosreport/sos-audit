#!/bin/bash
#
# Tested on: RHEL8 alpha
#
# NOTE: Not intended to be shipped but used in packaging / building
#
# This script can be used as a starting point to help generate the filesystem-changes.rules audit file.
# NOTE: Some 'bin' and 'conf' files probably should not be included in the rules.
#
# TODO: might be easier to maintain in python
#
RULES_DIR=/usr/lib/sos/audit/rules.d
RULES_FILE=$RULES_DIR/40-sos-filesystem.rules
if [ ! -d $RULES_DIR ]; then
	echo Creating $RULES_DIR
	mkdir -p $RULES_DIR
fi
> $RULES_FILE

# Filter out read-only or other commands that may generate excessive audit entries
declare -A binary_filter
for b in /usr/sbin/xfs_bmap /usr/sbin/xfs_estimate /usr/sbin/xfs_info /usr/sbin/xfs_logprint
do
	binary_filter[xfsprogs,$b]=1
done
for b in /usr/bin/lsattr /usr/sbin/dumpe2fs /usr/sbin/filefrag /usr/sbin/logsave
do
	binary_filter[e2fsprogs,$b]=1
done
for b in /sbin/nfsdcltrack /sbin/osd_login /sbin/rpc.statd /usr/sbin/blkmapd /usr/sbin/mountstats /usr/sbin/nfsidmap /usr/sbin/nfsiostat /usr/sbin/nfsstat /usr/sbin/rpc.gssd /usr/sbin/rpc.idmapd /usr/sbin/rpc.mountd /usr/sbin/rpc.nfsd /usr/sbin/showmount /usr/sbin/sm-notify /usr/sbin/start-statd
do
	binary_filter[nfs-utils,$b]=1
done
for b in /usr/bin/getcifsacl /usr/sbin/cifs.idmap /usr/sbin/cifs.upcall
do
	binary_filter[cifs-utils,$b]=1
done

RPMS="xfsprogs e2fsprogs nfs-utils cifs-utils"
echo "## $RULES_FILE: Filesystem related audit rules that change system state." >> $RULES_FILE
echo "## The audit rules monitor both executable as well as configuration file modification." >> $RULES_FILE
echo "## The executable and configuration files are from the following RPMs: $RPMS " >> $RULES_FILE
for p in $RPMS
do
	echo "# $p" >> $RULES_FILE
	dnf repoquery --arch x86_64 -l $p > /tmp/$p-repoquery.txt
	for f in $(cat /tmp/$p-repoquery.txt | grep bin | sort | uniq); do
		if [[ ${binary_filter[$p,$f]} ]]; then
			echo "skipping $p $f"
			continue
		fi
		echo "-w $f -p x -k filesystem_changes -k $p" >> $RULES_FILE
	done
	for f in $(cat /tmp/$p-repoquery.txt | grep \\.conf$ | sort | uniq); do
		echo "-w $f -p wa -k filesystem_changes -k $p" >> $RULES_FILE
	done
done

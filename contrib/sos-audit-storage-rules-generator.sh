#!/bin/bash
#
# This script can be used as a starting point to help generate the storage-changes.rules file.
# NOTE: Some 'bin' and 'conf' files probably should not be included in the rules.
#
RULES_DIR=/usr/lib/sos/audit/rules.d
RULES_FILE=$RULES_DIR/40-sos-storage.rules
if [ ! -d $RULES_DIR ]; then
	echo Creating $RULES_DIR
	mkdir -p $RULES_DIR
fi
> $RULES_FILE

# Filter out read-only or other commands that may generate excessive audit entries
declare -A binary_filter
for b in /usr/sbin/lvdisplay /usr/sbin/lvmdiskscan /usr/sbin/lvmetad /usr/sbin/lvmpolld /usr/sbin/lvmsadc /usr/sbin/lvmsar /usr/sbin/lvs /usr/sbin/lvscan /usr/sbin/pvdisplay /usr/sbin/pvs /usr/sbin/pvscan /usr/sbin/vgdisplay /usr/sbin/vgs /usr/sbin/vgscan
do
	binary_filter[lvm2,$b]=1
done
for b in /usr/sbin/multipathd
do
	binary_filter[device-mapper-multipath,$b]=1
done
for b in /usr/sbin/mdmon /usr/sbin/raid-check
do
	binary_filter[mdadm,$b]=1
done
for b in /usr/sbin/fcoemon /usr/sbin/fcping /usr/sbin/fcrls /usr/sbin/fipvlan
do
	binary_filter[fcoe-utils,$b]=1
done
for b in /usr/sbin/iscsid /usr/sbin/iscsi-iname /usr/sbin/iscsistart
do
	binary_filter[iscsi-initiator-utils,$b]=1
done
for b in /usr/bin/vdodmeventd /usr/bin/vdodumpconfig /usr/bin/vdoreadonly /usr/bin/vdostats
do
	binary_filter[vdo,$b]=1
done

RPMS="lvm2 device-mapper-multipath parted mdadm fcoe-utils iscsi-initiator-utils vdo"
echo "## $RULES_FILE: Storage related audit rules that change system state." >> $RULES_FILE
echo "## The audit rules monitor both executable as well as configuration file modification." >> $RULES_FILE
echo "## The executable and configuration files are from the following RPMs: $RPMS " >> $RULES_FILE
for p in $RPMS
do
	echo "# $p" >> $RULES_FILE
	dnf repoquery --arch x86_64 -l $p > /tmp/$p-repoquery.txt
	# TODO: filter out binaries that do not change state or we do not care about
	for f in $(cat /tmp/$p-repoquery.txt | grep bin | sort | uniq); do
		if [[ ${binary_filter[$p,$f]} ]]; then
			echo "skipping $p $f"
			continue
		fi
		echo "-w $f -p x -k storage_changes -k $p" >> $RULES_FILE
	done
	for f in $(cat /tmp/$p-repoquery.txt | grep \\.conf$ | sort | uniq); do
		echo "-w $f -p wa -k storage_changes -k $p" >> $RULES_FILE
	done
done
echo "# Miscellaneous (util-linux)" >> $RULES_FILE
# FIXME: include /usr/sbin/fsfreeze ?
for b in /usr/sbin/fdisk /usr/sbin/cfdisk /usr/sbin/sfdisk /usr/sbin/wipefs /usr/sbin/fstrim
do
	echo "-w $b -p x -k storage_changes -k util-linux" >> $RULES_FILE
done

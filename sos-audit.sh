#!/bin/bash -e

############################################################################
# Process /etc/sos/sos-audit.conf and enable or disable audit rules linked 
# into /etc/audit/rules.d.
############################################################################

############################################################################
# Copyright (C) 2018 Red Hat, Inc. All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
############################################################################

export LC_ALL=C

VERSION="0.3"

PATH=/bin:/sbin:$PATH
SOS_AUDIT_CONF=/etc/sos/sos-audit.conf
RULES_DIR=/usr/lib/sos/audit/rules.d
ETC_RULES_DIR=/etc/audit/rules.d

RULES_CHANGED=0
VERBOSE=0

# Read config file settings into an associate array.
declare -A AUDIT_RULES
RULES=$(sed -nr 's|^[[:space:]]*([[:alpha:]]+)[[:space:]]*=[[:space:]]*([01])[[:space:]]*$|AUDIT_RULES[sos-\1]=\2|p' < $SOS_AUDIT_CONF)
if [ -n "$RULES" ]; then
	declare $RULES
fi

while getopts "vVh" o; do
	case $o in
	v)
		VERBOSE=1
		;;
	V)
		echo "$(basename "$0"): Version $VERSION"
		exit 0
		;;
	*)
		echo "Usage: $(basename "$0") [-h][-v][-V]"
		exit 0
		;;
	esac
done

# Update any symlinks based on the configuration
for r in "${!AUDIT_RULES[@]}"
do
	if [[ "$r" =~ [^-[:alnum:]] ]]; then
		echo Skipping invalid input in $SOS_AUDIT_CONF file - "$r"
		continue
	fi
	if [ "${AUDIT_RULES[$r]}" -eq 1 ]; then
		if [ ! -e "$ETC_RULES_DIR/40-$r.rules" ]; then
			ln -s "$RULES_DIR/40-$r.rules" $ETC_RULES_DIR
			RULES_CHANGED=1
		fi
	else
		if [ -L "$ETC_RULES_DIR/40-$r.rules" ]; then
			rm -f "$ETC_RULES_DIR/40-$r.rules"
			RULES_CHANGED=1
		fi
	fi
	if [ $VERBOSE -eq 1 ]; then
		echo " "
		grep ^## "$RULES_DIR/40-$r.rules"
	fi
done

# Display currently enabled rules and indicate whether changes made
echo Currently-enabled sos-audit rules in $ETC_RULES_DIR are:
(cd $ETC_RULES_DIR && ls -1L 40-sos-*) 2> /dev/null
if [ $RULES_CHANGED -eq 1 ]; then
	echo "NOTE: Audit rules changed in $ETC_RULES_DIR. Run 'augenrules --load' to activate the new rules."
fi

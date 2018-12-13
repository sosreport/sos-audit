#!/bin/bash -e

INSTALL=install

M_INSTALL_DATA=-m444
M_INSTALL_WDATA=-m644
M_INSTALL_PROGRAM=-m755

INSTALL_DATA="$INSTALL -p $M_INSTALL_DATA"
INSTALL_WDATA="$INSTALL -p -m 644"
INSTALL_DIR="$INSTALL -m 755 -d"
INSTALL_SCRIPT="$INSTALL -p $M_INSTALL_PROGRAM"

RULES_DIR=$DESTDIR/usr/lib/sos/audit/rules.d
CONFIG_DIR=$DESTDIR/etc/sos
SBIN_DIR=$DESTDIR/usr/sbin

$INSTALL_DIR $SBIN_DIR
$INSTALL_SCRIPT sos-audit.sh $SBIN_DIR
$INSTALL_DIR $CONFIG_DIR
$INSTALL_WDATA sos-audit.conf $CONFIG_DIR
$INSTALL_DIR $RULES_DIR
$INSTALL_DATA 40-sos-storage.rules $RULES_DIR
$INSTALL_DATA 40-sos-filesystem.rules $RULES_DIR

mkdir -p ${DESTDIR}/usr/share/man/man5
mkdir -p ${DESTDIR}/usr/share/man/man8
gzip -c sos-audit.conf.5 > sos-audit.conf.5.gz
gzip -c sos-audit.sh.8 > sos-audit.sh.8.gz
install -m644 sos-audit.conf.5.gz ${DESTDIR}/usr/share/man/man5/
install -m644 sos-audit.sh.8.gz ${DESTDIR}/usr/share/man/man8/

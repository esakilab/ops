#!/bin/sh

DATE=`date +%Y%m%d`
DATE_YEAR=`date +%Y`
DATE_MONTH=`date +%m`
DATE_DAY=`date +%d`
TFTP_ROOT=/tftpboot
BACKUPDIR=${TFTP_ROOT}/${DATE_YEAR}/${DATE_MONTH}/${DATE_DAY}
CONF_FILE=
ENCRYPTED_PASSWORD=
ENCRYPTION_KEY=
TFTPSERVER=10.0.0.1

function centre_backup() {
    HOST_NAME=$1
    USER="manager"
    TMP_FILE="autobackup.cfg"
    CREATE_TMP_FILE="CREATE CONFIG=${TMP_FILE}"
    BACKUP_COMMAND="UPLOAD METHO=tftp FILE=${TMP_FILE} DESTFILE=${BACKUPDIR}/${HOST_NAME}.${DATE}.cfg SERVER=${TFTPSERVER}"
    DELETE_TMP_FILE="DELTE FILE=${TMP_FILE}"
    #expect -c "
    echo "
    set timeout 20
    spawn telnet $HOST_NAME
    expect \"login:\"   ; send \"${USER}\n\"
    expect \"Password:\"; send \"${PASSWORD}\n\"
    expect \"Manager\"  ; send \"${CREATE_TMP_FILE}\"
    expect \"Manager\"  ; send \"${BACKUP_COMMAND}\"
    expect \"Manager\"  ; send \"${DELETE_TMP_FILE}\"
    "
}

function cisco_backup() {
    echo cisco
}

function alaxala_backup() {
    echo alaxala
}

function juniper_backup() {
    echo juniper
}

function foundry_backup() {
    echo foundry
}

function backup() {
    HOST_NAME=$1
    case ${HOST_NAME} in
	foundry* ) foundry_backup $HOST_NAME ;;
	alaxala* | nec* ) alaxala_backup $HOST_NAME ;;
	juniper* ) juniper_backup $HOST_NAME;;
	cisco* ) cisco_backup $HOST_NAME;;
	centre* ) centre_backup $HOST_NAME;;
    esac
}

function get_password() {
    TMP_PASSWORD_FILE=tmp_password.${DATE}
    openssl enc -d -aes256 -in ${ENCRYPTED_PASSWORD} -out ${TMP_PASSWORD_FILE} -kfile ${ENCRYPTION_KEY}
    PASSWORD=`cat $TMP_PASSWORD_FILE`
    #rm $TMP_PASSWORD_FILE    
}

# main function
declare PASSWORD
get_password

mkdir -p ${BACKUPDIR}
for HOST_NAME in `cat ${CONF_FILE}`;
do
    backup $HOST_NAME
done


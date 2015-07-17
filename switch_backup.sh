#!/bin/sh

DATE=`date +%Y%m%d`
DATE_YEAR=`date +%Y`
DATE_MONTH=`date +%m`
DATE_DAY=`date +%d`
TFTP_ROOT=/tftpboot
BACKUP_DIR=${TFTP_ROOT}/${DATE_YEAR}/${DATE_MONTH}/${DATE_DAY}
HOSTS_FILE=
ENCRYPTED_PASSWORD_FILE=
ENCRYPTION_KEY_FILE=
TFTPSERVER=10.0.0.1

centre_backup() {
    HOST_NAME=$1
    USER="manager"
    TMP_FILE="autobackup.cfg"
    BACKUP_FILE_PATH=${BACKUP_DIR}/${HOST_NAME}.${DATE}.cfg
    CREATE_TMP_FILE="CREATE CONFIG=${TMP_FILE}"
    BACKUP_COMMAND="UPLOAD METHO=tftp FILE=${TMP_FILE} DESTFILE=${BACKUP_FILE_PATH} SERVER=${TFTPSERVER}"
    DELETE_TMP_FILE="DELTE FILE=${TMP_FILE}"
    touch ${BACKUP_FILE_PATH}
    chmod 666 ${BACKUP_FILE_PATH}
    
    expect -c "
    set timeout 20
    spawn telnet $HOST_NAME
    expect \"login:\"   ; send \"${USER}\n\"
    expect \"Password:\"; send \"${PASSWORD}\n\"
    expect \"Manager\"  ; send \"${CREATE_TMP_FILE}\n\"
    expect \"Manager\"  ; send \"${BACKUP_COMMAND}\n\"
    expect \"Manager\"  ; send \"${DELETE_TMP_FILE}\n\"
    "
}

cisco_backup() {
    echo cisco
}

alaxala_backup() {
    echo alaxala
}

juniper_backup() {
    echo juniper
}

foundry_backup() {
    echo foundry
}

backup() {
    HOST_NAME=$1
    case ${HOST_NAME} in
	foundry* ) foundry_backup $HOST_NAME ;;
	alaxala* | nec* ) alaxala_backup $HOST_NAME ;;
	juniper* ) juniper_backup $HOST_NAME;;
	cisco* ) cisco_backup $HOST_NAME;;
	centre* ) centre_backup $HOST_NAME;;
    esac
}

get_password() {
    TMP_PASSWORD_FILE=tmp_password_${DATE}
    openssl enc -d -aes256 -in ${ENCRYPTED_PASSWORD_FILE} -out ${TMP_PASSWORD_FILE} -kfile ${ENCRYPTION_KEY_FILE}
    PASSWORD=`cat $TMP_PASSWORD_FILE`
    rm $TMP_PASSWORD_FILE    
}

# main function
get_password

mkdir -p ${BACKUP_DIR}
for HOST_NAME in `cat ${HOSTS_FILE}`;
do
    backup $HOST_NAME
done


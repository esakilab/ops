#!/bin/sh

EXEC_DATE=`date +%Y%m%d`
DATE_PATH=`date +%Y/%m/%d`
TFTP_ROOT=/tftpboot
BACKUP_DIR=${TFTP_ROOT}/${DATE_PATH}
HOSTS_FILE=
ENCRYPTED_PASSWORD_FILE=
ENCRYPTION_KEY_FILE=
BACKUP_SERVER=10.0.0.1

centre_backup() {
    USER="manager"
    TMP_FILE="autobackup.cfg"
    LOCAL_TMP_FILE="tmp.cfg"
    case ${HOST_NAME} in
        centre9) BACKUP_FILE_PATH=${BACKUP_DIR}/${LOCAL_TMP_FILE};; # this is due to the filename limitation
        *) BACKUP_FILE_PATH=${BACKUP_DIR}/${HOST_NAME}.${EXEC_DATE}.cfg;;
    esac
    CREATE_TMP_FILE_COMMAND="CREATE CONFIG=${TMP_FILE}"
    BACKUP_COMMAND="UPLOAD METHO=tftp FILE=${TMP_FILE} DESTFILE=${BACKUP_FILE_PATH} SERVER=${BACKUP_SERVER}"
    DELETE_TMP_FILE_COMMAND="DELTE FILE=${TMP_FILE}"
    touch ${BACKUP_FILE_PATH}
    chmod 666 ${BACKUP_FILE_PATH}
    
    expect -c "
        set timeout 2
        spawn telnet ${HOST_NAME}
        expect \"login:\"   ; send \"${USER}\n\"
        expect \"Password:\"; send \"${PASSWORD}\n\"
        expect \"Manager\"  ; send \"${CREATE_TMP_FILE_COMMAND}\n\"
        expect \"Manager\"  ; send \"${BACKUP_COMMAND}\n\"
        expect \"Manager\"  ; send \"${DELETE_TMP_FILE_COMMAND}\n\"
    "
    case ${HOST_NAME} in
        centre9) mv ${BACKUP_DIR}/${LOCAL_TMP_FILE} ${BACKUP_DIR}/${HOST_NAME}.${EXEC_DATE}.cfg;;
    esac
}

cisco_backup() {
    USER="elab"
    BACKUP_FILE=${DATE_PATH}/${HOST_NAME}.${EXEC_DATE}.cfg
    BACKUP_COMMAND="copy running-config tftp://${BACKUP_SERVER}/${BACKUP_FILE}"
    touch ${TFTP_ROOT}/${BACKUP_FILE}
    chmod 666 ${BACKUP_FILE}
    
    expect -c "
        set timeout 2
        spawn telnet ${HOST_NAME}
        expect \"\[Uu\]sername:\" ; send \"${USER}\n\"
        expect \"Password:\"      ; send \"${PASSWORD}\n\"
        expect \"cisco\"          ; send \"en\n\"
        expect \"Password:\"      ; send \"${PASSWORD}\n\"
        expect \"cisco\"          ; send \"${BACKUP_COMMAND}\n\"
        expect \"Address\"        ; send \"\n\"
        expect \"Destination\"    ; send \"\n\"
        expect \"!!\"             ;
    "
}

alaxala_backup() {
    USER="elab"
    BACKUP_FILE=${DATE_PATH}/${HOST_NAME}.${EXEC_DATE}.cfg
    BACKUP_COMMAND="copy running-config tftp:${BACKUP_SERVER}/${BACKUP_FILE}"
    touch ${TFTP_ROOT}/${BACKUP_FILE}
    chmod 666 ${BACKUP_FILE}
    
    expect -c "
        set timeout 2
        spawn telnet ${HOST_NAME}
        expect \"\[Ll\]ogin:\"        ; send \"${USER}\n\"
        expect \"Password:\"          ; send \"${PASSWORD}\n\"
        expect \"\[nN\]\[eE\]\[cC\]\" ; send \"en\n\"
        expect \"Password:\"          ; send \"${PASSWORD}\n\"
        expect \"\[nN\]\[eE\]\[cC\]\" ; send \"${BACKUP_COMMAND}\n\"
        expect \"Configuration\"      ; send \"y\n\"
        expect \"Data\"               ;
    "
}

juniper_backup() {
    USER="elab"
    TMP_FILE="autobackup.cfg"
    BACKUP_FILE_PATH=${BACKUP_DIR}/${HOST_NAME}.${EXEC_DATE}.cfg
    CREATE_TMP_FILE_COMMAND="save ${TMP_FILE}"
    BACKUP_COMMAND="file copy ${TMP_FILE} scp://${USER}@${BACKUP_SERVER}${BACKUP_FILE_PATH}"
    DELETE_TMP_FILE_COMMAND="file delete ${TMP_FILE}"
    touch ${BACKUP_FILE_PATH}
    chmod 666 ${BACKUP_FILE_PATH}
    
    expect -c "
        set timeout 2
        spawn telnet ${HOST_NAME}
        expect \"\[Ll\]ogin:\" ; send \"${USER}\n\"
        expect \"Password:\"   ; send \"${PASSWORD}\n\"
        expect \"elab@\"       ; send \"configure\n\"
        expect \"elab@\"       ; send \"${CREATE_TMP_FILE_COMMAND}\n\"
        expect \"elab@\"       ; send \"exit\n\"
        expect \"elab@\"       ; send \"${BACKUP_COMMAND}\n\"
        expect \"elab@\"       ; send \"${DELETE_TMP_FILE_COMMAND}\n\"
        expect \"elab@\"       ;
    "
}

foundry_backup() {
    USER="elab"
    BACKUP_FILE=${DATE_PATH}/${HOST_NAME}.${EXEC_DATE}.cfg
    BACKUP_COMMAND="copy running-config tftp ${BACKUP_SERVER} ${BACKUP_FILE}"
    touch ${TFTP_ROOT}/${BACKUP_FILE}
    chmod 666 ${TFTP_ROOT}/${BACKUP_FILE}
    
    expect -c "
        set timeout 20
        spawn telnet $HOST_NAME
        expect \"Please Enter Login Name:\" ; send \"${USER}\r\n\"
        expect \"Please Enter Password:\" ; send \"${PASSWORD}\r\n\"
        expect \"*foundry\"        ; send \"${BACKUP_COMMAND}\r\n\"
        expect \"*Upload\"
    "
}

backup() {
    case ${HOST_NAME} in
	    foundry* ) foundry_backup ;;
	    alaxala* | nec* ) alaxala_backup;;
	    juniper* ) juniper_backup ;;
	    cisco* ) cisco_backup ;;
	    centre* ) centre_backup ;;
    esac
}

get_password() {
    if [ ! -f ${ENCRYPTION_KEY_FILE} ] || [ ! -f ${ENCRYPTED_PASSWORD_FILE} ];
    then
	    echo "Encrypted password file or private key file for decryption does not exist."
	    exit 1
    fi

    TMP_PASSWORD_FILE=tmp_password_${EXEC_DATE}
    openssl enc -d -aes256 -in ${ENCRYPTED_PASSWORD_FILE} -out ${TMP_PASSWORD_FILE} -kfile ${ENCRYPTION_KEY_FILE}
    PASSWORD=`cat $TMP_PASSWORD_FILE`
    rm $TMP_PASSWORD_FILE    
}

create_backup_directory() {
    if [ -d ${BACKUP_DIR} ]
    then
	    rm -rf ${BACKUP_DIR}
    fi
    mkdir -p ${BACKUP_DIR}
}

## main function ##
get_password
create_backup_directory

if [ ! -f ${HOSTS_FILE} ]
then
    echo "hosts file does not exist."
    exit 1
fi

for HOST_NAME in `cat ${HOSTS_FILE}`;
do
    backup $HOST_NAME
done


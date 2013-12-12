 #!/bin/bash
set -e
#ALL PATH VARIABLES SHOULD HAVE A TRAILING SLASH

#PATHS
MEMDRIVEPATH=./secure/memdrive/
DAEMONPATH=./daemons/
DECRYPTEDPATH=./secure/decrypted/


#Dropbox Config#
DROPBOXSCRIPT=./modules/dropbox/dropbox_uploader.sh
DROPBOXCONFIG=./dropbox_uploader.cfg
DBWALLETCONTAINERPATH=/
WALLETCONTAINERFILE=Backup2.dat
#End Dropbox Config#

#Truecrypt config
TRUECRYPTBIN=./modules/truecrypt/truecrypt
#End truecrypt config

#Rsync config
RSYNCBIN=`which rsync`
#End rsync config
#Backup config

source "./inc.logger.sh"

RP_LOGGER_CLEAN_UP() {
	log "Unmounting all truecrypt drives"
	$TRUECRYPTBIN -d
	if mountpoint -q $MEMDRIVEPATH; then log "Trying to unmount memdrive." &&  umount -f $MEMDRIVEPATH; fi
	if [ -d "$MEMDRIVEPATH" ]; then log "Trying to remove memdrive path" && rm -rf $MEMDRIVEPATH; fi
	if [ -d "$DECRYPTEDPATH" ]; then log "Trying to remove decrypted path" && rm -rf $DECRYPTEDPATH; fi
	log "Clean up successful"
}

if  [ "$1" != "backup" ] && [ "$1" != "restore" ] || ( [ "$1" == "restore" ] && [ -z "$2" ]  ); then
	log_fatal "Valid syntax : script.sh <backup|restore> [path_to_restore_from]"
	exit 1
fi


log_info "Initializing script"
RP_LOGGER_CLEAN_UP

log_info "Creating memdrive path"
mkdir -p $MEMDRIVEPATH

log_info "Creating decrypted path"
mkdir -p $DECRYPTEDPATH

log_info "Mounting memdrive"
mount -t tmpfs -o size=1024M tmpfs $MEMDRIVEPATH

log_info "Downloading archive from dropbox"
$DROPBOXSCRIPT -p -f $DROPBOXCONFIG download $DBWALLETCONTAINERPATH$WALLETCONTAINERFILE $MEMDRIVEPATH$WALLETCONTAINERFILE

log_info "Decrypting wallet container."
$TRUECRYPTBIN -t -k "" --protect-hidden=no $MEMDRIVEPATH$WALLETCONTAINERFILE $DECRYPTEDPATH
if [ "$1" == "backup" ]; then
	log_info "Backing up wallets."
	timestamp=`date +"%Y-%m-%d-%H-%M-%S"`
	$RSYNCBIN $DAEMONPATH $DECRYPTEDPATH$timestamp -rtv --include \\.*/ --include wallet.dat --exclude \*
elif [ "$1" == "restore" ] && [ -n "$2" ] && [ -d "$DECRYPTEDPATH$2" ]; then
	log_info "Restoring wallets."
	echo -n "Type 'restore' (without quotes) to confirm restoration: "
	read do_restore
	if [ "$do_restore" != "restore" ] ; then
		log "Confirmation not recieved."
		exit 0
	fi
	$RSYNCBIN $DECRYPTEDPATH$2 $DAEMONPATH -rtv --include \\.*/ --include wallet.dat --exclude \*
else
	log_fatal "Restore path is invalid. Check your paths."
	find $DECRYPTEDPATH . -maxdepth 1 -type d
	exit 1
fi

log_info "Unmounting all truecrypt drives"
$TRUECRYPTBIN -d

log_info "Uploading truecrypt container"
$DROPBOXSCRIPT -p -f $DROPBOXCONFIG upload $MEMDRIVEPATH$WALLETCONTAINERFILE  $DBWALLETCONTAINERPATH$WALLETCONTAINERFILE 

RP_LOGGER_DONE

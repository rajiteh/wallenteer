 #!/bin/bash
if [ ! "$BASH_VERSION" ] ; then
    /bin/bash $0 $@
    exit 1
fi
set -e
#ALL PATH VARIABLES SHOULD HAVE A TRAILING SLASH

#PATHS
DAEMONPATH=./daemons/

#VARS
LOOPLIMIT=5
DAEMONCOUNT=0
source "./inc.logger.sh"

list_all_daemons() {
	local list=`echo ${DAEMONS}`
	log_info "Detected $DAEMONCOUNT daemons on this platform."
	log_info "List: $list"
}
is_daemon_running() {
	local daemon=$1
	local status=`pgrep ${daemon}`
	if [ "${status:-null}" == null ]; then
		echo 0
	else
		echo 1
	fi
}


start_daemon() {
	local daemon=$1

	if [ "$(is_daemon_running ${daemon})" == "1" ] ; then
                log_warn "$daemon is already running."
        	return
        fi

	if [ -f "$daemon" ] && [ -d ".$daemon" ] ; then
		./$daemon -datadir=.$daemon -daemon
		if [ "$(is_daemon_running ${daemon})" == 1 ] ; then
			log_info "$daemon is running."
		else
			log_warn "Cannot start $daemon"
		fi
	else
		log_warn "Daemon $daemon or it's data dir .$daemon does not exist."
	fi
}

stop_daemon() {
	local daemon=$1
	local loop=0
	local running=1

        if [ ! "$(is_daemon_running ${daemon})" == "1" ] ; then
        	log_warn "$daemon is not running."
                return
        fi

	./$daemon -datadir=.$daemon stop || :
	while [ $loop -lt $LOOPLIMIT ]; do
		loop=$[loop+1]
		log_info "Checking if $daemon is running..."
		if [ "$(is_daemon_running ${daemon})" == "1" ] ; then
			log_warn "Attempt $loop : $daemon is not dead. Retrying after 1 second.."
			sleep 2
		else
			log_info "$daemon is not running."
			running=0
			loop=$[LOOPLIMIT+1]
		fi
	done
	if [ $running == 1 ]; then
		log_warn "Force killing $daemon"
		killall $daemon || :
		sleep 5
		if [ "$(is_daemon_running ${daemon})" == "1" ]; then
			log_warn "Cannot kill $daemon"
		fi
	fi

}

start_all() {
	local loop=0
	for i in ${DAEMONS[*]}; do
		loop=$[loop+1]
		log_info "Starting daemon $loop/$DAEMONCOUNT ($i)..."
		start_daemon $i
	done
}

stop_all() {
	local loop=0
	for i in ${DAEMONS[*]}; do
		loop=$[loop+1]
		log_info "Stopping daemon $loop/$DAEMONCOUNT ($i)..."
		stop_daemon $i
	done
}


log_info "Initializing script"
cd $DAEMONPATH && DAEMONS=`find . -maxdepth 1 -type f -name "*d" | awk '{ sub(/\.\//,""); print }'`
for i in ${DAEMONS[*]}; do
	DAEMONCOUNT=$[DAEMONCOUNT+1]
done
list_all_daemons
if [ "$1" == "restart" ]; then
	log_info "Restarting all daemons."
	stop_all
	start_all
elif [ "$1" == "stop" ]; then
	log_info "Stopping all daemons."
	stop_all
elif [ "$1" == "start" ]; then
	log_info "Starting all daemons."
	start_all
else
	log_fatal "Unknown action. Syntax: scriptname.sh <start|stop|restart>"
	exit 1
fi
log_info "All done"
RP_LOGGER_DONE

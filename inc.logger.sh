#!/bin/bash

# Logging helper for bash scripts.
# Written by Raj Perera <rajiteh@gmail.com>
# This code is MIT Licensed. (http://opensource.org/licenses/MIT)

# Usage
# * Include this script at the header of your primary script.
#	$ source "inc.logger.sh"
# * Use log, log_info, log_warn, log_fatal functions to perform your logging.
# * Re-define the function RP_LOGGER_CLEAN_UP in your primary script to perform 
#    clean up tasks for your script.
# * Include RP_LOGGER_DONE function call at the end of the script to gracefully terminate.


RP_LOGGER_CLEAN_UP_MSG="Script finished."
log() {
        LASTLOGMSG=$1
        LASTLOGTYPE=$2
        if [ "$2" == "info" ]; then
                typemsg="INFO   "
        elif [ "$2" == "warn" ]; then
                typemsg="WARNING"
        elif [ "$2" == "fatal" ]; then
                typemsg="FATAL  "
        else
                typemsg="INFO   "
        fi
        printf "[ %s ] %s\t:\t%s\n"  "$(date +'%T')" "$typemsg" "$LASTLOGMSG"
}

log_info() {
        log "$@" "info"
}

log_warn() {
        log "$@" "warn"
}

log_fatal() {
        log "$@" "fatal"
}

die_with_honor() {
        cmd=$BASH_COMMAND
        msg=$LASTLOGMSG
        if [ "$msg" == "$RP_LOGGER_CLEAN_UP_MSG" ]; then exit 0; fi
        log_warn "Script ended prematurely"
        log_fatal "Failed at : $msg ($cmd)"
	RP_LOGGER_CLEAN_UP
        exit 0
}

RP_LOGGER_DONE() {
	log_info "$RP_LOGGER_CLEAN_UP_MSG"
}

RP_LOGGER_CLEAN_UP() {
	log_info "Cleaning up."
}


trap die_with_honor EXIT

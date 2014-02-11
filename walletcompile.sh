 #!/bin/bash
if [ ! "$BASH_VERSION" ] ; then
	/bin/bash $0 $@
	exit 1
fi
set -e
#ALL PATH VARIABLES SHOULD HAVE A TRAILING SLASH

#PATHS
SOURCESPATH=./sources/
DAEMONPATH=./daemons/
REPOS=
REPOSCOUNT=0

source "./inc.logger.sh"


list_all_repositories() {
	local list=`echo ${REPOS}`
	log_info "Detected $REPOSCOUNT repositories on this platform."
	log_info "List: $list"
}

get_repo_path() {
	local repo=$1
	echo $SOURCESPATH$repo"/src/"
}

compile_repository() {
	local repo=$1
	local repodir=$(get_repo_path ${repo})
	if [ ! -d "$repodir" ] ; then
		log_warn "$repo does not exist."
		return
	fi
	log_info "Compiling $repo"
	cd $repodir && make
	log_info "Installing $repo"
	if [ ! -f "$repodir$repo" ] ; then
		log_warn "Could not detect binary for $repo."
		return
	fi
	log_info "Copying $repo to daemons path."
	if [ -f "$DAEMONPATH$repo" ] ; then
		log_info "$repo binary found in $DAEMONPATH. Making backup."
		cp $DAEMONPATH$repo "$DAEMONPATH$repo$(date +%s).bak"
	fi
	cp $repodir$repo $DAEMONPATH$repo
}

clone_repository() {
	local url=$1
	local repo=$2
	git clone $url $SOURCESPATH$repo && return 1
}

download_and_extract_repository() {
	local url=$1
	local repo=$2
	log_fatal "TODO: Implement this feature."
}

update_repository() {
	local repo=$1
	local repodir=$(get_repo_path ${repo})
	if [ ! -d "${repodir}../.git" ] ; then
		log_warn "$repodir is not a git repository."
		return 0
	fi
	cd ${repodir}../ && git checkout . && git pull && return 1
}

update_all() {
	local loop=0
	for i in ${REPOS[*]}; do
		loop=$[loop+1]
		log_info "Updating repository $loop/$DAEMONCOUNT ($i)..."
		update_repository $i && compile_repository $i
	done
}

log_info "Initializing script"
cd $SOURCESPATH && REOPOS=`find  -maxdepth 1 -type d ! -path . | awk '{ sub(/\.\//,""); print }'`
for i in ${DAEMONS[*]}; do
	REPOSCOUNT=$[REPOSCOUNT+1]
done
list_all_repositories
if [ "$1" == "update" ]; then
	log_info "Updating all daemons."
	update_all
elif [ "$1" == "git" ]; then
	if [[ -z "$2" ] || [ -z "$3" ]]; then
		log_fatal "Incorrect number of arugments. <script> git <repo> <coin name>"
		exit 1
	fi
	log_info "Cloning git repository."
	clone_repository $2 $3 && compile_repository $3
else
	log_fatal "Unknown action. Syntax: scriptname.sh <update|git>"
	exit 1
fi
log_info "All done"
RP_LOGGER_DONE

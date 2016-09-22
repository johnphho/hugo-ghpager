#!/bin/zsh

#TODO:  convert to JSON and use jq to read configuration
# GITHUB
github_username="johnphho"
github_access_key=[FILL IN REQUIRED]
ghpage_source_repo=johnphho.github.io.source
ghpage_public_repo=johnphho.github.io

# DYNAMIC
github_url="git@github.com:${github_username}"

# CIRCLECI
circleci_access_key=[FILL IN REQUIRED]

# HUGO
hugo_baseurl="https://johnphho.github.io/"
hugo_theme="future-imperfect"

# SCRIPT
current_path=$(pwd)
current_script=$(basename ${(%):-%x})
has_repo="false"

### BEGIN PREREQUISITES ###

get_jq() {
    ENTRY
    curl -s http://stedolan.github.io/jq/download/linux64/jq -o jq
    chmod +x jq
    RETURN
}

### END PREREQUISITES ###

### BEGIN LOGGER - BASED ON http://www.cubicrace.com/2016/03/efficient-logging-mechnism-in-shell.html ###

SCRIPT_LOG=hugo-ghpage.log

function SCRIPTENTRY(){
    printf "%30.30s\n" "${funcstack[1]}: ${current_script}" | tee -a $SCRIPT_LOG
}

function SCRIPTEXIT(){
    printf "%30.30s\n" "${funcstack[1]}: ${current_script}" | tee -a $SCRIPT_LOG
    cd ${current_path}
}

function ENTRY(){
    local cfn="${funcstack[2]}"
    local tstamp=$(date)
    local msg="> ${cfn} ${funcstack[1]}"
    printf "\t%s\t%s\n" "[$tstamp] [DEBUG]" "$msg" | tee -a  $SCRIPT_LOG
}

function RETURN(){
    local cfn="${funcstack[2]}"
    local tstamp=$(date)
    local msg="> ${cfn} ${funcstack[1]}"
    printf "\t%s\t%s\n" "[$tstamp] [DEBUG]" "$msg" | tee -a  $SCRIPT_LOG
}

function INFO()
{
    local msg="${1}"
    local tstamp=$(date)
    printf "\t%s\t%s\n" "[$tstamp] [INFO]" "$msg" | tee -a  $SCRIPT_LOG
}

function DEBUG()
{
    local msg="${1}"
    local tstamp=$(date)
    printf "\t%s\t%s\n" "[$tstamp] [DEBUG]" "$msg" | tee -a  $SCRIPT_LOG
}

function ERROR()
{
    local msg="${1}"
    local tstamp=$(date)
    printf "\t%s\t%s\n" "[$tstamp] [ERROR]" "$msg" | tee -a  $SCRIPT_LOG
}

function TESTLOGGER()
{
    ENTRY
    DEBUG "debug message"
    INFO "info message"
    RETURN
}

### END LOGGER ###

### BEGIN GITHUB ###

test_github_response(){
    ENTRY
    echo ${1} | ./jq -e 'has("message")' > /dev/null
    if [ $? -eq 0 ]; then
        ERROR "Invalid response"
        exit 1
    else
        DEBUG "Valid response"
    fi
    RETURN
}

test_github_access_key() {
    ENTRY
    INFO "${1}"
    local json=$(curl -s -H "Authorization: token ${github_access_key}" https://api.github.com)
    test_github_response ${json}
    DEBUG "Valid access key"
    RETURN
}

test_repo_exists() {
    ENTRY
    INFO "${1}"
    local json=$(curl -s -H "Authorization: token ${github_access_key}" https://api.github.com/user/repos)
    test_github_response ${json}
    echo ${json} | ./jq -e '.[] | select(.name == "'${1}'")' > /dev/null
    if [ $? -eq 0 ]; then
        DEBUG "Repo exists"
		has_repo="true"
    else
        DEBUG "Repo does not exist"
		has_repo="false"
    fi
    RETURN
}

init_git_config() {
    ENTRY
 	git config --global user.name ${github_username}
    git config --global user.email ${github_email}
    local git_config_output=$(git config --list)
	DEBUG ${git_config_output} 
	RETURN
}

init_github_repo() {
    ENTRY
    INFO "${1}"
    mkdir -p "${1}"
    cd ${1}
    find ./ -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
    git init
    if [[ "$#" -gt 1 && "${2}" = "src" ]]; then
        echo "public" > .gitignore
    fi 
    cd ..
	RETURN
}

push_github_repo() {
    ENTRY
    INFO "${1}"
	cd "${1}"
    git add --all
    git commit -m "auto first commit"
    git remote add origin git@github.com:${github_username}/${1}.git
    git push origin master
    cd ..
    RETURN
}

create_github_repo() {
    ENTRY
    INFO "${1}"
    curl -s -H "Authorization: token ${github_access_key}" https://api.github.com/user/repos -d '{"name": "'$1'"}'
	RETURN
}

delete_github_repo() {
    ENTRY
    INFO "${1}"
    curl -s -X DELETE -H "Authorization: token ${github_access_key}" https://api.github.com/repos/$github_username/${1}
    RETURN
}

delete_github_ssh_key() {
    ENTRY
    curl  -H "Authorization: token ${github_access_key}" https://api.github.com/user/keys
    RETURN
}

### BEGIN HUGO ###

create_hugo_site() {
    ENTRY
    cd ${ghpage_source_repo}
    hugo new site . --force
    cd ..
	RETURN
}

configure_hugo_site() {
    ENTRY
	cp config.toml ${ghpage_source_repo}
    RETURN
}

add_hugo_theme() {
   ENTRY
   git clone https://github.com/spf13/hugoThemes.git
   cd hugoThemes
   git submodule update --init $hugo_theme
   mkdir -p ${ghpage_source_repo}/themes
   cp -R ${hugo_theme} ../${ghpage_source_repo}/themes
   cd ..
   RETURN
}

build_hugo_site() {
   ENTRY
   cd ${ghpage_source_repo}
   hugo -v
   cd ..
   RETURN
}

create_sample_post() {
    ENTRY
    cd ${ghpage_source_repo}
    hugo new post/welcome.md
    echo "welcome post" >> content/post/welcome.md
    sed -i -r 's#draft = true#draft = false#' content/post/welcome.md
    cd ..
    RETURN
}

### END HUGO ###

### CIRCLECI ###

configure_circleci() {
   ENTRY
   cp circle.yml ${ghpage_source_repo}
   cp deploy.sh ${ghpage_source_repo}
   RETURN
}

circleci_follow_repo() {
    ENTRY
    curl -X POST -H "Content-Type: application/json" https://circleci.com/api/v1.1/project/github/${github_username}/${ghpage_source_repo}/follow\?circle-token\=${circleci_access_key}
    RETURN
}

circleci_unfollow_repo() {
    ENTRY
    curl -s  -X POST -H "Content-Type: application/json" https://circleci.com/api/v1.1/project/github/${github_username}/${ghpage_source_repo}/unfollow\?circle-token\=${circleci_access_key}
    RETURN
}

add_circleci_checkout_key() {
    ENTRY
    curl -X POST -H "Content-Type: application/json" -d '{"type":"github-user-key"}' https://circleci.com/api/v1.1/project/github/${github_username}/${ghpage_source_repo}/checkout-key\?circle-token\=${circleci_access_key}
    RETURN
}

circleci_build_repo() {
    ENTRY
    curl -X POST -H "Content-Type: application/json" https://circleci.com/api/v1.1/project/github/${github_username}/${ghpage_source_repo}\?circle-token\=${circleci_access_key}
    RETURN
}

### END CIRCLECI ###

### BEGIN MAIN ###

create() {
    ENTRY
    get_jq
    test_github_access_key
    test_repo_exists ${ghpage_source_repo}
    if [ ${has_repo} = "true" ]; then
        if [[ ${2} =  -f || ${2} = --force ]]; then
            delete_github_repo ${ghpage_source_repo}
            circleci_unfollow_repo
        else
            ERROR "Repo ${ghpage_source_repo} exists..."
            exit 1
        fi 
    else
        create_github_repo ${ghpage_source_repo}
    fi
    test_repo_exists ${ghpage_public_repo}
    if [ ${has_repo} = "true" ]; then
        if [[ ${2} =  -f || ${2} = --force ]]; then
            delete_github_repo ${ghpage_public_repo} 
        else
            ERROR "Repo ${ghpage_public_repo} exists..."
            exit 1
        fi 
    else
        create_github_repo ${ghpage_public_repo}
    fi
    init_github_repo ${ghpage_source_repo} "src"
    init_github_repo ${ghpage_public_repo}
    push_github_repo ${ghpage_public_repo}
    create_hugo_site
    configure_hugo_site
    add_hugo_theme
    build_hugo_site
    create_sample_post
    configure_circleci
    push_github_repo ${ghpage_source_repo}
    circleci_follow_repo
    add_circleci_checkout_key
    circleci_build_repo
    RETURN
}

delete() {
    ENTRY
    get_jq
    test_repo_exists ${ghpage_source_repo}
    if [ ${has_repo} = "true" ]; then
        delete_github_repo ${ghpage_source_repo}
    else
        ERROR "Repo ${ghpage_source_repo} does not exist"
    fi
    test_repo_exists ${ghpage_public_repo}
    if [ ${has_repo} = "true" ]; then
        delete_github_repo ${ghpage_public_repo}
    else
        ERROR "Repo ${ghpage_public_repo} does not exist"
    fi
    circleci_unfollow_repo
    RETURN
}


SCRIPTENTRY
case ${1} in
    -c | --create)
        create
        ;;
    -d | --delete)
        delete
        ;;
    -t | --test)
       #TEST SOMETHING
       ;;
    *)
    echo "Usage $0 {-c or --create -f --force | -d or --delete}"
    exit 1
    ;;
esac
SCRIPTEXIT

### END MAIN ###

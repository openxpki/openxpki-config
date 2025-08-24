#!/bin/bash
# Author Arnaud Crampet AKA doraken
# automating realms base cnfiguration directory.
# Mail : doraken@doraken.net

Realm_Name="${1}"
directory_list="${Realm_Name} ${Realm_Name}/profile ${Realm_Name}/notification ${Realm_Name}/workflow ${Realm_Name}/workflow/def"
removed_workflow="./workflow/def/certificate_export.yaml  ./workflow/def/certificate_revoke_by_entity.yaml ./workflow/def/report_list.yaml"


function create_directory () 
{ 
### call : create_directory "Mydir" 
### result : 
###         1) check if inputed variable is null 
###         2) chek if directory is already created 
###         4) create directory 
###         5) control created directory
    _dir="${1}"

    if [ -z ${_dir} ]
       then 
           echo "Error on create_directory call" 
           exit 125
    fi 

    if [ -d ${_dir} ] 
       then 
           echo "directory : ${_dir} ---> Already created "
       else 
          mkdir -p ${_dir} 
          if [ -d ${_dir}  ] 
             then 
                  echo "directory : ${_dir} ---> created "
              else 
                  echo "Error on create_directory call"  
                  exit 4
          fi
    fi
}


function remove_files ()
{
### call : remove_files "file" 
### result : 
###         1) check if inputed variable is null 
###         2) chek if file exist
###         4) remove existing file

    _removed_file="${1}"
    if [ -z ${_removed_file} ] 
      then 
           echo "Error on remove_files call" 
           exit 125
    fi 

    if [ -f  ${_removed_file} ] 
       then 
           rm  ${_removed_file}
           echo "file removed : ${_removed_file}"
       else 
           echo "file already removed"
    fi 

}


function check_realms_root_dir ()
{
### call : check_realms_root_dir 
### result : 
###         1) check if realm root dir exist
###         2) take ${directory_list} to call create_directory

    if [ -d ${Realm_Name} ] 
    then 
        echo " realms already present" 
        exit 4
    else 
        for dorectory in ${directory_list}
            do 
                create_directory ${dorectory}
        done 
    fi 
}

function generate_realm ()
{
    check_realms_root_dir
    cd ${Realm_Name}
    ln -s ../../realm.tpl/api/
    ln -s ../../realm.tpl/auth/
    ln -s ../../realm.tpl/crl/
    ln -s ../../realm.tpl/crypto.yaml
    ln -s ../../realm.tpl/uicontrol/
    ln -s ../../../realm.tpl/workflow/global workflow/
    ln -s ../../../realm.tpl/workflow/persister.yaml workflow/
    ln -s ../../../realm.tpl/profile/template/ profile/
    (cd workflow/def/ && find ../../../../realm.tpl/workflow/def/ -type f | xargs -L1 ln -s)
    cp ../../realm.tpl/profile/default.yaml profile/
    cp ../../realm.tpl/notification/smtp.yaml.sample notification/smtp.yaml
 
    for file in ${removed_workflow}
      do 
        remove_files "${file}"
    done 
}

### check realm parameter
if [ -z ${Realm_Name} ]
   then
       echo " error realm set to : NULL "
       exit 1
   else
       echo "Realms set to : ${Realm_Name} "
       generate_realm
fi

        

#!/bin/sh

################################################################################
#
# HRMake.sh
#
# Author: Heverton Rodrigues <heverton25@gmail.com>
# Date: 2016-08-03
# Version: 0.1
#
# Project Description
#
# One simple rule:
#
# Usage:
#
#   sudo chmod +x create.sh
#   create.sh and follow the steps
#
################################################################################



OLDNAME="HRPRODUCTNAME"
OLDBUNDLE="HRBUNDLEID"
OLDORGANIZATION="HRORGANIZATION"
NEWNAME="DEFAULTNAME"
BUNDLEID="DEFAULTBUNDLE"
ORGANIZATION="DEFAULTORGANIZATION"


echo "Set the project name"

read NAME
NEWNAME=$(echo "${NAME}" | sed -e "s/[^a-zA-Z0-9_-]//g")


echo "Set your organization"
read TMPORGANIZATION
ORGANIZATION=$(echo "${TMPORGANIZATION}" | sed -e "s/[^a-zA-Z0-9_-]//g")


TMPBUNDLEID="com.$ORGANIZATION.$NEWNAME"
echo "Your bundle ID will be: $TMPBUNDLEID, want to confirm?"
read -p "[Y/n]: " OPT
if [ "$OPT" == "n" ]; then
  echo "Enter your customized bundle id"
  read TMPBUNDLEID
fi
BUNDLEID=$(echo "${TMPBUNDLEID}" | sed -e "s/[^.a-zA-Z0-9_-]//g")

echo "${BUNDLEID}" | grep ".${NEWNAME}" > /dev/null
if [ $? -eq 0 ]; then
  BUNDLEID=$(echo $BUNDLEID | sed -e "s/.$NEWNAME//g")
fi


tar -zxf "projects/$OLDNAME.tar.gz"


#Validations

TMPFILE=/tmp/xcodeRename.$$

if [ -d "${NEWNAME}" -o "$NEWNAME" = "" ]; then
  echo "Invalid Name"
  exit
fi

echo "${NEWNAME}" | grep "${OLDNAME}" > /dev/null
if [ $? -eq 0 ]; then
  echo "Invalid Name"
  exit
fi

# be sure tmp file is writable
cp /dev/null ${TMPFILE}
if [ $? -ne 0 ]; then
  echo "tmp file ${TMPFILE} is not writable. Terminating."
  exit
fi


# copy project directory
echo "Creating Project ${NEWNAME}"
mv "${OLDNAME}" "${NEWNAME}"


#find text files, replace text
find "${NEWNAME}/." | while read currFile
do
  # find files that are of type text
  file "${currFile}" | grep "text" > /dev/null
  if [ $? -eq 0 ]; then


    # Renaming Organization
    grep "${OLDORGANIZATION}" "${currFile}" > /dev/null
    if [ $? -eq 0 ]; then
       sed -e "s/${OLDORGANIZATION}/${ORGANIZATION}/g" "${currFile}" > ${TMPFILE}
       mv ${TMPFILE} "${currFile}"
       cp /dev/null ${TMPFILE}
    fi

    # Renaming Bundle ID
    grep "${OLDBUNDLE}" "${currFile}" > /dev/null
    if [ $? -eq 0 ]; then
       sed -e "s/${OLDBUNDLE}/${BUNDLEID}/g" "${currFile}" > ${TMPFILE}
       mv ${TMPFILE} "${currFile}"
       cp /dev/null ${TMPFILE}
    fi



    # Renaming Project Name
    grep "${OLDNAME}" "${currFile}" > /dev/null
    if [ $? -eq 0 ]; then
       sed -e "s/${OLDNAME}/${NEWNAME}/g" "${currFile}" > ${TMPFILE}
       mv ${TMPFILE} "${currFile}"
       cp /dev/null ${TMPFILE}
    fi



  fi

done



# rename directories
find "${NEWNAME}/." -type dir | while read currFile
do
  echo "${currFile}" | grep "${OLDNAME}" > /dev/null
  if [ $? -eq 0 ]; then
    MOVETO=`echo "${currFile}" | sed -e "s/${OLDNAME}/${NEWNAME}/g"`
    mv "${currFile}" "${MOVETO}" 2> /dev/null
  fi
done

# rename files
find "${NEWNAME}/." -type file | while read currFile
do
  echo "${currFile}" | grep "${OLDNAME}" > /dev/null
  if [ $? -eq 0 ]; then
    MOVETO=`echo "${currFile}" | sed -e "s/${OLDNAME}/${NEWNAME}/g"`
    mv "${currFile}" "${MOVETO}" 2> /dev/null
  fi
done


rm -f ${TMPFILE}


echo "Installing PODs"



cat <<EOT > $NEWNAME/Podfile
# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'
use_frameworks!

target '$NEWNAME' do

  $(echo "pod 'Fabric'\n  pod 'Crashlytics'\n  pod 'Alamofire'")

end
EOT


echo $(cd $NEWNAME && pod install && git init && git add . && git commit -m "Initial Commit" && open "$NEWNAME.xcworkspace") > /dev/null


echo finished.

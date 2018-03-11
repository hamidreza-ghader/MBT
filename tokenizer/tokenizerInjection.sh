#!/bin/sh
EXTERNAL_PATH=/home/hghader1/projects/oister_workspace/oister/install/external_components/moses

#Clean up after the script before existing
function clean() {
    #Remove the template file
    :rm -f ${TEMPL_FILE}

}

#Get this script actual location to find utility scripts
SCRIPT=$(readlink "${0}")
BASEDIR=$(dirname "$0")

#Include the utils
. ${BASEDIR}/process_utils.sh

#Define the script type
export SCRIPT_TYPE="pre"

#Process the script parameters
. ${BASEDIR}/process_params.sh

#Run the pre-processing script

${BASEDIR}/tokenizer.pl --input-file=${INPUT_FILE} --output-file=${OUTPUT_FILE} --language=${LANGUAGE} --external-path=${EXTERNAL_PATH}
#DEBUG: Create back files for ananlysis
#cp ${INPUT_FILE} ${INPUT_FILE}.bak
#cp ${TEMPL_FILE} ${TEMPL_FILE}.bak
#cp ${OUTPUT_FILE} ${OUTPUT_FILE}.bak

rc=$?
if [[ $rc != 0  ]]; then
    echo `cat ${OUTPUT_FILE}`
    clean
    exit $rc;
fi



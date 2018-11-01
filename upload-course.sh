#!/bin/bash
#
# version: 2.0.0
# data: 20181101

source ./include/colors.sh
source ./include/usage.sh
source ./include/test_functions.sh
source ./include/course_publishing_functions.sh

##############################################################################
#        Variables
##############################################################################

if [ -z ${1} ]
then
  usage
  exit 1
fi

cd $(dirname ${0})
SCRIPT_DIR=$(pwd)

if [ -d ${1} ]
then
  if ! ls ${1} | grep -q ".cfg"
  then
    echo
    echo -e "${LTRED}ERROR: No configuration files were found in the supplied configuration file directory (${LTGRAY}${CONFIG_FILE}${LTRED}). Exiting.${NC}"
    echo
    exit 2
  else
    CONFIG_FILE_LIST=$(ls ${1})
    CONFIG_FILE_DIR="${1}/"
  fi
else
  if ! [ -e ${1} ]
  then
    echo
    echo -e "${LTRED}ERROR: The supplied configuration file (${LTGRAY}${CONFIG_FILE}${LTRED}) is not found. Exiting.${NC}"
    echo
    exit 2
  else
    CONFIG_FILE_LIST="${1}"
  fi
fi



##############################################################################
#        Functions
##############################################################################


##############################################################################
#        Main Function
##############################################################################

main() {
  source ${CONFIG_FILE_DIR}${CONFIG_FILE}

  LAB_ENV_SRC_DIR="${COURSES_BASE_DIR}/${COURSE_ID}/${COURSE_VER}/lab_environment"
  PDF_SRC_DIR="${COURSES_BASE_DIR}/${COURSE_ID}/${COURSE_VER}/manuals_and_slides/pdf"
  RECORDING_SRC_DIR="${COURSES_BASE_DIR}/${COURSE_ID}/${COURSE_VER}/recordings"

  COURSE_TMP_BASE_DIR="${COURSES_STAGING_BASE_DIR}"
  if ! [ -e ${COURSE_TMP_BASE_DIR} ]
  then
    echo -e "${LTGREEN}COMMAND: ${GRAY} mkdir -p ${COURSE_TMP_BASE_DIR}${NC}"
    mkdir -p ${COURSE_TMP_BASE_DIR}
    echo
  fi

  TIMESTAMP="$(date +%Y%m%d-%s)"
  COURSE_TMP_DIR="${COURSE_TMP_BASE_DIR}/${COURSE_ID}-${COURSE_VER}_${TIMESTAMP}"

  test_for_required_vars

  echo
  echo -e "${BLUE}======================================================================================${NC}"
  echo -e "${BLUE}                         ${SCRIPT_BANNER_TEXT}${NC}"
  echo -e "${BLUE}                 ----------------------------------------${NC}"
  echo
  echo -e "${BLUE} Uploading Course: ${COURSE_ID} version: ${COURSE_VER}${NC}"
  echo
  echo -e "${BLUE} From: ${COURSES__BASE_DIR}${NC}"
  echo -e "${BLUE} To:   ${COURSE_UPLOAD_SERVER}${COURSE_UPLOAD_BASE_DIR}${NC}"
  echo
  echo
  echo -e "${BLUE}======================================================================================${NC}"
  echo

  case ${COURSE_UPLOAD_PROTOCOL}
  in
    FTP|ftp|SFTP|sftp)
      if [ -z ${USER_NAME} ]
      then
        echo -ne "${BLUE}Enter your username for - ${LTPURPLE}${COURSE_UPLOAD_SERVER}${BLUE}: ${NC}" ; read USER_NAME
      fi
      if [ -z ${USER_PASS} ]
      then
        echo -ne "${BLUE}Enter your password for - ${LTPURPLE}${USER_NAME}@${COURSE_UPLOAD_SERVER}${BLUE}: ${NC}" ; read -s USER_PASS
      fi
    ;;
  esac

  gather_files_to_upload

  case ${REPLACE_PDF_COVER_PAGES}
  in
    Y|y|Yes|YES)
      replace_pdf_cover_pages
    ;;
  esac

  case ${COVER_LOGO_PDFS}
  in
    Y|y|Yes|YES)
      cover_logo_pdfs ${PDF_COVER_LOGO_TO_USE}
    ;;
  esac

  case ${WATERMARK_PDFS}
  in
    Y|y|Yes|YES)
      watermark_pdfs ${PDF_WATERMARK_TO_USE}
    ;;
  esac

  case ${CREATE_PDF_ARCHIVE_FILE}
  in
    Y|y|Yes|YES)
      create_pdf_archive_file
    ;;
  esac

  case ${CONCATENATE_PDF_FILES}
  in
    Y|y|Yes|YES)
      concatenate_pdf_files
    ;;
  esac

  if [ -z ${COURSE_UPLOAD_PROTOCOL} ]
  then
    COURSE_UPLOAD_PROTOCOL=FTP
  fi

  case ${COURSE_UPLOAD_PROTOCOL}
  in
    FTP|ftp)
      ftp_upload_course_files
    ;;
    SFTP|sftp)
      sftp_upload_course_files
    ;;
    LOCAL|local)
      local_upload_course_files
    ;;
  esac

  case ${CREATE_LIST_OF_UPLOADED_FILES}
  in
    Y|y|Yes|YES)
      create_file_list
    ;;
  esac

  case ${PRESERVE_STAGING_FILES}
  in
    Y|y|Yes|YES)
      echo
      echo -e "${ORANGE}WARNING: The staging files (${GRAY}${COURSE_TMP_DIR}${ORANGE}) were not removed. Pleasce manualy remove them before running this command again.${NC}"
      echo
    ;;
    *)
      clean_up_tmp_files
    ;;
  esac

  echo -e "${GRAY}Time to complete:${NC}"
  echo -en "${GRAY}-----------------${NC}"
}

##############################################################################
#        Code Body
##############################################################################

for CONFIG_FILE in ${CONFIG_FILE_LIST}
do
  time main $*
  echo -e "${GRAY}-----------------${NC}"
  echo
done
echo
echo -e "${BLUE}===================================  Finished  ======================================${NC}"
echo

echo

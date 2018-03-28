# Functions for the course publishing scripts
#
# version: 1.0.0
# date: 20180327
#
#  echo -e "${LTGREEN}COMMAND: ${GRAY}${NC}"

gather_files_to_upload() {
  echo
  echo -e "${LTCYAN}Creating new staging directory of course files ...${NC}"
  echo -e "${LTCYAN}----------------------------------------------------------------${NC}"

  echo -e "${LTGREEN}COMMAND: ${GRAY}mkdir -p ${COURSE_TMP_DIR}${NC}"
  mkdir -p ${COURSE_TMP_DIR}
  echo

  # PDFs
  case ${UPLOAD_PDFS}
  in
    y|Y|yes|Yes|YES)
      echo -e "${LTCYAN}  -Copying the course PDFs to the staging directory ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY} cp -Rv ${PDF_SRC_DIR}/*.pdf ${COURSE_TMP_DIR}/${NC}"
      cp -Rv ${PDF_SRC_DIR}/*.pdf ${COURSE_TMP_DIR}/

      case ${UPLOAD_SLIDES}
      in
        n|N|no|No|NO)
          echo -e "${LTCYAN}  -Removing Slides PDF from the staging directory ...${NC}"
          echo -e "${LTGREEN}COMMAND: ${GRAY} rm -f ${COURSE_TMP_DIR}/SLIDES*.pdf${NC}"
          rm -f ${COURSE_TMP_DIR}/SLIDES*.pdf
        ;;
      esac

      echo
    ;;
  esac

  # Lab Environment
  case ${UPLOAD_LAB_ENV}
  in
    y|Y|yes|Yes|YES)
      echo -e "${LTCYAN}  -Copying the lab environment files to the staging directory ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY} cp ${LAB_ENV_SRC_DIR}/* ${COURSE_TMP_DIR}/${NC}"
      cp -v ${LAB_ENV_SRC_DIR}/* ${COURSE_TMP_DIR}/
      echo
    ;;
  esac

  # Recordings
  case ${UPLOAD_RECORDINGS}
  in
    y|Y|yes|Yes|YES)
      echo -e "${LTCYAN}  -Copying the recordings to the staging directory ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY} cp -Rv ${RECORDING_SRC_DIR}/* ${COURSE_TMP_DIR}/${NC}"
      cp -Rv ${RECORDING_SRC_DIR}/* ${COURSE_TMP_DIR}/
      echo
    ;;
  esac
}


watermark_pdfs() {
  # Function must be called with an argument for the watermark type
  # Example:  watermark_pdfs Internal
  #
  # The watermark template pdf must be named: watermark-${1}.pdf
  # ( Where ${1} is Internal in the example above: i.e. watermark-Internal.pdf )

  if [ -z ${1} ]
  then
    echo -e "${LTRED}ERROR: Function watermark_pdfs was called without an argument${NC}"
    return 1
  fi

  local WATERMARK=${1}
  local PDF_TEMPLATE="${PDF_WATERMARK_TEMPLATE_DIR}/watermark-${WATERMARK}.pdf"

  case ${WATERMARK}
  in
    none|NONE|None)
      echo -e "${LTBLUE}(Watermarking disabled in config file. Skipping ...)${NC}"
      echo
    ;;
    *)
      cd ${COURSE_TMP_DIR}
  
      local PDF_LIST=$(ls *.pdf)
  
      if which pdftk > /dev/null 2>&1
      then
        echo
        echo -e "${LTCYAN}Watermarking PDFs ..."
        echo -e "${LTCYAN}----------------------------------------------------------------${NC}"
  
        for PDF in ${PDF_LIST}
        do
          if [ -e ${PDF_TEMPLATE} ]
          then
            if echo ${PDF} | grep -q -E '^LAB|^LECTURE'
            then
              echo -e "${LTBLUE}  -${PDF}${NC}"
              echo -e "${LTGREEN}  COMMAND: ${GRAY} pdftk ${PDF} multistamp ${PDF_TEMPLATE} output $(echo ${PDF} | sed "s/\.pdf/\.${WATERMARK}\.pdf/g")${NC}"
              pdftk ${PDF} multistamp ${PDF_TEMPLATE} output $(echo ${PDF} | sed "s/\.pdf/\.${WATERMARK}\.pdf/g")
   
              echo -e "${LTGREEN}  COMMAND: ${GRAY} rm -f ${PDF}${NC}"
              rm -f ${PDF}
            fi
          else
            echo -e "${ORANGE}WARNING: The watermark template does not seem to be present.${NC}"
            echo -e "${ORANGE}         Continuing without watermarking the PDF ...${NC}"
          fi
        done
  
        echo
      else
        echo -e "${ORANGE}WARNING: The pdftk command does not seem to be present.${NC}"
        echo -e "${ORANGE}         Continuing without watermarking the PDF ...${NC}"
      fi
    ;;
  esac
}


create_pdf_archive_file(){
  echo
  echo -e "${LTCYAN}Creating pdf archive file ...${NC}"
  echo -e "${LTCYAN}----------------------------------------------------------------${NC}"

  cd ${COURSE_TMP_DIR}

  echo -e "${LTGREEN}COMMAND: ${GRAY} zip ${COURSE_ID}-${COURSE_VER}.zip *.pdf${NC}"
  zip ${COURSE_ID}-${COURSE_VER}.zip *.pdf

  echo -e "${LTGREEN}COMMAND: ${GRAY} rm -f *.pdf${NC}"
  rm -f *.pdf

  echo
}


concatenate_pdf_files() {
  echo
  echo -e "${LTCYAN}Concatenating pdf files ...${NC}"
  echo -e "${LTCYAN}----------------------------------------------------------------${NC}"

  cd ${COURSE_TMP_DIR}

  echo -e "${LTGREEN}COMMAND: ${GRAY} pdftk LECTURE_MANUAL-*.pdf LAB_MANUAL-*.pdf cat output ${CONCATENATE_PDF_FILE_PREFIX}-${COURSE_ID}-${COURSE_VER}.pdf${NC}"
  pdftk LECTURE_MANUAL-*.pdf LAB_MANUAL-*.pdf cat output ${CONCATENATE_PDF_FILE_PREFIX}-${COURSE_ID}-${COURSE_VER}.pdf

  echo -e "${LTGREEN}COMMAND: ${GRAY} rm -f LECTURE_MANUAL-*.pdf ; rm -f LAB_MANUAL-*.pdf${NC}"
  rm -f LECTURE_MANUAL-*.pdf
  rm -f LAB_MANUAL-*.pdf

  echo
}


ftp_upload_course_files() {
  #local FTP_CMD="ftp -inv"
  local FTP_CMD="ncftp -u ${USER_NAME} -p ${USER_PASS}"
  echo
  echo -e "${LTCYAN}Uploading course files to server (FTP) ...${NC}"
  echo -e "${LTCYAN}----------------------------------------------------------------${NC}"

  echo -e "${LTGREEN}COMMAND: ${GRAY} cd ${COURSE_TMP_DIR}${NC}"
  cd ${COURSE_TMP_DIR}
  echo -e "${LTGREEN}COMMAND: ${GRAY} ${FTP_CMD} ${COURSE_UPLOAD_SERVER}; mkdir ${COURSE_UPLOAD_DIR}; cd ${COURSE_UPLOAD_DIR}; mput -r *${NC}"
  ${FTP_CMD} ${COURSE_UPLOAD_SERVER} << END_OF_FTP_SCRIPT
mkdir ${COURSE_UPLOAD_DIR}
cd ${COURSE_UPLOAD_DIR}
mput -r *
quit
END_OF_FTP_SCRIPT

  echo
}


sftp_upload_course_files() {
  local SFTP_CMD="sshpass -e sftp"
  echo
  echo -e "${LTCYAN}Uploading course files to server (SFTP) ...${NC}"
  echo -e "${LTCYAN}----------------------------------------------------------------${NC}"

  echo -e "${LTGREEN}COMMAND: ${GRAY} cd ${COURSE_TMP_DIR}${NC}"
  cd ${COURSE_TMP_DIR}
  echo -e "${LTGREEN}COMMAND: ${GRAY} ${SFTP_CMD} ${USER_NAME}@${COURSE_UPLOAD_SERVER}; mkdir ${COURSE_UPLOAD_DIR}; cd ${COURSE_UPLOAD_DIR}; put -r *${NC}"
  export SSHPASS=${USER_PASS}
  ${SFTP_CMD} ${USER_NAME}@${COURSE_UPLOAD_SERVER} << END_OF_SFTP_SCRIPT
mkdir ${COURSE_UPLOAD_DIR}
cd ${COURSE_UPLOAD_DIR}
put -r *
quit
END_OF_SFTP_SCRIPT
  echo
}


nfs_upload_course_files() {
  echo
  echo -e "${LTCYAN}Uploading course files to server (NFS) ...${NC}"
  echo -e "${LTCYAN}----------------------------------------------------------------${NC}"

  local NFS_UPLOAD_MOUNT_POINT="${HOME}/nfs_temp"

  if ! [ -e ${NFS_UPLOAD_MOUNT_POINT} ]
  then
    echo -e "${LTCYAN}  -Creating NFS upload mount point directory ...${NC}"
    echo -e "${LTGREEN}  COMMAND: ${GRAY} mkdir -p ${NFS_UPLOAD_MOUNT_POINT}${NC}"
    mkdir -p ${NFS_UPLOAD_MOUNT_POINT}
  fi

  if ! mount | grep -q ${NFS_UPLOAD_MOUNT_POINT}
  then
    echo -e "${LTCYAN}  -Mounting NFS directory on server ...${NC}"
    echo -e "${LTGREEN}  COMMAND: ${GRAY} sudo mount ${COURSE_UPLOAD_SERVER}:${COURSE_UPLOAD_DIR} ${NFS_UPLOAD_MOUNT_POINT}${NC}"
    sudo mount ${COURSE_UPLOAD_SERVER}:${COURSE_UPLOAD_DIR} ${NFS_UPLOAD_MOUNT_POINT}
    local DO_MOUNT=Y
  fi

  cd ${COURSE_TMP_DIR}

  #FIXME
  if ! [ -d "${NFS_UPLOAD_MOUNT_POINT}/$(basename ${COURSE_UPLOAD_DIR})" ]
  then
    echo -e "${LTCYAN}  -Creating ${NFS_UPLOAD_MOUNT_POINT}/$(basename ${COURSE_UPLOAD_DIR}) ...${NC}"
    echo -e "${LTGREEN}  COMMAND: ${GRAY} mkdir -p ${NFS_UPLOAD_MOUNT_POINT}/$(basename ${COURSE_UPLOAD_DIR})${NC}"
    mkdir -p ${NFS_UPLOAD_MOUNT_POINT}/$(basename${COURSE_UPLOAD_DIR})
  fi

  echo -e "${LTCYAN}  -Copying files ...${NC}"
  echo -e "${LTGREEN}  COMMAND: ${GRAY} cp -R * ${NFS_UPLOAD_MOUNT_POINT}${NC}"
  cp -R * ${NFS_UPLOAD_MOUNT_POINT}

  case ${DO_MOUNT}
  in
    Y)
      echo -e "${LTCYAN}  -Unmounting NFS directory on server ...${NC}"
      echo -e "${LTGREEN}COMMAND: ${GRAY} sudo umount ${NFS_UPLOAD_MOUNT_POINT}${NC}"
      sudo umount ${NFS_UPLOAD_MOUNT_POINT}
    ;;
  esac
  echo
}


local_upload_course_files() {
  echo
  echo -e "${LTCYAN}Uploading course files to server (LOCAL) ...${NC}"
  echo -e "${LTCYAN}----------------------------------------------------------------${NC}"

  cd ${COURSE_TMP_DIR}
  
  if ! [ -d ${COURSE_UPLOAD_DIR} ]
  then
    echo -e "${LTCYAN}  -Creating ${COURSE_UPLOAD_DIR} ...${NC}"
    echo -e "${LTGREEN}  COMMAND: ${GRAY} mkdir -p ${COURSE_UPLOAD_DIR}${NC}"
    mkdir -p ${COURSE_UPLOAD_DIR}
  fi

  echo -e "${LTCYAN}  -Copying files ...${NC}"
  echo -e "${LTGREEN}  COMMAND: ${GRAY} cp -R * ${COURSE_UPLOAD_DIR}${NC}"
  cp -R * ${COURSE_UPLOAD_DIR}

  echo
}


create_file_list() {
  echo
  echo -e "${LTCYAN}Creating file (${GRAY}${URL_FILE}${LTCYAN}) with URLs for uploaded files ...${NC}"
  echo -e "${LTCYAN}----------------------------------------------------------------${NC}"
  echo
  cd ${COURSE_TMP_DIR}

  rm -rf ${URL_FILE}

  for FILE in $(ls)
  do
    if [ -f ${FILE} ]
    then
      echo ${SERVER_BASE_ACCESS_URL}/${COURSE_ID}/${FILE} | tee -a ${URL_FILE}
    fi
  done

  for DIR in $(ls)
  do 
    if [ -d ${DIR} ]
    then
      local DIR_LIST=$(ls ${DIR})
    fi

    for FILE in ${DIR_LIST}
    do 
      echo ${SERVER_BASE_ACCESS_URL}/${COURSE_ID}/${DIR}/${FILE} | tee -a ${URL_FILE}
    done
  done
  echo
}


clean_up_tmp_files() {
  echo
  echo -e "${LTCYAN}Cleaning up staging files ...${NC}"
  echo -e "${LTCYAN}----------------------------------------------------------------${NC}"
  echo -e "${LTGREEN}COMMAND: ${GRAY} rm -rf ${COURSE_TMP_BASE_DIR}/${COURSE_ID}/${NC}"
  rm -rf ${COURSE_TMP_BASE_DIR}/${COURSE_ID}/
  echo
}


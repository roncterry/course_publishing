# Functions for the course publishing scripts
#
# version: 2.1.0
# date: 20200903
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


replace_pdf_cover_pages() {
  local NEW_LAB_MANUAL_COVER=$(ls COVER_LAB_MANUAL*.pdf)
  local NEW_LECTURE_MANUAL_COVER=$(ls COVER_LECTURE_MANUAL*.pdf)

  cd ${COURSE_TMP_DIR}

  local PDF_LIST=$(ls *.pdf)

  if which pdftk > /dev/null 2>&1
  then
    echo
    echo -e "${LTCYAN}Replacing PDF Covers ..."
    echo -e "${LTCYAN}----------------------------------------------------------------${NC}"

    for PDF in ${PDF_LIST}
    do
      if echo ${PDF} | grep -q -E '^LAB|^LECTURE'
      then
        local PDF_BACKUP=$(echo ${PDF} | sed "s/\.pdf/\.backup\.pdf/g")
        local PDF_NO_COVER=$(echo ${PDF} | sed "s/\.pdf/\.no_cover\.pdf/g")
        local PDF_OUTPUT=${PDF}

        echo -e "${LTBLUE}  -${PDF}${NC}"
        echo -e "${LTGREEN}  COMMAND: ${GRAY} cp ${PDF} ${PDF_BACKUP}${NC}"
        cp ${PDF} ${PDF_BACKUP}

        #---- cut off cover
        echo -e "${LTGREEN}  COMMAND: ${GRAY} pdftk A=${PDF} cat A2-end output ${PDF_NO_COVER}${NC}"
        pdftk A=${PDF} cat A2-end output ${PDF_NO_COVER}

        #---- add new cover to manual
        if echo ${PDF} | grep -q "^LAB"
        then
          if ! [ -z ${NEW_LAB_MANUAL_COVER} ]
          then
            echo -e "${LTGREEN}  COMMAND: ${GRAY} pdftk A=${NEW_LAB_MANUAL_COVER} B=${PDF_NO_COVER} cat output ${PDF_OUTPUT}${NC}"
            pdftk A=${NEW_LAB_MANUAL_COVER} B=${PDF_NO_COVER} cat output ${PDF_OUTPUT}
          else
            echo -e "${LTBLUE}   (no new lab manual cover found)${NC}"
          fi
        elif echo ${PDF} | grep -q "^LECTURE"
        then
          if ! [ -z ${NEW_LECTURE_MANUAL_COVER} ]
          then
            echo -e "${LTGREEN}  COMMAND: ${GRAY} pdftk A=${NEW_LECTURE_MANUAL_COVER} B=${PDF_NO_COVER} cat output ${PDF_OUTPUT}${NC}"
            pdftk A=${NEW_LECTURE_MANUAL_COVER} B=${PDF_NO_COVER} cat output ${PDF_OUTPUT}
          else
            echo -e "${LTBLUE}   (no new lecture manual cover found)${NC}"
          fi
        fi

        #---- remove unneeded PDF files
        echo -e "${LTGREEN}  COMMAND: ${GRAY} rm -f ${PDF_BACKUP}${NC}"
        rm -f ${PDF_BACKUP}
        echo -e "${LTGREEN}  COMMAND: ${GRAY} rm -f ${PDF_NO_COVER}${NC}"
        rm -f ${PDF_NO_COVER}
        echo -e "${LTGREEN}  COMMAND: ${GRAY} rm -f ${NEW_LAB_MANUAL_COVER}${NC}"
        rm -f ${NEW_LAB_MANUAL_COVER}
        echo -e "${LTGREEN}  COMMAND: ${GRAY} rm -f ${NEW_LECTURE_MANUAL_COVER}${NC}"
        rm -f ${NEW_LECTURE_MANUAL_COVER}
      fi
    done

    echo
  else
    echo -e "${ORANGE}WARNING: The pdftk command does not seem to be present.${NC}"
    echo -e "${ORANGE}         Continuing without replacing PDF covers ...${NC}"
  fi
}


cover_logo_pdfs() {
  # Function must be called with an argument for the logo type
  # Example:  cover_logo_pdfs Academic
  #
  # The logo template pdf must be named: logo-${1}.pdf
  # ( Where ${1} is Academic in the example above: i.e. logo-Academic.pdf )

  if [ -z ${1} ]
  then
    echo -e "${LTRED}ERROR: Function logo_pdfs was called without an argument${NC}"
    return 1
  fi

  local LOGO=${1}
  local PDF_TEMPLATE="${PDF_WATERMARK_TEMPLATE_DIR}/logo-${LOGO}.pdf"

  case ${LOGO}
  in
    none|NONE|None)
      echo -e "${LTBLUE}(Logoing disabled in config file. Skipping ...)${NC}"
      echo
    ;;
    *)
      cd ${COURSE_TMP_DIR}
  
      local PDF_LIST=$(ls *.pdf)
  
      if which pdftk > /dev/null 2>&1
      then
        echo
        echo -e "${LTCYAN}Logoing PDFs ..."
        echo -e "${LTCYAN}----------------------------------------------------------------${NC}"
  
        for PDF in ${PDF_LIST}
        do
          if [ -e ${PDF_TEMPLATE} ]
          then
            if echo ${PDF} | grep -q -E '^LAB|^LECTURE'
            then
              local PDF_BACKUP=$(echo ${PDF} | sed "s/\.pdf/\.backup\.pdf/g")
              local PDF_COVER_ONLY=$(echo ${PDF} | sed "s/\.pdf/\.cover_only\.pdf/g")
              local PDF_NO_COVER=$(echo ${PDF} | sed "s/\.pdf/\.no_cover\.pdf/g")
              local PDF_COVER_ONLY_WITH_LOGO=$(echo ${PDF} | sed "s/\.pdf/\.cover_only_with_logo\.pdf/g")
              #local PDF_OUTPUT=$(echo ${PDF} | sed "s/\.pdf/\.${LOGO}\.pdf/g")
              local PDF_OUTPUT=${PDF}

              echo -e "${LTBLUE}  -${PDF}${NC}"
              echo -e "${LTGREEN}  COMMAND: ${GRAY} cp ${PDF} ${PDF_BACKUP}${NC}"
              cp ${PDF} ${PDF_BACKUP}

              #---- cut off cover
              echo -e "${LTGREEN}  COMMAND: ${GRAY} pdftk A=${PDF} cat A1 output ${PDF_COVER_ONLY}${NC}"
              pdftk A=${PDF} cat A1 output ${PDF_COVER_ONLY}

              echo -e "${LTGREEN}  COMMAND: ${GRAY} pdftk A=${PDF} cat A2-end output ${PDF_NO_COVER}${NC}"
              pdftk A=${PDF} cat A2-end output ${PDF_NO_COVER}

              #---- apply new cover graphic
              echo -e "${LTGREEN}  COMMAND: ${GRAY} pdftk ${PDF_COVER_ONLY} stamp ${PDF_TEMPLATE} output ${PDF_COVER_ONLY_WITH_LOGO}${NC}"
              pdftk ${PDF_COVER_ONLY} stamp ${PDF_TEMPLATE} output ${PDF_COVER_ONLY_WITH_LOGO}
              
              #---- recombine logoed cover with manual
              echo -e "${LTGREEN}  COMMAND: ${GRAY} pdftk A=${PDF_COVER_ONLY_WITH_LOGO} B=${PDF_NO_COVER} cat output ${PDF_OUTPUT}${NC}"
              pdftk A=${PDF_COVER_ONLY_WITH_LOGO} B=${PDF_NO_COVER} cat output ${PDF_OUTPUT}
   
              #---- remove unneeded PDF files
              echo -e "${LTGREEN}  COMMAND: ${GRAY} rm -f ${PDF_BACKUP}${NC}"
              rm -f ${PDF_BACKUP}
              echo -e "${LTGREEN}  COMMAND: ${GRAY} rm -f ${PDF_COVER_ONLY}${NC}"
              rm -f ${PDF_COVER_ONLY}
              echo -e "${LTGREEN}  COMMAND: ${GRAY} rm -f ${PDF_COVER_ONLY_WITH_LOGO}${NC}"
              rm -f ${PDF_COVER_ONLY_WITH_LOGO}
              echo -e "${LTGREEN}  COMMAND: ${GRAY} rm -f ${PDF_NO_COVER}${NC}"
              rm -f ${PDF_NO_COVER}
            fi
          else
            echo -e "${ORANGE}WARNING: The logo template does not seem to be present.${NC}"
            echo -e "${ORANGE}         Continuing without logoing the PDF ...${NC}"
          fi
        done
  
        echo
      else
        echo -e "${ORANGE}WARNING: The pdftk command does not seem to be present.${NC}"
        echo -e "${ORANGE}         Continuing without logoing the PDF ...${NC}"
      fi
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
              local PDF_OUTPUT=$(echo ${PDF} | sed "s/\.pdf/\.${WATERMARK}\.pdf/g")

              echo -e "${LTBLUE}  -${PDF}${NC}"
              echo -e "${LTGREEN}  COMMAND: ${GRAY} pdftk ${PDF} multistamp ${PDF_TEMPLATE} output ${PDF_OUTPUT}${NC}"
              pdftk ${PDF} multistamp ${PDF_TEMPLATE} output ${PDF_OUTPUT}
              #echo -e "${LTGREEN}  COMMAND: ${GRAY} pdftk ${PDF} multibackground ${PDF_TEMPLATE} output ${PDF_OUTPUT}${NC}"
              #pdftk ${PDF} multibackground ${PDF_TEMPLATE} output ${PDF_OUTPUT}
   
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
  if ! grep -q "${COURSE_UPLOAD_SERVER}" ~/.ssh/known_hosts
  then
    echo -e "${LTCYAN}(downloading the server's host key ...)${NC}"
    if host "${COURSE_UPLOAD_SERVER}" > /dev/null 2>&1
    then
      ssh-keyscan "${COURSE_UPLOAD_SERVER}",$(host "${COURSE_UPLOAD_SERVER}" | awk '{ print $4 }') >> ~/.ssh/known_hosts
    else
      ssh-keyscan "${COURSE_UPLOAD_SERVER}" >> ~/.ssh/known_hosts
    fi
    echo
  fi
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
      if echo ${FILE} | grep -Eq ".(mp4|MP4|mov|MOV|webm|WEBM|mkv|MKV)"
      then
        local FILE_DURATION=$(ffmpeg -i ${FILE} 2>&1 | grep "Duration"| cut -d ' ' -f 4 | sed s/,//)
        echo "${SERVER_BASE_ACCESS_URL}/${COURSE_ID}${COURSE_ID_APPEND}/${FILE},${FILE},${FILE_DURATION}" | tee -a ${URL_FILE}
        unset FILE_DURATION
      else
        echo "${SERVER_BASE_ACCESS_URL}/${COURSE_ID}${COURSE_ID_APPEND}/${FILE},${FILE},-"| tee -a ${URL_FILE}
      fi
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
      #echo ${SERVER_BASE_ACCESS_URL}/${COURSE_ID}/${DIR}/${FILE} | tee -a ${URL_FILE}
      if echo ${FILE} | grep -Eq ".(mp4|MP4|mov|MOV|webm|WEBM|mkv|MKV)"
      then
        local FILE_DURATION=$(ffmpeg -i ${DIR}/${FILE} 2>&1 | grep "Duration"| cut -d ' ' -f 4 | sed s/,//)
        echo "${SERVER_BASE_ACCESS_URL}/${COURSE_ID}${COURSE_ID_APPEND}/${DIR}/${FILE},${FILE},${FILE_DURATION}" | tee -a ${URL_FILE}
        unset FILE_DURATION
      else
        echo "${SERVER_BASE_ACCESS_URL}/${COURSE_ID}${COURSE_ID_APPEND}/${DIR}/${FILE},${FILE},-"| tee -a ${URL_FILE}
      fi
    done
  done
  echo
}


clean_up_tmp_files() {
  echo
  echo -e "${LTCYAN}Cleaning up staging files ...${NC}"
  echo -e "${LTCYAN}----------------------------------------------------------------${NC}"
  echo -e "${LTGREEN}COMMAND: ${GRAY} rm -rf ${COURSE_TMP_DIR}${NC}"
  rm -rf ${COURSE_TMP_DIR}
  echo
}


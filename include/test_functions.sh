# Test functions for course uploading
#
# version: 1.0.0
# date: 20180323
#

test_for_required_vars() {
  if [ -z ${COURSE_ID} ]
  then
    echo
    echo -e "${LTRED}ERROR: You must provide a Course ID. Check your config file. ${NC}"
    echo
    echo -e "${LTRED}       Exiting ...${NC}"
    echo
    exit 3
  fi

  if [ -z ${COURSE_VER} ]
  then
    echo
    echo -e "${LTRED}ERROR: You must provide a Course Version. Check your config file. ${NC}"
    echo
    echo -e "${LTRED}       Exiting ...${NC}"
    echo
    exit 3
  fi

  if [ -z ${COURSE_UPLOAD_DIR} ]
  then
    echo
    echo -e "${LTRED}ERROR: You must provide a course upload directory on the server. Check your config file. Exiting ...${NC}"
    echo
    echo -e "${LTRED}       Exiting ...${NC}"
    echo
    exit 3
  fi

}

test_for_source_files() {
  if ! [ -e ${COURSES_BASE_DIR}/${COURSE_ID}/${COURSE_VER} ]
  then
    echo
    echo -e "${LTRED}ERROR: The course source directory (${LTGRAY}${COURSES_BASE_DIR}/${COURSE_ID}/${COURSE_VER}${LTRED}) can't be found.${NC}"
    echo
    echo -e "${LTRED}       Exiting ...${NC}"
    echo
    exit 4
  fi
}

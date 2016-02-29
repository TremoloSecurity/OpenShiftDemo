#!/bin/bash

downloadComponent() {
  COMP_NAME=$1
  URL_BASE=$2
  FILE_NAME=$3
  DIR_NAME=$4

  echo "Downloading $COMP_NAME from $URL_BASE/$FILE_NAME"
  wget $URL_BASE/$FILE_NAME -O /tmp/$FILE_NAME

  echo "Deploying $COMP_NAME"
  rm -rf /usr/local/tomcat/webapps/$DIR_NAME
  mkdir /usr/local/tomcat/webapps/$DIR_NAME
  unzip /tmp/$FILE_NAME -d /usr/local/tomcat/webapps/$DIR_NAME/
}

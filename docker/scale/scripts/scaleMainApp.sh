#!/bin/bash

. /usr/local/tomcat/bin/downloadScale.sh


downloadComponent "Scale Main Application" \
                  "$SCALE_MAIN_SOURCE_URL"  \
                  "$SCALE_MAIN_WAR" \
                  "$SCALE_APP_PATH"

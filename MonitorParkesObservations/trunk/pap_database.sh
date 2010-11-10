#!/bin/bash

#
# Execute whatever argument is given as a mysql command on the
# kho018_pulseatparkes database. Must be run from herschel.
# Uses temp file /tmp/mysql.cmd to store the command because
# I have no idea about parsing it correctly.
#
# Author: Jonathan Khoo
# Date:   10.11.10
#

db_name=kho018_pulseatparkes
db_password=Chozae5+u
db_user=pulseadmin

mysql_cmd=$1
TEMP_MYSQL_CMD=/tmp/mysql.cmd

# Use a temporary file to store the mysql command.
echo $mysql_cmd > $TEMP_MYSQL_CMD

# Connect to the database and execute the command from the temporary file.
mysql --user=${db_user} --password=${db_password} ${db_name} < $TEMP_MYSQL_CMD

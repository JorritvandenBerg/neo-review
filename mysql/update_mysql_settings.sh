#!/bin/bash

cat > /etc/mysql/my.cnf <<EOF
[client]
default-character-set=utf8

[mysqld]
character-set-server=utf8
EOF

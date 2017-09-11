#!/bin/bash

# Check if a config file for ReviewBoard exists, if not; do a new installation
if [[ ! -f /etc/apache2/sites-available/${DOMAIN}.conf ]]; then

  # Check if all the env variables are set and give a warning if not
  if [[ -z $MYSQL_ROOT_PASSWORD ]]; then
    echo "Environment variable MYSQL_ROOT_PASSWORD not set, aborting"
    exit 1
  fi

  if [[ -z $MYSQL_USER ]]; then
    echo "Environment variable MYSQL_USER not set, aborting"
    exit 1
  fi

  if [[ -z $MYSQL_PASSWORD ]]; then
    echo "Environment variable MYSQL_PASSWORD not set, aborting"
    exit 1
  fi

  if [[ -z $REVIEWBOARD_ADMIN_USER ]]; then
    echo "Environment variable REVIEWBOARD_ADMIN_USER not set, aborting"
    exit 1
  fi

  if [[ -z $REVIEWBOARD_ADMIN_PASSWORD ]]; then
    echo "Environment variable REVIEWBOARD_ADMIN_PASSWORD not set, aborting"
    exit 1
  fi

  if [[ -z $DOMAIN ]]; then
    echo "Environment variable DOMAIN not set, aborting"
    exit 1
  fi

  if [[ -z $REVIEWBOARD_EMAIL ]]; then
    echo "Environment variable REVIEWBOARD_EMAIL not set, aborting"
    exit 1
  fi

  # Set utf8 as default character set on mysql
  cat >> /etc/mysql/my.cnf <<EOF
[client]
default-character-set=utf8
EOF

  # Check if mysql container is fired up
  echo -n "Waiting for mysql to start..."
  while ! nc -w 1 mysql 3306 &> /dev/null
  do
    echo -n .
    sleep 1
  done

  # Create database, database user and set the necessary permissions
  mysql -h mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS reviewboard CHARACTER SET utf8;"
  mysql -h mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE USER \"$MYSQL_USER\"@\"%\" IDENTIFIED BY \"$MYSQL_PASSWORD\";"
  mysql -h mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON reviewboard.* to \"$MYSQL_USER\"@\"%\";"
  mysql -h mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

  # Install ReviewBoard
  rb-site install --noinput \
      --domain-name="$DOMAIN" \
      --site-root=/ --static-url=static/ --media-url=media/ \
      --db-type=mysql \
      --db-name=reviewboard \
      --db-host=mysql \
      --db-user="$MYSQL_USER" \
      --db-pass="$MYSQL_PASSWORD" \
      --web-server-type=apache --python-loader=wsgi\
      --cache-type=memcached --cache-info=localhost:11211 \
      --admin-user="$REVIEWBOARD_ADMIN_USER" --admin-password="$REVIEWBOARD_ADMIN_PASSWORD" --admin-email="$REVIEWBOARD_EMAIL" \
      /var/www/reviewboard/

  # Change ownership of web directories
  chown -R www-data /var/www/reviewboard/htdocs/media/uploaded
  chown -R www-data:www-data /var/www/reviewboard/htdocs/media/ext
  chown -R www-data:www-data /var/www/reviewboard/htdocs/static/ext
  chown -R www-data /var/www/reviewboard/data

  # Move all config files in the right directory
  cp /var/www/reviewboard/conf/apache-wsgi.conf /etc/apache2/sites-available/reviewboard.conf
  rm /etc/apache2/sites-enabled/000-default.conf
  sed -i '/ServerName/r conf.txt' /etc/apache2/sites-available/reviewboard.conf
  ln -s /etc/apache2/sites-available/reviewboard.conf /etc/apache2/sites-enabled/

  # Define helper function to join arrays to string
  function join { local IFS="$1"; shift; echo "$*"; }

  # Get array of hashed CSS files (needed to be able to modify them)
  stamped_files=()
  for filepath in /var/www/reviewboard/htdocs/static/rb/css/*; do
    if [[ -f $filepath ]]; then
      filename=$(basename $filepath)
      filename_array=(${filename//./ })
      second_last_element=${filename_array[-2]}
      origin_filename=$(sed "s/$second_last_element.//" <<< $filename)
      origin_filepath=/var/www/reviewboard/htdocs/static/rb/css/${origin_filename}

      if [[ -f $origin_filepath ]]; then
        md5=`md5sum ${origin_filepath} | awk '{ print $1 }'`
        md5=$(echo $md5 | head -c 12)
        if [[ "$second_last_element" == "$md5" ]]; then
          stamped_files+=($filepath)
        fi
      fi
    fi
  done

  # Change UI with custom layout
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i '/navbar a/a    font-weight: 600;'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/blue/#49af43/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#0000CC/#49AF43/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#5A646E/#EEEEEE/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#555/#EEEEEE/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#584b15/#EEEEEE/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#FFE4E1/#D4E691/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#D0E6FF/#D8DDD5/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#DAEBFF/#8FD700/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#EDE1B2/#8FD700/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#CCC/#8FD700/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#2222BB/#000000/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#0700E8/#000000/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i '/title_box_top_bg.e6ef809b528f.png/d'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#A2BEDC/#AFE400/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#E5D7A8/#AFE400/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#44679a/#61a537/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#7E9BC6/#AFE400/g'
  find /var/www/reviewboard/htdocs/static/rb/css/ -type f -print0 | xargs -0 sed -i 's/#5b80b2/#336603/g'

  # Get stamped files and rename them with the new MD5 hash if they differ
  for filepath in "${stamped_files[@]}"; do
    filename=$(basename $filepath)
    origin_filename_array=(${filename//./ })
    second_last_element=${origin_filename_array[-2]}
    origin_filename=$(sed "s/$second_last_element.//" <<< $filename)
    origin_filepath=/var/www/reviewboard/htdocs/static/rb/css/${origin_filename}

    md5=`md5sum ${origin_filepath} | awk '{ print $1 }'`
    md5=$(echo $md5 | head -c 12)

    filename_array=(${filename//./ })
    filename_array[-2]=$md5
    new_filename=$(join . ${filename_array[@]})
    newpath=/var/www/reviewboard/htdocs/static/rb/css/$new_filename

    if [ ! "$filepath" == "$newpath" ]; then
      mv $filepath $newpath
    fi
  done

  # Add GitHub OAuth client id and secret to Django settings
  if [[ ! -z $GITHUB_CLIENT_ID ]]  && [[ ! -z $GITHUB_CLIENT_SECRET ]]; then
    cat >> /var/www/reviewboard/conf/settings_local.py <<EOF

# GitHub OAuth app credentials
GITHUB_CLIENT_ID = '$GITHUB_CLIENT_ID'
GITHUB_CLIENT_SECRET = '$GITHUB_CLIENT_SECRET'
EOF
  fi

  # Get rid of our secrets
  unset MYSQL_ROOT_PASSWORD MYSQL_USER MYSQL_PASSWORD REVIEWBOARD_ADMIN_USER \
    REVIEWBOARD_ADMIN_PASSWORD GITHUB_CLIENT_ID GITHUB_CLIENT_SECRET DOMAIN REVIEWBOARD_EMAIL
fi

# We're all set, fire up Apache!
/usr/sbin/apache2ctl -D FOREGROUND

#!/bin/sh

############################################
 
# ドキュメントルート（カレントディレクトリの場合は「.」）
dir=www
 
# WordPressコアファイルの場所（$dirと同じ場合は「.」）
wpdir=.
 
# WordPressのロケール
locale=ja
 
# ホスト名
hostname=wordpress.local
 
# データベース
dbname=wordpress
dbuser=root
dbpass=root
dbprefix=wp_
 
# サイトタイトル
title="New WordPress Site"
 
# 管理者アカウント
admin_user=admin
admin_password=admin
admin_email=admin@admin.local
 
############################################

set -e


root=$(pwd)
mkdir -p $dir/$wpdir
cd $dir


echo Check wp-cli...
if type wp 2>/dev/null 1>/dev/null 
then
  echo wp-cli exists
else
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  sudo mv wp-cli.phar /usr/local/bin/wp
  mkdir -p ~/.wp-cli/commands
  git clone https://github.com/wp-cli/server-command.git ~/.wp-cli/commands/server
  echo "require:" >> ~/.wp-cli/config.yml
  echo "  - commands/server/command.php" >> ~/.wp-cli/config.yml
fi


echo Download WordPress core...
wp --path=$wpdir core download --locale=$locale


echo Setup SQLite...
curl -o temp.zip https://downloads.wordpress.org/plugin/sqlite-integration.1.8.1.zip
unzip temp.zip && rm temp.zip
mv sqlite-integration $wpdir/wp-content/plugins/
mkdir $wpdir/wp-content/database
mv $wpdir/wp-content/plugins/sqlite-integration/db.php $wpdir/wp-content/


echo Install phpLiteAdmin...
curl -o temp.zip https://phpliteadmin.googlecode.com/files/phpliteAdmin_v1-9-5.zip
unzip temp.zip -d $wpdir/wp-content/database && rm temp.zip


echo Generate wp-config.php...
wp --path=$wpdir core config --skip-check \
    --dbname=$dbname \
    --dbuser=$dbuser \
    --dbpass=$dbpass \
    --dbprefix=$dbprefix \
    --locale=$locale \
    --extra-php <<PHP
define('WP_HOME', 'http://$hostname');
PHP


echo Install dadabase...
wp --path=$wpdir core install \
    --url=http://$hostname \
    --title="$title" \
    --admin_user=$admin_user \
    --admin_password=$admin_password \
    --admin_email=$admin_email


echo Install plugins...
wp --path=$wpdir plugin install sqlite-integration
wp --path=$wpdir plugin install dynamic-hostname --activate
wp --path=$wpdir plugin install wp-multibyte-patch --activate
wp --path=$wpdir plugin install advanced-custom-fields --activate


echo Tweaks...
# TODO: 初期設定をいじる
# TODO: 最初のpostを消したりする
# TODO: 最初のpostを消したりする


echo dynamic-hostname Tweak...
wp --path=$wpdir plugin deactivate dynamic-hostname
curl -O https://raw.githubusercontent.com/mgaoshima/dynamic-hostname/temp-use/dynamic-hostname.php
mv dynamic-hostname.php $wpdir/wp-content/plugins/dynamic-hostname/
wp --path=$wpdir plugin activate dynamic-hostname


if [ "$wpdir" != "." ] ; then
  echo Setting $wpdir as a siteurl...
  wp --path=$wpdir option update siteurl "http://$hostname/$wpdir"
  cat $wpdir/index.php | sed -e "s;/wp-blog-header.php;/$wpdir&;" > index.php
fi


cd $root


startscript="wp server"
if [ "$dir" != "." ] ; then
  startscript="$startscript --path=$dir"
fi

echo done.
echo - - - - - - - - - - - - - - - - - - - - 
echo
echo Start server with:
echo $ $startscript
echo

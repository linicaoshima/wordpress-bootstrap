#!/bin/bash


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

# テーマ名（$theme_nameで http://underscores.me/ から生成してくる）
theme_name=

# 管理者アカウント
admin_user=admin
admin_password=admin
admin_email=admin@admin.local

############################################


set -e


echo Check wp-cli...
if type wp 2>/dev/null 1>/dev/null
then
  echo wp-cli exists
else
  echo Please install wp-cli
  echo run `brew install wp-cli`
fi


echo -n "docroot ($dir): "
read input
dir=${input:-$dir}

echo -n "wpdir ($dir): "
read input
wpdir=${input:-$wpdir}

echo -n "locale ($locale): "
read input
locale=${input:-$locale}

echo -n "dbname ($dbname): "
read input
dbname=${input:-$dbname}

echo -n "title ($title): "
read input
title=${input:-$title}

echo -n "theme ($theme): "
read input
theme=${input:-$theme}


root=$(pwd)
mkdir -p $dir/$wpdir
cd $dir/$wpdir


echo Download WordPress core...
wp core download --locale=$locale


echo Setup SQLite...
curl -o db.php https://raw.githubusercontent.com/aaemnnosttv/wp-sqlite-db/master/src/db.php
mv db.php wp-content/db.php


echo Install phpLiteAdmin...
curl -L -o temp.zip https://bitbucket.org/phpliteadmin/public/downloads/phpLiteAdmin_v1-9-8-2.zip
unzip temp.zip -d temp && rm temp.zip
mkdir wp-content/database
mv temp/phpliteadmin.php wp-content/database
rm -rf temp

echo Generate wp-config.php...
wp core config \
  --skip-check \
  --dbname=$dbname \
  --dbuser=$dbuser \
  --dbpass=$dbpass \
  --dbprefix=$dbprefix \
  --locale=$locale \
  --extra-php <<PHP
if ( isset(\$_SERVER['HTTP_HOST']) ) {
  \$hostname = \$_SERVER['HTTP_HOST'];
  if ( \$hostname == 'localhost:8080' ) {
    define('WP_DEBUG', true);
    define('SAVEQUERIES', true);
  }
}
PHP

echo Install dadabase...
wp core install \
  --url=http://$hostname \
  --title="$title" \
  --admin_user=$admin_user \
  --admin_password=$admin_password \
  --admin_email=$admin_email
wp core verify-checksums


echo Install plugins...
wp plugin install --activate wp-multibyte-patch
wp plugin install --activate debug-bar
wp plugin install --activate wordpress-importer
#wp plugin install advanced-custom-fields
#wp plugin install simple-page-ordering
#wp plugin install taxonomy-terms-order


echo Delete default posts/comments/postmeta...
db="wp-content/database/.ht.sqlite"
sqlite3 $db "DELETE FROM \"wp_comments\""
sqlite3 $db "DELETE FROM \"wp_postmeta\""
sqlite3 $db "DELETE FROM \"wp_posts\""


echo Tweaks...
# キャッチフレーズ（ディスクリプション）
wp option update blogdescription ""

# 日付のフォーマット
wp option update time_format "H:i"

# :-) や :-P のような顔文字を画像に変換して表示する
wp option update use_smilies false

# この投稿に含まれるすべてのリンクへの通知を試みる
wp option update default_pingback_flag false

# 他のブログからの通知 (ピンバック・トラックバック) を受け付ける
wp option update default_ping_status false

# 新しい投稿へのコメントを許可する
wp option update default_comment_status false

# パーマリンク設定
wp option update permalink_structure "/%postname%/"

# _sテーマのダウンロード
if [ "$theme_name" != "" ] ; then
  echo Download _s as "$theme_name"...
  wp scaffold _s $theme_name --activate
fi


wp core update
wp plugin update --all

cat << PHP >> wp-config.php


// Update home/siteurl
if ( function_exists( 'update_option') ) {
  switch ( \$hostname ) {
    case 'localhost:8080':
      update_option('home', 'http://localhost:8080');
      update_option('siteurl', 'http://localhost:8080');
      break;
    default:
      update_option('home', 'http://$hostname');
      update_option('siteurl', 'http://$hostname');
      break;
  }
}
PHP


cd $root


# WordPressをサブディレクトリにインストールする場合
if [ "$wpdir" != "." ] ; then
  echo Setting "$wpdir" as a siteurl...
  wp --path=$dir/$wpdir option update siteurl "http://$hostname/$wpdir"
  cat $dir/$wpdir/index.php | sed -e "s;/wp-blog-header.php;/$wpdir&;" > $dir/index.php
fi


# SQLiteの差分をテキストで表示 - https://goo.gl/LeK6cK
echo '!*.sqlite' >> .gitignore
echo '*.sqlite diff=sqlite3' >> .gitattributes
git config diff.sqlite3.textconv 'echo .dump|sqlite3'


# サーバー起動設定
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

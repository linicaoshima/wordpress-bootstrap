# wordpress-bootstrap

[WP-CLI](http://wp-cli.org/)と[SQLite](http://www.dbonline.jp/sqlite/)を使用したWordPress環境のテンプレートです。  
WordPress環境がディレクトリ内で完結するので、チームで実装する場合に便利です。

## 使い方

### 1. デフォルトのまま使う場合

デフォルトだと`www`ディレクトリ（ドキュメントルート）が作成され、その中にWordPressがインストールされます。

```
$ mkdir yourSiteName
$ cd yourSiteName
$ curl -sL https://raw.githubusercontent.com/linicaoshima/wordpress-bootstrap/master/install.sh | sh
$ wp server --path=www   # http://localhost:8080
```


### 2. 設定を変更して使う場合

```
$ mkdir yourSiteName
$ cd yourSiteName
$ curl -O https://raw.githubusercontent.com/linicaoshima/wordpress-bootstrap/master/install.sh
```

`install.sh` の冒頭に設定があるので、適宜修正して下さい。

```
$ chmod +x install.sh
$ ./install.sh
$ wp server --path=設定したドキュメントルートを指定    # 設定したホスト名で起動
```


## 備考

- デフォルトのWordPressアカウントは`admin`、パスワードも`admin`です。
- `wp-cli`がインストールされていない場合は自動でインストールされるので注意して下さい（suパスワード要求あり）
- SQLite Integrationをベースに開発された[wp-sqlite-db](https://github.com/aaemnnosttv/wp-sqlite-db)でSQLiteを使用しているので、たまに動かないプラグインがあります。
- `www/wp-content/database/.ht.sqlite` がDBファイルです。そのままデプロイできると思いますが、ブラウザから直接アクセスされないようにする必要があります。
- `http://localhost:8080/wp-content/database/phpliteadmin.php` から[phpLiteAdmin](https://code.google.com/p/phpliteadmin/)に入れます。
- PHPのビルトインサーバなので、一部機能が動かない場合があります（画像の編集機能など）
- `.gitignore`と`.gitattributes`が生成されます。すでにある場合は上書きされてしまうので気をつけて下さい。


## License

MIT

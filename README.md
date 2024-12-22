# jtp-webhook

webhookサーバー

## 準備

### passwdファイル作成

```sh
sudo apt-get install apache2-utils
htpasswd -bc ./nginx/.htpasswd admin admin
htpasswd -b ./nginx/.htpasswd user user
```

### hostsファイル(/etc/hosts)編集

以下を追記

`/etc/hosts`

```hosts
127.0.0.1    hoge.com
```

`/etc/wsl.conf` wsl起動時に初期化されるのを回避するため

```conf
[network]
generateHosts = false
```

## 環境起動

```sh
make start
```

## ログ確認

```sh
docker logs --follow webhook
docker logs --follow nginx
```

## テストwebhook発行

```sh
# 認証なし:webhookサーバ直接
curl -v -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"field1":"aaaa","data":{"field2":"bbbb"}}' http://localhost:9000/hooks/test
# 認証あり:nginx経由
curl -v -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"field1":"aaaa","data":{"field2":"bbbb"}}' http://hoge.com/hooks/test -u user:user
# HTTPS認証あり:nginx経由
curl -v -k -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"field1":"aaaa","data":{"field2":"bbbb"}}' https://hoge.com/hooks/test -u user:user
```

## 自己証明書発行

```sh
# 秘密鍵(.key) RSA2048
openssl genrsa -out ./nginx/ssl/hoge.com.key
# 証明書署名要求(.csr) SHA-256
openssl req -new -sha256 -key ./nginx/ssl/hoge.com.key -out ./nginx/ssl/hoge.com.csr
# 自己署名証明書(.crt) X.509
openssl x509 -req -in ./nginx/ssl/hoge.com.csr -signkey ./nginx/ssl/hoge.com.key -out ./nginx/ssl/hoge.com.crt -days 3650
# 個人情報交換ファイル(.pfx) PKCS#12
openssl pkcs12 -export -inkey ./nginx/ssl/hoge.com.key -in ./nginx/ssl/hoge.com.crt -out ./nginx/ssl/hoge.com.pfx
```

## 環境停止

```sh
make stop
```

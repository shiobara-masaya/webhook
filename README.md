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

## プライベートCA局

```sh
# RSA署名鍵作成 パスフレーズ:piyo
openssl genrsa -aes256 -out ./root-ca/pki/private/caprivate.pem 4096
# RSA署名鍵の内容確認 パスフレーズ:piyoを入力する
openssl rsa -text -noout -in ./root-ca/pki/private/caprivate.pem

# 自己署名証明書署名要求(cacert.csr)作成
openssl req -new -key ./root-ca/pki/private/caprivate.pem -out ./root-ca/pki/cert/cacert.csr -config ./root-ca/pki/openssl.conf
# 同、内容確認
openssl req -text -noout -in ./root-ca/pki/cert/cacert.csr

# 自己ルート証明書(cacert.pem)
openssl x509 -req -in ./root-ca/pki/cert/cacert.csr -signkey ./root-ca/pki/private/caprivate.pem -days 5844 -out ./root-ca/pki/cert/cacert.pem
# 同、内容確認
openssl x509 -text -noout -in ./root-ca/pki/cert/cacert.pem


# RSA署名鍵作成 パスフレーズ:piyo
openssl genrsa -aes256 -out ./private/caprivate.pem 4096
# RSA署名鍵の内容確認 パスフレーズ:piyo
openssl rsa -text -noout -in ./private/caprivate.pem

# 自己署名証明書署名要求(cacert.csr)作成
openssl req -new -key ./private/caprivate.pem -config ./openssl.conf -out ./cert/cacert.csr
# 同、内容確認
openssl req -text -noout -in ./cert/cacert.csr

# 自己ルート証明書(cacert.pem)
openssl x509 -req -in ./cert/cacert.csr -signkey ./private/caprivate.pem -days 5844 -out ./cert/cacert.pem
# 同、内容確認
openssl x509 -text -noout -in ./cert/cacert.pem


openssl x509 -req -in ./cert/cacert.csr -signkey ./nginx/ssl/hoge.com.key -out ./nginx/ssl/hoge.com.crt -days 5844
```

## 自己証明書発行

```sh
# 秘密鍵(.key) RSA4096
openssl genrsa -out ./nginx/ssl/hoge.com.key
# 証明書署名要求(.csr) SHA-256
openssl req -new -sha256 -key ./nginx/ssl/hoge.com.key -out ./nginx/ssl/hoge.com.csr
# 自己署名証明書(.crt) X.509
openssl x509 -req -in ./nginx/ssl/hoge.com.csr -signkey ./nginx/ssl/hoge.com.key -out ./nginx/ssl/hoge.com.crt -days 5844
# 個人情報交換ファイル(.pfx) PKCS#12
openssl pkcs12 -export -inkey ./nginx/ssl/hoge.com.key -in ./nginx/ssl/hoge.com.crt -out ./nginx/ssl/hoge.com.pfx

# RSA署名鍵(privkey.pem) パスフレーズ:hoge
openssl genrsa -aes256 -out ./nginx/ssl/privkey.pem 4096
# 証明書署名要求(.csr) SHA-256
openssl req -new -key ./nginx/ssl/privkey.pem -out ./nginx/ssl/servercert.csr -config ./nginx/ssl/openssl.conf
# 認証局の署名鍵を使って署名 →失敗する
openssl x509 -req -in ./nginx/ssl/servercert.csr -CA ./root-ca/pki/cert/cacert.pem -CAkey ./root-ca/pki/private/privkey.pem -CAcreateserial

# RSA署名鍵 パスフレーズ:hoge
openssl genrsa -aes256 -out ./hoge.com/hoge.com.private.pem 4096
# 証明書署名要求(.csr)
openssl req -new -sha256 -key ./hoge.com/hoge.com.private.pem -out ./hoge.com/hoge.com.csr
openssl rsa -in ./hoge.com/hoge.com.private.pem -out ./hoge.com/hoge.com.private.pem


# 認証局の署名
openssl x509 -req -in ./hoge.com/hoge.com.csr -CA ./cert/cacert.pem -CAkey ./private/caprivate.pem -CAcreateserial -extfile ./hoge.com/subjectnames.txt -days 5844 -out ./hoge.com/hoge.com.crt
openssl x509 -in ./hoge.com/hoge.com.crt -text -noout
openssl pkcs12 -export -inkey ./hoge.com/hoge.com.private.pem -in ./hoge.com/hoge.com.crt -out ./hoge.com/hoge.com.pfx

openssl x509 -req -in ./nginx/ssl/servercert.csr -CA ./root-ca/pki/cert/cacert.pem -CAkey ./root-ca/pki/private/caprivate.pem -C


```




## 環境停止

```sh
make stop
```

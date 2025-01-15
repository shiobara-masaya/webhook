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

### 他各種設定

* プロキシ除外設定
  * ターミナル環境変数
  * docker クライアント、サーバ

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
# HTTP、サーバ直接、認証なし
curl -v -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"field1":"HTTP通信","data":{"field2":"サーバ直接", "field3":"認証なし"}}' http://localhost:9000/hooks/test
# HTTP、nginx経由、認証あり
curl -v -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"field1":"HTTP通信","data":{"field2":"NGINX経由", "field3":"BASIC認証あり"}}' http://hoge.com/hooks/test -u user:user
# HTTPS、nginx経由、認証あり
curl -v -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"field1":"HTTPS通信","data":{"field2":"NGINX経由", "field3":"BASIC認証あり"}}' https://hoge.com/hooks/test -u user:user
```

## 自己ルート証明書、自己中間証明書、自己サーバ証明書発行

```sh
# ルート証明書用秘密鍵生成
openssl genrsa -out ./root-ca/pki/private/rootCA.pem 4096
# 同、内容確認
openssl rsa -text -noout -in ./root-ca/pki/private/rootCA.pem
# ルート証明書作成要求 (CSR)
openssl req -new -key ./root-ca/pki/private/rootCA.pem -out ./root-ca/pki/cert/rootCA.csr -subj "/C=JP/ST=Tokyo/L=Shinjyuku/CN=Piyo Root CA"
# 同、内容確認
openssl req -text -noout -in ./root-ca/pki/cert/rootCA.csr
# ルート証明書生成
openssl x509 -req -in ./root-ca/pki/cert/rootCA.csr -signkey ./root-ca/pki/private/rootCA.pem -days 5844 -out ./root-ca/pki/cert/rootCA.crt -extfile <(echo "basicConstraints=CA:TRUE")
# 同、内容確認
openssl x509 -text -noout -in ./root-ca/pki/cert/rootCA.pem

# 中間証明書用秘密鍵生成
openssl genrsa -out ./root-ca/pki/private/intermediateCA.pem 4096
# 中間証明書作成要求 (CSR)
openssl req -new -key ./root-ca/pki/private/intermediateCA.pem -out ./root-ca/pki/cert/intermediateCA.csr -subj "/C=JP/ST=Tokyo/L=Chiyoda/CN=Moge IntermediateCA"
# 中間証明書生成
openssl x509 -req -days 5844 -in ./root-ca/pki/cert/intermediateCA.csr -CA ./root-ca/pki/cert/rootCA.crt -CAkey ./root-ca/pki/private/rootCA.pem -CAcreateserial -out ./root-ca/pki/cert/intermediateCA.crt -extfile <(echo "basicConstraints=CA:TRUE")

# サーバー証明書用秘密鍵生成 →niginxに設定する秘密鍵
openssl genrsa -out ./nginx/ssl/hoge.com.key 4096
# サーバー証明書作成要求 (CSR)
openssl req -new -key ./nginx/ssl/hoge.com.key -out ./nginx/ssl/hoge.com.csr -subj "/C=JP/ST=Tokyo/L=Shinjuku/CN=hoge.com"
# サーバー証明書生成
openssl x509 -req -days 5844 -in ./nginx/ssl/hoge.com.csr -CA ./root-ca/pki/cert/intermediateCA.crt -CAkey ./root-ca/pki/private/intermediateCA.pem -CAcreateserial -extfile ./nginx/ssl/subjectnames.txt -out ./nginx/ssl/hoge.com.crt
# 同、内容確認
openssl x509 -text -noout -in ./nginx/ssl/hoge.com.crt
# 個人情報交換ファイル(.pfx) PKCS#12
openssl pkcs12 -export -inkey ./nginx/ssl/hoge.com.key -in ./nginx/ssl/hoge.com.crt -out ./nginx/ssl/hoge.com.pfx
# 連鎖証明書作成 →niginxに設定する証明書
cat ./nginx/ssl/hoge.com.crt ./root-ca/pki/cert/intermediateCA.crt > ./nginx/ssl/hoge.com.chain.crt

# クライアントにルート証明書登録
sudo cp ./root-ca/pki/cert/rootCA.crt /usr/local/share/ca-certificates/rootCA.crt
sudo update-ca-certificates
```

## 環境停止

```sh
make stop
```

## RocketChatへのAPI発行

```sh
curl --request POST --url https://10.169.38.56:3000/api/v1/login -H 'accept: application/json' -H 'content-type: application/json' -d '{"user": "shiobara.m", "password": "ddg173"}'

# TETRAから
curl -vk -H 'Content-Type: application/json' --data '{"username":"DataDog","icon_emoji":":datadog:","text":"Example message","attachments":[{"title":"Rocket.Chat","title_link":"https://rocket.chat","text":"Rocket.Chat, the best open source chat","color":"#764FA5"}]}' https://tools.tsp-service.jp/chat/hooks/Wjzdq7fLWRJdgzKdy/tZSCTfC9SBx33ztcFAFg9SYQegob22PvjHymPMkFaQvEnKKW | jq
# 運用サーバから
curl -vk -H 'Content-Type: application/json' --data '{"username":"DataDog","icon_emoji":":datadog:","text":"Example message","attachments":[{"title":"Rocket.Chat","title_link":"https://rocket.chat","text":"Rocket.Chat, the best open source chat","color":"#764FA5"}]}' https://10.169.38.55/chat/hooks/Wjzdq7fLWRJdgzKdy/tZSCTfC9SBx33ztcFAFg9SYQegob22PvjHymPMkFaQvEnKKW | jq
```

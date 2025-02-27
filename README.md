# webhookサーバー

webhookサーバーとその前段にnginxを配置し、nginxでBASIC認証、https対応したwebhook処理を行う  
webhookサーバーには<https://github.com/adnanh/webhook>を用いる

## 準備

### 使用ツール

* docker
* docker compose
* make
* openssl

### BASIC認証のためのpasswdファイル作成

本リポジトリには`./nginx/ssl`に以下作成済

```sh
sudo apt-get install apache2-utils
htpasswd -bc ./nginx/.htpasswd admin admin
htpasswd -b ./nginx/.htpasswd user user
```

### webhookのためのホストをhostsファイル(/etc/hosts)に登録

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

* hostsファイルに設定したホストをプロキシ除外する
  * ターミナル環境変数
  * docker クライアント、サーバ

### 自己ルート証明書、自己中間証明書、自己サーバ証明書の発行

自己ルート証明書、自己中間証明書、自己サーバ証明書を発行し、  
クライアントに作成した自己ルート証明書を登録する  
これにより全ての手順が通るHTTPS通信が可能となる  
本リポジトリには`./root-ca`に以下作成済

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

## 稼働

### 環境起動

```sh
make start
```

### ログ確認

```sh
docker logs --follow webhook
docker logs --follow nginx
```

### テストwebhook発行

```sh
# HTTP、webhookサーバ直接、認証なし
curl -v -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"field1":"HTTP通信","data":{"field2":"サーバ直接", "field3":"認証なし"}}' http://localhost:9000/hooks/test
# HTTP、nginx経由、認証あり
curl -v -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"field1":"HTTP通信","data":{"field2":"NGINX経由", "field3":"BASIC認証あり"}}' http://hoge.com/hooks/test -u user:user
# HTTPS、nginx経由、認証あり
curl -v -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"field1":"HTTPS通信","data":{"field2":"NGINX経由", "field3":"BASIC認証あり"}}' https://hoge.com/hooks/test -u user:user
```

### 環境停止

```sh
make stop
```

### その他

[`makefile`](makefile)参照

## 追補 webhookサーバの設定

* [`./webhook/hooks.yaml`](./webhook/hooks.yaml):webhookサーバのコンフィグファイル
  * `id`: 各webhook APIのエンドポイントを識別するID
  * `execute-command`: 実行されるシェルスクリプトのパス
  * `command-working-directory`: 実行ディレクトリ
  * `pass-arguments-to-command`: シェルスクリプトに渡す引数を抽出するためのAPIのJSONペイロード定義  
    詳細は<https://github.com/adnanh/webhook>参照
* `./webhook/scripts/`:実行されるシェルスクリプトを配置するディレクトリ
* エンドポイント:`/hooks/{hooks.yamlで定義したid}`
* 実行するシェルスクリプトはwebhookサーバ上で実行されるため、用いるツール類はコンテナイメージ内にインストールしている([`dockerfile`](dockerfile))  
  volumeマウント等でホストマシン上のツールを呼び出すことも可能かもしれないが試していない(2025/2/27現在)  
  コンテナイメージにインストールするのが確実


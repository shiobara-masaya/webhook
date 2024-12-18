# jtp-webhook

webhookサーバー

```sh
# 準備

# passwdファイル作成
sudo apt-get install apache2-utils
htpasswd -bc ./nginx/.htpasswd admin admin
htpasswd -b ./nginx/.htpasswd user user

# hostsファイル /etc/hosts 追記
127.0.0.1    hoge.com

# 環境起動
make start

# ログ確認
docker logs --follow webhook

# テストwebhook発行(認証なし)
curl -v -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"field1":"aaaa","data":{"field2":"bbbb"}}' http://localhost:9000/hooks/test

# テストwebhook発行(認証あり)


# 環境停止
make stop
```

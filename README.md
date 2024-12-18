# jtp-webhook

webhookサーバー

```sh
# 準備
sudo apt-get install apache2-utils

# passwdファイル作成
htpasswd -bc ./nginx/.htpasswd admin admin
htpasswd -b ./nginx/.htpasswd user user


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

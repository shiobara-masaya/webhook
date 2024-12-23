# UTF-8, LF

.PHONY: menu	# メニュー
menu:
	@grep -E "^(.PHONY)" makefile | grep -v "menu" | awk '{printf"%-20s%s\n",$$2,$$4}' | fzf +m | awk '{print $$1}' | xargs -IXXX make XXX

.PHONY: webhook	# webhookイメージビルド
webhook:
	@docker build -t=webhook:latest ./webhook

.PHONY: root-ca	# rootCAイメージビルド
root-ca:
	@docker build -t=root-ca:latest ./root-ca

.PHONY: start	# サーバー起動
start:
	@docker compose up -d
	@docker compose exec client bash -c "update-ca-certificates </dev/null"

# リアルタイムログ出力
logs:
	@docker compose logs -f

# クライアントログイン
login: start
	@docker compose exec -it client bash

# 証明書チェーン検証
verify: start
	@docker compose exec client bash -c "openssl s_client -showcerts -connect hoge.com:443 </dev/null"

# tlsバージョン・暗号スイート確認
list_ciphers: start
	@docker compose exec client bash -c "nmap --script ssl-enum-ciphers -p 443 hoge.com"

.PHONY: stop	# サーバー停止
stop:
	@docker compose down

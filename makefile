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

.PHONY: stop	# サーバー停止
stop:
	@docker compose down

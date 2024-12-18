# UTF-8, LF

.PHONY: menu	# メニュー
menu:
	@grep -E "^(.PHONY)" makefile | grep -v "menu" | awk '{printf"%-20s%s\n",$$2,$$4}' | fzf +m | awk '{print $$1}' | xargs -IXXX make XXX

.PHONY: build	# イメージビルド
build:
	@docker build -t=webhook:latest .

.PHONY: start	# サーバー起動
start:
	@docker compose up -d

.PHONY: stop	# サーバー停止
stop:
	@docker compose down

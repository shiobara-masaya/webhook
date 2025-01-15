# Dockerfile for https://github.com/adnanh/webhook
FROM golang:alpine AS build
ENV  WEBHOOK_VERSION=2.8.2
RUN go install github.com/adnanh/webhook@${WEBHOOK_VERSION}

FROM debian:stable
RUN apt-get update && apt-get -y upgrade \
	&& apt-get -y install sudo ca-certificates git ssh curl procps gnupg libsecret-1-0 gnome-keyring musl-dev \
	openssl jq fzf software-properties-common nano wget apt-transport-https locales skopeo docker-compose \
	&& apt-get autoremove && apt-get clean && apt-get autoclean

COPY --from=build ./go/bin/. /usr/bin/.
WORKDIR /etc/webhook
VOLUME ["/etc/webhook"]
EXPOSE 9000
ENTRYPOINT ["/usr/bin/webhook"]

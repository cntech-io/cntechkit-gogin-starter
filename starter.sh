#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Provide a folder name!"
    exit 1
fi

folder_name=$1

mkdir "$folder_name"
cd "$folder_name" || exit

mkdir app app/controllers app/handlers app/config app/middlewares app/dtos app/constants app/utils

touch main.go app/server.go app/config/config.go

go mod init "$folder_name"

go get -u github.com/cntech-io/cntechkit-gogin/v2

cat <<EOT >> app/config/config.go
package config

import (
    "github.com/cntech-io/cntechkit-go/v2/env"
)

var ENV = env.NewServerEnv()
EOT

cat <<EOT >> app/controllers/auth.go
package controllers

import (
    "github.com/cntech-io/cntechkit-gogin/v2/controller"
)

func Auth() *controller.Controller {
    return controller.NewController("v1", "auth")
}
EOT

cat <<EOT >> app/server.go
package app

import (
    "github.com/cntech-io/cntechkit-gogin/v2/server"
    "$folder_name/app/controllers"
)

func CreateServer() *server.Server {
	return server.
		NewServer().
		AttachHealth().
        AddController(controllers.Auth())
}
EOT

cat <<EOT >> main.go
package main

import (
    "$folder_name/app"
)

func main() {
    app.CreateServer().Run()
}
EOT

cat <<EOT >> .env
DEBUG_MODE_FLAG=
APP_PORT=
TRUSTED_PROXIES=
EOT

cat <<EOT >> Dockerfile
FROM golang:1.19-buster as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN go build -v -o server


FROM debian:buster-slim
RUN set -x && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/server /app/server
EXPOSE 8080
CMD ["/app/server"]
EOT

go mod tidy


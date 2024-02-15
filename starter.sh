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
    "fmt"
    "$folder_name/app"
)

func main() {
    fmt.Println("Hello, Go Gin!")
    app.CreateServer().Run()
}
EOT





go mod tidy


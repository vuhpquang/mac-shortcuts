#!/bin/bash
PROJECT_NAME=$1
mkdir -p ./projects/$PROJECT_NAME
cd ./projects/$PROJECT_NAME
git init
git checkout -b develop
echo "# $PROJECT_NAME" > README.md
git add . && git commit -m "init: $PROJECT_NAME"
cd ../..
git submodule add ./projects/$PROJECT_NAME ./projects/$PROJECT_NAME
git commit -m "chore: add $PROJECT_NAME as submodule"
echo "Project $PROJECT_NAME ready."

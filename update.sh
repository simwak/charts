#!/bin/bash

if [ -n "$1" ]; then
  echo "Token supplied"
else
  echo "Token not supplied. Exiting!"
  exit 1
fi

rm -rf .cr-index
rm -rf .cr-release-packages

# Checkout to main
git checkout main

for d in charts/* ; do
  version=$(helm show chart $d | grep -o -P '(?<=^version: ).*')
  name=$(helm show chart $d | grep -o -P '(?<=^name: ).*')
  tag=$name-$version

  res=$(curl -s -o /dev/null -w '%{http_code}\n' https://api.github.com/repos/simwak/charts/releases/tags/$tag)
  if ((res == 404)); then
    # Get dependencies and package it into .tgz
    helm package -u -d .cr-release-packages $d
  fi

  # Cleanup
  rm -rf $d/charts/*.tgz
done

mkdir -p .cr-index
cp index.yaml .cr-index/index.yaml

cr upload --owner simwak --git-repo charts --token $1
cr index --owner simwak --git-repo charts --charts-repo https://github.com/simwak/charts --token $1

git checkout chart-repository

cp .cr-index/index.yaml index.yaml
git add index.yaml

read -p "Commit message: " msg

git commit -m "$msg"

read -p "Push? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

git push


# Checkout to main again
git reset --hard
git checkout main
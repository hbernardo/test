#!/usr/bin/env bash

if [[ $CODACY_TOKEN ]]; then

    REPO_PATH=${MBT_REPO_PATH:-"."}

    # Golang

    COVERAGE_FILE="./go_coverage.out"

    go test -race -tags "unit integration" -coverprofile="$COVERAGE_FILE" "$REPO_PATH/go-services/..."

    [ -f $COVERAGE_FILE ] && echo "Go coverage report file generated!" || exit 1

    godacov -t "$CODACY_TOKEN" -r "$COVERAGE_FILE" -c "$(git rev-parse HEAD)"


    # Javascript

    echo "824169247b62d6b7ad05e312a01a4769  codacy-coverage" > codacy-coverage-md5
    curl -Ls https://coverage.codacy.com/get.sh -o codacy-coverage && md5sum --check codacy-coverage-md5
    [ $? -ne 0 ] && exit 1

    for dir in "$REPO_PATH"/js/*; do
        if [ -f "$dir"/package.json ] && grep -q "\"test\"" "$dir"/package.json; then
            yarn --cwd "$dir" && rm -f "$dir"/.npmrc
            yarn --cwd "$dir" test -- --coverage --watchAll=false
            bash codacy-coverage report -t "$CODACY_TOKEN" --commit-uuid "$(git rev-parse HEAD)" -l javascript -r "$dir"/coverage/lcov.info --partial
        fi
    done

    bash codacy-coverage final -t "$CODACY_TOKEN" --commit-uuid "$(git rev-parse HEAD)"

    rm -f codacy-coverage codacy-coverage-md5

fi

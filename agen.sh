#!/bin/bash

if ! command -v agen &> /dev/null
then
    echo "agen not found, active assets_generator..."
    dart pub global activate assets_generator
    if ! command -v agen &> /dev/null
    then
        echo "install assets_generator failed"
        exit 1
    else
        echo "install assets_generator success"
    fi
fi

agen --no-watch -t d -r lcc -o lib/constants -c Resources
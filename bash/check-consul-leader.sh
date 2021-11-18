#!/bin/bash

while true
do
    curl -i http://127.0.0.1:8500/v1/status/leader >> leader_response.log
done

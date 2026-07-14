#!/bin/bash

while getopts "m:uh" arg; do
    case $arg in
        m) 
            machineName="$OPTARG"
            ((parameter_counter++)) 
            ;;
        h) 
            helpPanel
            exit 0
            ;;
        u)
            ((parameter_counter+=2))
            ;;
        *)
            helpPanel
            exit 1
            ;;
    esac
done
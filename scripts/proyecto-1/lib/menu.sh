#!/bin/bash

while getopts "m:uy:i:h" arg; do
    case $arg in
        m) 
            machineName="$OPTARG"
            ((parameter_counter++)) 
            ;;
        u)
            ((parameter_counter+=2))
            ;;
        i) ipAddress="$OPTARG"
           ((parameter_counter += 3)) 
           ;;
        y) 
            machineName="$OPTARG"
           ((parameter_counter += 4))
           ;;
        h) 
            helpPanel
            exit 0
            ;;
        *)
            helpPanel
            exit 1
            ;;
    esac
done
#!/bin/bash

if [ -f /usr/share/arete-lib.sh ]; then
    sudo rm /usr/share/arete-lib.sh 2>/dev/null
fi

if [ -f /usr/share/arete.sh ]; then
    sudo rm /usr/share/arete.sh 2>/dev/null
fi

if [ -f /usr/sbin/arete ]; then
    sudo unlink /usr/sbin/arete 2>/dev/null
fi

#!/bin/bash

echo Starting Sizaha device.

# Check if settings file was generated by bootstrap server.
if [[ -f "/garage_settings/settings.json" ]] then
  echo Launching Runtime service.
  python3 ./garage_daemain.py
else
  AP_NAME = "Sizaha_$RANDOM"
  echo Launching Bootstrap Access Point at $AP_NAME
  echo Launching Bootstrap Server
  python3 bootstrap_server.py
  reboot
fi

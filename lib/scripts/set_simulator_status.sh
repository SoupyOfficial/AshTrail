#!/bin/bash

# Get the list of booted simulators
BOOTED_SIMULATORS=$(xcrun simctl list devices | grep "Booted" | awk -F'[()]' '{print $2}')

echo "Setting status bar appearance for all running simulators..."

for UDID in $BOOTED_SIMULATORS
do
  # Set classic "Apple demo" status bar appearance (9:41 AM, full signal, etc.)
  xcrun simctl status_bar $UDID override \
    --time "9:41" \
    --dataNetwork "wifi" \
    --wifiMode "active" \
    --wifiBars 3 \
    --cellularMode "active" \
    --cellularBars 4 \
    --batteryState "charged" \
    --batteryLevel 100
    
  echo "Status bar configured for simulator: $UDID"
done

echo "Status bar configuration complete!"
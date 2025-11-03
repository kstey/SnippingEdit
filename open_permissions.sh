#!/bin/bash

echo "Opening System Settings > Privacy & Security > Screen Recording..."
echo ""
echo "Steps to grant permission:"
echo "Opening Screen Recording preferences..."
echo ""
echo "Instructions:"
echo "1. Look for 'SnippingEdit' in the list"
echo "2. Enable the checkbox next to it"
echo "3. You may need to quit and restart SnippingEdit"
echo ""

# Open System Settings to Screen Recording permissions
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"


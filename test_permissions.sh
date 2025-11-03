#!/bin/bash

echo "🧪 Testing SnippingEdit Permissions..."
echo ""
echo "1. Starting the app..."
./.build/debug/SnippingEdit &
APP_PID=$!

echo "2. App started with PID: $APP_PID"
echo ""
echo "📋 What to test:"
echo "   ✅ Look for permission dialog popup"
echo "   ✅ Click the 📷 camera icon in menu bar"
echo "   ✅ Try taking a screenshot"
echo ""
echo "Press Ctrl+C to stop the app when done testing"
echo ""

# Wait for user to test
wait $APP_PID

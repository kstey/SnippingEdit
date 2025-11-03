#!/bin/bash

echo "🔨 Building SnippingEdit..."
./build_app.sh

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "🚀 Launching SnippingEdit..."
open build/SnippingEdit.app

echo ""
echo "⏳ Waiting 2 seconds for app to start..."
sleep 2

echo ""
echo "📋 Opening System Settings for Screen Recording permissions..."
./open_permissions.sh

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. The app should now be running (check menu bar for 📷 icon)"
echo "2. System Settings should be open to Screen Recording permissions"
echo "3. If SnippingEdit is not in the list yet, try taking a screenshot first"
echo "4. Enable SnippingEdit in the Screen Recording permissions list"
echo "5. Restart the app if needed"
echo ""


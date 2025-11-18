# Auto-Clipboard Feature Guide

## Overview
The SnippingEdit app now automatically copies your edited image to the clipboard after 2 seconds of inactivity. This makes it faster to use your edited screenshots without manually clicking the Copy button.

## How It Works

### Automatic Clipboard Copy
After you finish editing, the app will automatically copy the image to your clipboard after **2 seconds** of no activity.

### When the Timer Starts
The 2-second countdown begins after:
- ✏️ **Drawing an annotation** (when you release the mouse)
- ↩️ **Undo operation** (Cmd+Z or Undo button)
- ↪️ **Redo operation** (Cmd+Shift+Z or Redo button)

### Timer Reset Behavior
If you make another edit before the 2 seconds are up:
- The timer **cancels** and **restarts** from 2 seconds
- This ensures you don't get multiple clipboard copies while actively editing

### When the Timer is Cancelled
The timer stops without copying when you:
- 🗑️ **Click "Clear"** button
- [object Object] new image** into the editor

### Visual Feedback
When the auto-copy happens, you'll see:
- The Copy button briefly changes to **"✅ Copied!"**
- This confirms the image is now in your clipboard
- The button then becomes disabled (since it's already copied)

## Usage Examples

### Example 1: Quick Edit
1. Draw a red circle on your screenshot
2. Wait 2 seconds
3. ✅ Image automatically copied to clipboard
4. Switch to another app and paste (Cmd+V)

### Example 2: Multiple Edits
1. Draw a red arrow
2. Draw a blue box (within 2 seconds)
3. Draw yellow highlight (within 2 seconds)
4. Stop editing
5. Wait 2 seconds
6. ✅ Image automatically copied with all 3 annotations

### Example 3: Using Undo/Redo
1. Draw an annotation
2. Press Undo (Cmd+Z)
3. Wait 2 seconds
4. ✅ Image automatically copied (without the annotation)

### Example 4: Continuous Editing
1. Draw annotation #1
2. Within 2 seconds, draw annotation #2
3. Within 2 seconds, draw annotation #3
4. Stop editing
5. Wait 2 seconds
6. ✅ Image automatically copied (timer only triggered once)

## Manual Copy Still Available
You can still manually click the **"Copy"** button at any time if you don't want to wait for the auto-copy.

## Benefits
- ⚡ **Faster workflow** - No need to click Copy button
- 🎯 **Smart timing** - Only copies when you're done editing
- [object Object]th undo/redo** - Updates clipboard after changes
- 💡 **Intuitive** - Just edit and wait, then paste anywhere

## Technical Details
- Timer duration: **2.0 seconds**
- Timer is implemented using Swift's `Timer.scheduledTimer`
- Each new edit cancels the previous timer and starts a new one
- The same clipboard code is used for both auto and manual copy


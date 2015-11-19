# MusicMotion: Adding Motion Awareness to a Music App

## Version
1.0

## About MusicMotion

CoreMotion provides great contextual awareness that can be used to make apps even smarter. This sample demonstrates best practices for CoreMotion API usage and provides an example of how to fuse different types of motion and fitness data to enable context aware application behavior.

## Structure

The project consists of 2 view controllers and 4 model classes.

### View Controllers

1) SongViewController
    - A music player's song queue.

2) HistoryViewController
    - A user's history view controller.

### Models

There are a few model classes that are used throughout the app:

1) Song
2) SongManager
3) Activity
4) MotionManager

## What's Important

This sample code is a mock music application that combines motion and fitness data to update a queued playlist. The application also allows you to review historical activity and pedometer data. The MotionManager class performs the following:

1. Checks for API availability.
2. Checks for Motion Activity authorization.
3. Requests live updates of activity, pedometer data, and altitude data (while running or walking).
3. Queries for historical motion activity and correlates with historical pedometer data.

The MotionManager also contains several application specific constants that should be tuned to your specific needs.

## Requirements

### Build
Xcode 7.0, iOS 9.0 SDK

### Runtime
iOS 9.0

Copyright (C) 2015 Apple Inc. All rights reserved.
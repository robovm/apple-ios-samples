Read Me About GKLeaderboard
===========================================================================
GKLeaderboard is a sample application that shows how to correctly 
submit a score and view them using GKLeaderboardViewController. 
This code is completely copy and paste-able.


IMPORTANT: When adding support for Game Center to an application, it is not
enough to simply add the necessary code to your application.  You also
need to configure your app in iTunes Connect to match your desired
configuration.  

===========================================================================
BUILD REQUIREMENTS:

This project was built with Xcode 3.2.4 and iOS SDK 4.2

===========================================================================
RUNTIME REQUIREMENTS:

The project requires iOS 4.2 and a GameCenter account to run.

===========================================================================
PACKAGING LIST:
- ReadMe.txt -- This file.
- GKLeaderboards.xcodeproj --  Xcode project for this sample
- Resources -- The project nib, images, and so on
- Classes/GKLeaderboardsAppDelegate.h -- Declaration of the best 
    practices
- Classes/GKLeaderboardsAppDelegate.m -- Contains the app delegate including 
    best practices of authentication
- Classes/PlayerModel -- Declaration of everything you need to 
    include store scores, and resubmit them at a further point
- Classes/PlayerModel.m -- Contains methods to submit, store and load 
    scores
- Classes/SampleViewController.h -- Declaration of viewController around a 
    single button
-- Classes/SampleViewController.m -- Contains methods to display 
    AchievementsViewController and submit a percentage of an achievement
- main.m -- The main function of this sample.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.0: (Mar 2011) First shipping version.

===========================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.


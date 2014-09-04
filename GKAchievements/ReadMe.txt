Read Me About GKAuthentication
===========================================================================
GKAuthentication is a sample application that shows how to correctly 
submit an Achievement and view the GKAchievementViewController. 
This code is completely copy and paste-able.

It is important to note that there is no code for locally saving the state 
of the achievements submitted. GKAchievementViewController will present the
highest completion that has been submitted.

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
- GKAchievements.xcodeproj --  Xcode project for this sample. 
- Resources -- The project nib, images, and so on.
- Classes/GKAchievementsAppDelegate.h -- Declaration of the best 
    practices
- Classes/GKAchievementsAppDelegate.m -- Contains the app delegate including 
    best practices of authentication
- Classes/PlayerModel.h -- Declaration of everything you need to 
    include achievements
- Classes/PlayerModel.m -- Contains methods to submit, store and load 
    achievements
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


### SimpleUndo ###

===========================================================================
DESCRIPTION:

Illustrates how to use undo on iPhone.
The root view controller displays information (title, author, and copyright date) about a book. The user can edit this information by tapping Edit in the navigation bar. When editing starts, the root view controller creates an undo manager to record changes. The undo manager supports up to three levels of undo and redo.  When the user taps Done, changes are considered to be committed and the undo manager is disposed of.

===========================================================================
BUILD REQUIREMENTS:

iOS 6.0 SDK or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS 5.0 or later

===========================================================================
PACKAGING LIST:

SimpleUndoAppDelegate.{h,m}
    Configures the book and the first view controllers.

RootViewController.{h,m}
    Manages a table view that displays information about a book.

EditingViewController.{h,m}
    View controller for editing a field of data, text or date.

Book.{h,m}
    A simple managed object class to represent a book.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
- Adopted storyboards and ARC.

Version 1.1
- Upgraded project to build with the iOS 4.0 SDK.

Version 1.0
- First version.

===========================================================================
Copyright (C) 2009-2013 Apple Inc. All rights reserved.

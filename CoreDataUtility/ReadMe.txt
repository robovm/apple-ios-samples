### Core Data Utility ###

===========================================================================
DESCRIPTION:

This sample contains the complete source code to the Core Data Utility Tutorial.

The sample illustrates how you can create a command-line utility that uses Core Data. It shows how to performs basic tasks required in a Core Data application:
* Creation of a Core Data stack -- a persistent store, a persistent store coordinator (including the managed object model), and a managed object context.
* Creation and initialization of a managed object.
* Committing changes to the store by saving a context.
* Creating a fetch request and retrieving managed objects.

===========================================================================
PACKAGING LIST:

Run.{h,m}
Run is a simple managed object class to record the date and process ID of a process. It also implements:
* awakeFromInsert: to set the date of a Run instance to the date at which it is first inserted into a managed object context.
* setNilValueForKey: to trap an attempt to set a nil value for the process ID (which is a scalar value).


main.m
Contains the main() function to run the utility, and additional supporting functions.
There are supporting functions to:
* Create the managed object model.
* Create the managed object context and the rest of the Core Data stack.
* Create a URL to the application's log directory.

Using the supporting functions, the main function creates a new instance of the Run entity to represent the current run of the utility, adds the run to the persistent store, and lists previous runs.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2012 Apple Inc. All rights reserved.

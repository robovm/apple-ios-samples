### PackagedDocument_iOS ###

===========================================================================
DESCRIPTION:

"PackagedDocument_iOS" is a sample application for opening, editing and saving packaged documents using UIDocument and NSFileWrapper.
This sample is ARC-enabled (Automatic Reference Counting).

File Format and NSFileWrapper:
It is important to consider NSFileWrapper when designing your document format.  Choices you make in designing your document format can impact issues like network transfer performance to and from iCloud for your app’s documents, should you choose to suppose iCloud someday. The most important choice is to be sure to use a file package for your document format.  If your document data format consists of multiple distinct pieces, use a file package for your document file format. A file package, which you access by way of an NSFileWrapper object, lets you store the elements of a document as individual files and folders that can be read and written separately—while still appearing to the user as a single file. For example the iCloud upload and download machinery makes use of this factoring of content within a file package; only changed elements are uploaded or downloaded.

Two distinctive components of this document format:
This sample demonstrates the use of NSFileWrapper by writing two distinctive files: text, image.


===========================================================================
BUILD REQUIREMENTS:

Xcode 5.0 or later, iOS 7.0 SDK or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.0 - First version.

===========================================================================
Copyright (C) 2014 Apple Inc. All rights reserved.

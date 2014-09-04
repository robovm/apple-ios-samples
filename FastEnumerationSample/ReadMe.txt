### EnumerationSample ###

===========================================================================
DESCRIPTION:

EnumerationSample is a command line project that demonstrates how to implement a class that supports block-based enumeration, fast enumeration, enumeration using NSEnumerator, and subscripting.  While provided as a OS X application, the techniques demonstrated by this sample are fully applicable to iOS development.

Keep in mind that most developers will be better served by using one of the built in Foundation container classes, such as NSArray or NSDictionary, rather than implementing their own custom container class.

For more information on enumeration in Objective-C, see the relevant chapter in the Collections Programming Topics
    <https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/Collections/Articles/Enumerators.html>
For more information on NSEnumerator, see the NSEnumerator class reference
    <https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSEnumerator_Class/Reference/Reference.html>
For more information on the NSFastEnumeration protocol, see the Fast Enumeration protocol reference 
    <https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/NSFastEnumeration_protocol/Reference/NSFastEnumeration.html>
    
For more information on Object Subscripting in Objective-C, see the relevant Clang documentation
    <http://clang.llvm.org/docs/ObjectiveCLiterals.html#subscripting-methods>


===========================================================================
USING THE SAMPLE:

To view the sample's output in Xcode, open the Console by choosing "Product" > "Run" (or entering Command-R).  The sample will log four identical sets of 50 randomly generated numbers.  Each logged set if produced by a single enumeration technique.  See the comments in EnumerationSample.m.


===========================================================================
BUILD REQUIREMENTS:

OS X 10.9 SDK or later


===========================================================================
RUNTIME REQUIREMENTS:

OS X 10.7 or later


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
- Expanded the sample to cover various methods of enumeration.
- Named changed from 'FastEnumerationSample' to 'EnumerationSample'.

Version 1.0
- Initial Version


===========================================================================
BUG REPORTS:

Please submit any bug reports about this sample to the Bug Reporting page.


===========================================================================
Copyright (C) 2009-2014, Apple Inc. All rights reserved.
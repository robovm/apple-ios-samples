### UnwindSegue ###

================================================================================
DESCRIPTION:

This sample demonstrates using segues and unwind segues to drive navigation between the various screens of content in an app.  The project contains two build targets: UnwindSegue and CustomUnwindSegue.  UnwindSegue demonstrates using unwind segues with modally presented view controllers as well as view controllers in a UINavigationController.  CustomUnwindSegue demonstrates implementing a custom container view controller that can be used with unwind segues.

Both targets implement a simple quiz using the code under the 'Shared' group.  You can customize the questions presented in the quiz by editing the Questions.plist file.  MainMenuViewController displays the initial menu with some instructions and a button to begin the quiz.  After the user has completed the quiz at least once, the MainMenuViewController will also display their highest percentage score.  Tapping the 'Begin' button presents the first QuestionViewController (modally).  As the user answers each question, more instances of QuestionViewController are pushed onto the navigation stack until their are no more questions at which point ResultsViewController will be pushed onto the navigation stack.  ResultsViewController displays the user's quiz score and gives them the option to 'Start Over' or 'Return to the Main Menu'.  Tapping 'Start Over' returns to the first QuestionViewController using an unwind segue.  Tapping 'Return to the Main Menu' returns to MainMenuViewController using an unwind segue.

Notes about the storyboard configuration.
* Both samples contain a nearly identical storyboard.  In place of a UINavigationController, CustomUnwindSegue substitutes QuizContainerViewController which is functionally equivalent to a UINavigationController.
* The 'Question View Controller' scene contains two segues.  The first loops back to itself and is used to display the next question.  QuestionViewController overrides -shouldPerformSegueWithIdentifier: to block the execution of this segue when there are no more questions to display, at which point it manually triggers its second segue that displays the results screen.  This can be an efficient way to define conditional navigation with segues instead of falling back to IBActions/code.

For more information, including an overview of unwind segues, see
TN2298: Using Unwind Segues <https://developer.apple.com/library/ios/technotes/tn2298/_index.html>

================================================================================
BUILD REQUIREMENTS:

iOS 7.0 SDK or later
 
================================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later

================================================================================
PACKAGING LIST:

Shared
    Question.{h/m} 
        - Model class for a single question.
    
    Quiz.{h/m}
        - Model class for a Quiz.
    
    MainMenuViewController.{h/m} 
        - View controller for the initial screen.
    
    QuestionViewController.{h/m} 
        - View controller for displaying a Question.
    
    ResultsViewController.{h/m}
        - View controller for the results screen.
        
UnwindSegue
    AppDelegate.{h/m} 
        - The application's delegate for the UnwindSegue target.
        
CustomUnwindSegue:
    AppDelegate.{h/m} 
        - The application's delegate for the CustomUnwindSegue target.
        
    QuizContainerViewController.{h/m} 
        - A custom container view controller that is functionally similar to a UINavigationController.
        
    QuizContainerRootViewControllerSegue.{h/m} 
        - Custom segue for setting the root view controller of a QuizContainerViewController.
        
    QuizContainerFadeViewControllerSegue.{h/m} 
        - Custom segue for pushing new view controllers onto the navigation stack of a QuizContainerViewController.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0 
- First release.

================================================================================
Copyright (C) 2013 Apple Inc. All rights reserved.
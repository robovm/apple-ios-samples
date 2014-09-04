UnitTests illustrates the use of unit tests to ensure that an appÕs
functionality does not degrade as its source code undergoes changes to improve
the app or to fix bugs. The projects in the UnitTests workspace showcase two 
types of unit tests: logic and application. Logic unit tests allow for
stress-testing source code. Application unit tests help ensure the correct
linkage between user interface controls, controller objects, and model objects.

This example is a workspace that contains two projects that build an iOS app 
and a Mac app. Both apps use a static library that implements a calculator
engine.

Each project in the workspace builds four products:
- The app
- The application unit-tests for the app
- The Calculator library
- The logic unit-tests for the Calculator library

Each project contains two schemes:
- The app scheme:     builds and runs the app and the application unit tests
- The library scheme: builds the static library and runs the logic unit tests

Both projects use the source code for the Calculator class to build a static 
library that they use to process keystrokes and obtain calculation results.

The Calculator class implements a calculating engine that has two main methods:
input: and displayValue.
- The input: method accepts a one-character string as input, which represents
  a key press.
- The displayValue method provides the value representing the calculatorÕs 
  output.

========== The iOS_Calc Project ===============================================

The iOS_Calc project defines two schemes:
- iOS_Calc
  Runs the Calc app, and performs application unit tests on it.

- Calculator-iOS
  Performs logic unit tests on the Calculator class.

The project contains four targets:
- iOS_Calc                  
  Builds the Calc app.

- iOS_Calc_ApplicationTests
  Implements the application unit-test suite for the Calc app. 

- Calculator-iOS
  Builds the Calculator-iOS static library.

- Calculator-iOS_LogicTests
  Implements the iOS logic unit-test suite for the Calculator class.

--------------------------------------------------------------------------------------
Testing the Calculator-iOS static library using logic unit tests
- To run the logic tests:
  1. From the scheme toolbar menu, choose Calculator-iOS > <device_simulator>.
  2. Choose Product > Test. Xcode runs the test cases implemented in the
     CalculatorLogicTests.m file.
  3. Choose View > Navigators > Show Log Navigator to open the log navigator.
  4. In the list on the left, select the Test Calculator-iOS_LogicTests task
     to view the test log. 

-------------------------------------------------------------------------------
Testing the Calc app using application tests
- To run the application tests:
  1. From the scheme toolbar menu, choose iOS_Calc > <device>.
  2. Choose Product > Test. Xcode runs the test cases implemented in the 
     CalcTests.m file.
  3. Choose View > Navigators > Show Log Navigator to open the log navigator.
  4. In the list on the left, select the Test iOS_Calc_ApplicationTests task
     to view the test log.


========== The Mac_Calc Project ===============================================

The Mac_Calc project defines two schemes:
- Mac_Calc
  Runs the Calc app, and performs application unit tests on it.

- Calculator-Mac 
  Performs logic unit tests on the Calculator class.

The project contains four targets:
- Mac_Calc                  
  Builds the Calc app.

- Mac_Calc_ApplicationTests
  Implements the application unit-test suite for the Calc app. 

- Calculator-Mac  
  Builds the Calculator-Mac static library.

- Calculator-Mac_LogicTests
  Implements the Mac logic unit-test suite for the Calculator class.

-------------------------------------------------------------------------------
Testing the Calculator-Mac static library using logic unit tests
- To run the logic tests:
  1. From the scheme toolbar menu, choose Calculator-Mac > <Mac_architecture>.
  2. Choose Product > Test. Xcode runs the test cases implemented in the
     CalculatorLogicTests.m file.
  3. Choose View > Navigators > Show Log Navigator to open the log navigator.
  4. In the list on the left, select the Test Calculator-Mac_LogicTests task
     to view the test log. 

-------------------------------------------------------------------------------
Testing the Calc app using application unit tests
- To run the application tests:
  1. From the scheme toolbar menu, choose Mac_Calc > <Mac_architecture>.
  2. Choose Product > Test. Xcode runs the test cases implemented in the 
     CalcTests.m file.
  3. Choose View > Navigators > Show Log Navigator to open the log navigator.
  4. In the list on the left, select the Test Mac_Calc_ApplicationTests task
     to view the test log.


===============================================================================
Related Information
- For more information, see the Xcode Unit Testing Guide document.


Copyright © 2012 Apple Inc. All rights reserved.

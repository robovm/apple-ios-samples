/*
     File: CalcTests.m
 Abstract: This file implements the application unit tests for the Calc iOS app.
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
*/

#import "CalcTests.h"

@implementation CalcTests

/* The setUp method is called automatically for each test-case method (methods whose name starts with 'test').
 */
- (void) setUp {
   app                  = [NSApplication sharedApplication];
   calc_view_controller = (CalcViewController*)[[NSApplication sharedApplication] delegate];
   calc_view            = calc_view_controller.view;
}

- (void) testApp {
   XCTAssertNotNil(app, @"Cannot find NSApplication instance");
}

- (void) testCalcViewContoller {
   XCTAssertNotNil(calc_view_controller, @"Cannot find CalcViewController instance");
}

- (void) testCalcView {
   XCTAssertNotNil(calc_view, @"Cannot find CalcView instance");
}

/* testAddition performs a chained addition test.
 * The test has two parts:
 * 1. Check: 6 + 2 = 8.
 * 2. Check: display + 2 = 10.
 */
- (void) testAddition {
   [calc_view_controller press:[calc_view viewWithTag: 6]];  // 6
   [calc_view_controller press:[calc_view viewWithTag:13]];  // +
   [calc_view_controller press:[calc_view viewWithTag: 2]];  // 2
   [calc_view_controller press:[calc_view viewWithTag:12]];  // =   
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"8"], @"Part 1 failed.");
   
   [calc_view_controller press:[calc_view viewWithTag:13]];  // +
   [calc_view_controller press:[calc_view viewWithTag: 2]];  // 2
   [calc_view_controller press:[calc_view viewWithTag:12]];  // =      
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"10"], @"Part 2 failed.");
}

/* testSubtraction performs a simple subtraction test.
 * Check: 6 - 2 = 4.
 */
- (void) testSubtraction {
   [calc_view_controller press:[calc_view viewWithTag: 6]];  // 6
   [calc_view_controller press:[calc_view viewWithTag:14]];  // -
   [calc_view_controller press:[calc_view viewWithTag: 2]];  // 2
   [calc_view_controller press:[calc_view viewWithTag:12]];  // =   
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"4"], @"");
}

/* testDivision performs a simple division test.
 * Check: 25 / 4 = 6.25.
 */
- (void) testDivision {
   [calc_view_controller press:[calc_view viewWithTag: 2]];  // 2
   [calc_view_controller press:[calc_view viewWithTag: 5]];  // 5
   [calc_view_controller press:[calc_view viewWithTag:16]];  // /
   [calc_view_controller press:[calc_view viewWithTag: 4]];  // 4
   [calc_view_controller press:[calc_view viewWithTag:12]];  // =   
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"6.25"], @"");
}

/* testMultiplication performs a simple multiplication test.
 * Check: 19 x 8 = 152.
 */
- (void) testMultiplication {
   [calc_view_controller press:[calc_view viewWithTag: 1]];  // 1
   [calc_view_controller press:[calc_view viewWithTag: 9]];  // 9
   [calc_view_controller press:[calc_view viewWithTag:15]];  // x
   [calc_view_controller press:[calc_view viewWithTag: 8]];  // 8
   [calc_view_controller press:[calc_view viewWithTag:12]];  // =
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"152"], @"");
}

/* testDelete tests the functionality of the D (Delete) key.
 * 1. Enter the number 1987 into the calculator.
 * 2. Delete each digit, and test the display to ensure
 *    the correct display contains the expected value after each D press.
 */
- (void) testDelete {
   [calc_view_controller press:[calc_view viewWithTag: 1]];  // 1
   [calc_view_controller press:[calc_view viewWithTag: 9]];  // 9
   [calc_view_controller press:[calc_view viewWithTag: 8]];  // 8
   [calc_view_controller press:[calc_view viewWithTag: 7]];  // 7
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"1987"], @"Part 1 failed.");
   
   [calc_view_controller press:[calc_view viewWithTag:19]];  // D (delete)
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"198"],  @"Part 2 failed.");      
   
   [calc_view_controller press:[calc_view viewWithTag:19]];  // D (delete)
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"19"],   @"Part 3 failed.");      
   
   [calc_view_controller press:[calc_view viewWithTag:19]];  // D (delete)
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"1"],    @"Part 4 failed.");      
   
   [calc_view_controller press:[calc_view viewWithTag:19]];  // D (delete)
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"0"],    @"Part 5 failed.");
}

/* testClear tests the functionality of the C (Clear).
 * 1. Clear the display.
 *  - Enter the calculation 25 / 4.
 *  - Press C.
 *  - Ensure the display contains the value 0.
 * 2. Perform corrected computation.
 *  - Press 5, =.
 *  - Ensure the display contains the value 5.
 * 3. Ensure pressign C twice clears all.
 *  - Enter the calculation 19 x 8.
 *  - Press C (clears the display).
 *  - Press C (clears the operand).
 *  - Press +, 2, =.
 *  - Ensure the display contains the value 2.
 */
- (void) testClear {
   [calc_view_controller press:[calc_view viewWithTag: 2]];  // 2
   [calc_view_controller press:[calc_view viewWithTag: 5]];  // 5
   [calc_view_controller press:[calc_view viewWithTag:16]];  // /
   [calc_view_controller press:[calc_view viewWithTag: 4]];  // 4
   [calc_view_controller press:[calc_view viewWithTag:11]];  // C (clear)
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"0"], @"Part 1 failed.");
   
   [calc_view_controller press:[calc_view viewWithTag: 5]];  // 5
   [calc_view_controller press:[calc_view viewWithTag:12]];  // =
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"5"], @"Part 2 failed.");
   
   [calc_view_controller press:[calc_view viewWithTag: 1]];  // 1
   [calc_view_controller press:[calc_view viewWithTag: 9]];  // 9
   [calc_view_controller press:[calc_view viewWithTag:15]];  // x
   [calc_view_controller press:[calc_view viewWithTag: 8]];  // 8
   [calc_view_controller press:[calc_view viewWithTag:11]];  // C (clear)
   [calc_view_controller press:[calc_view viewWithTag:11]];  // C (all clear)
   [calc_view_controller press:[calc_view viewWithTag:13]];  // +
   [calc_view_controller press:[calc_view viewWithTag: 2]];  // 2
   [calc_view_controller press:[calc_view viewWithTag:12]];  // =   
   XCTAssertTrue([[calc_view_controller.displayField stringValue] isEqualToString:@"2"], @"Part 3 failed.");
}

@end

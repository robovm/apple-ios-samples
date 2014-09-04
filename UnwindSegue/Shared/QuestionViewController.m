/*
     File: QuestionViewController.m
 Abstract: View controller for displaying a Question.
 
  Version: 1.0
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "QuestionViewController.h"
#import "Quiz.h"
#import "ResultsViewController.h"

@interface QuestionViewController ()
@property (readwrite, getter = isLastQuestion) BOOL lastQuestion;
@end


@implementation QuestionViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Prevent the user from returning to the previous question.
    self.navigationItem.hidesBackButton = YES;
}


//| ----------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = [NSString stringWithFormat:@"Question %i", self.questionIndex+1];
    self.lastQuestion = (self.questionIndex == self.currentQuiz.totalQuestions - 1);
}


//| ----------------------------------------------------------------------------
//! Unwinds from the ResultsViewController back to the first
//! QuestionViewController when the user taps the 'Start Over' button.
//
//  This is an unwind action.  Note that the sender parameter is a
//  'UIStoryboardSegue*' instead of the usual 'id'.  Like all unwind actions,
//  this method is invoked early in the unwind process, before the visual
//  transition.  Note that the receiver of this method is the
//  destinationViewController of the segue.  Your view controller should use
//  this callback to update its UI before it is redisplayed.
//
- (IBAction)exitToQuizStart:(UIStoryboardSegue *)sender
{
    // The user has restarted the quiz.
    [self.currentQuiz resetQuiz];
}


//| ----------------------------------------------------------------------------
//  We must disambiguate which QuestionViewController should handle the
//  exitToQuizStart: action as there will be several QuestionViewController
//  instances on the navigation stack when the unwind segue is triggered.  By
//  default, a UINavigationController (or QuizContainerViewController) searches 
//  its viewControllers array in reverse.  Without overriding this method, 
//  the QuestionViewController directly preceding the results screen would be
//  selected as the destination of the unwind segue.
//
- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender
{
    // Always check if the view controller implements the unwind action by
    // calling the super's implementation.
    if ([super canPerformUnwindSegueAction:action fromViewController:fromViewController withSender:sender])
        // The first QuestionViewController in the navigation stack should 
        // handle the unwind action.
        return self == [[(UINavigationController*)self.parentViewController viewControllers] objectAtIndex:0];
    
    return NO;
}


//| ----------------------------------------------------------------------------
//  Overriding this method allows a view controller to block the execution of a 
//  triggered segue.
//
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // Only advance to the next question if there is a next question.
    if ([identifier isEqualToString:@"NextQuestion"])
        return !self.lastQuestion;
    
    return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
}


//| ----------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"NextQuestion"])
    {
        self.currentQuiz[self.questionIndex].selectedResponse = [self.tableView indexPathForSelectedRow].row;
        QuestionViewController *nextQuestionVC = (QuestionViewController*)segue.destinationViewController;
        nextQuestionVC.currentQuiz = self.currentQuiz;
        nextQuestionVC.questionIndex = self.questionIndex+1;
    }
    else if ([segue.identifier isEqualToString:@"ResultScreen"])
    {
        ResultsViewController *resultVC = (ResultsViewController*)segue.destinationViewController;
        resultVC.currentQuiz = self.currentQuiz;
    }
}

#pragma mark - Table view data source

//| ----------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}


//| ----------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 1;
    else
        return self.currentQuiz[self.questionIndex].responses.count;
}


//| ----------------------------------------------------------------------------
//  This delegate method is implemented because the height of the
//  cell displaying the question will need to change depending on the height 
//  required to display the question text.  As the device rotates this will
//  change.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        UITableViewCell *questionCell = [tableView dequeueReusableCellWithIdentifier:@"QuestionCell"];
        UILabel *questionLabel = questionCell.textLabel;
        
        // Use the -sizeWithFont:constrainedToSize: method of NSString to
        // determine the required height of the question cell in order
        // to display the question without cutting off any of the text.
        
        // The width must be constrained to the width of the table view minus the
        // left and right margin of a grouped style cell.
        // Unfortunately, there is no way to lookup exactly what that margin is, so
        // it must be hardcoded.
        // The height is left unconstrained.
        CGSize constrainingSize = CGSizeMake(tableView.bounds.size.width - 40*2, MAXFLOAT);
        
        return [questionLabel.text sizeWithFont:questionLabel.font constrainedToSize:constrainingSize].height + 22;
    }
    return tableView.rowHeight;
}


//| ----------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"QuestionCell"];
        cell.textLabel.text = self.currentQuiz[self.questionIndex].text;
        return cell;
    }
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AnswerCell"];
        cell.textLabel.text = self.currentQuiz[self.questionIndex].responses[indexPath.row];
        return cell;
    }
}


//| ----------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    // This method is called regardless of the value returned by 
    // -shouldPerformSegueWithIdentifier:.  Therefore, check if this view
    // controller is displaying the final question and advance to the results
    // screen only if it is.
    if (indexPath.section == 1 && self.lastQuestion)
    {
        self.currentQuiz[self.questionIndex].selectedResponse = indexPath.row;
        
        // Trigger the segue leading to the results screen.
        [self performSegueWithIdentifier:@"ResultScreen" sender:self];
    }
}

@end

/*
     File: MainMenuViewController.m
 Abstract: View controller for the initial screen.  Manages creating the Quiz  
 and displaying the user's highest score.
 
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

#import "MainMenuViewController.h"
#import "Quiz.h"
#import "QuestionViewController.h"
#import "ResultsViewController.h"

@interface MainMenuViewController () <UITableViewDataSource, UITabBarControllerDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (readwrite) float highScore;
@end


@implementation MainMenuViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];

    // No highscrore when the view first loads.
    self.highScore = -1.0f;
}


//| ----------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}


//| ----------------------------------------------------------------------------
//  This method will be called when the 'Begin' button is tapped.
//
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Create a new Quiz from the Questions.plist file in the bundle resources.
    Quiz *newQuiz = [[Quiz alloc] initWithQuestionsPlistAtURL:[[NSBundle mainBundle] URLForResource:@"Questions" withExtension:@"plist"]];
    
    // Set the newQuiz as the currentQuiz of the destination view controller.
    QuestionViewController *firstQuestionVC = (QuestionViewController*)[segue.destinationViewController viewControllers][0];
    firstQuestionVC.currentQuiz = newQuiz;
}


//| ----------------------------------------------------------------------------
//! Unwinds from the ResultsViewController back to the MainMenuViewController
//! when the user taps the 'Return to the Home Screen' button.
//
//  This is an unwind action.  Note that the sender parameter is a
//  'UIStoryboardSegue*' instead of the usual 'id'.  Like all unwind actions,
//  this method is invoked early in the unwind process, before the visual
//  transition.  Note that the receiver of this method is the
//  destinationViewController of the segue.  Your view controller should use
//  this callback to retrieve information from the sourceViewController.  Used
//  properly, this method can replace existing delegation techniques for
//  passing information from a detail view controller to a previous view
//  controller in the navigation hierarchy.
//
- (IBAction)exitToHomeScreen:(UIStoryboardSegue *)unwindSegue
{
    // Retrieve the score from the ResultsViewController and update the high
    // score.
    ResultsViewController *resultVC = (ResultsViewController*)unwindSegue.sourceViewController;
    self.highScore = MAX(resultVC.currentQuiz.percentageScore, self.highScore);
}

#pragma mark - 
#pragma mark UITableViewDatasource

//| ----------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // If there is a highscore to display, there are three sections.  Else, 
    // there are two sections.
    return (self.highScore > -1.0f) ? 3 : 2;
}


//| ----------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // There is only one row per section.
    return 1;
}


//| ----------------------------------------------------------------------------
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == 0)
        cell = [tableView dequeueReusableCellWithIdentifier:@"Instructions"];
    else if (indexPath.section == 1 && tableView.numberOfSections == 3)
    // If there are three setions being displayed, the second row shows the
    // highscore.
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Score"];
        cell.textLabel.text = [NSString stringWithFormat:@"Your best recorded score is %.0f%%", self.highScore * 100];
    }
    else
        // Last section is always the Begin button.
        cell = [tableView dequeueReusableCellWithIdentifier:@"Begin"];
    
    return cell;
}

#pragma mark - 
#pragma mark UITableViewDelegate

//| ----------------------------------------------------------------------------
//  This delegate method is implemented because the height of the
//  instructions cell will need to change depending on the height required to
//  display the instruction text.  As the device rotates this will change.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    // Instructions cell
    {
        UITableViewCell *instructionsCell = [tableView dequeueReusableCellWithIdentifier:@"Instructions"];
        UILabel *instructionsLabel = instructionsCell.textLabel;
        
        // Use the -sizeWithFont:constrainedToSize: method of NSString to 
        // determine the required height of the instructions cell in order
        // to display the instructions without cutting off any of the text.
        
        // The width must be constrained to the width of the table view minus the
        // left and right margin of a grouped style cell.
        // Unfortunately, there is no way to lookup exactly what that margin is, 
        // so it must be hardcoded.
        // The height is left unconstrained.
        CGSize constrainingSize = CGSizeMake(tableView.bounds.size.width - 40*2, MAXFLOAT);
        
        return [instructionsLabel.text sizeWithFont:instructionsLabel.font constrainedToSize:constrainingSize].height;
    }
    
    return tableView.rowHeight;
}

@end

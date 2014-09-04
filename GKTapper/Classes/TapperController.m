/*
 
 File: TapperController.m
 Abstract: Basic introduction to GameCenter
 
 Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "AppSpecificValues.h"
#import "TapperController.h"

#import "GameCenterManager.h"

enum
{
	kCurrentScoreSection= 0,
	kScoreHandlingSection= 1,
	kLeaderBoardSection= 2,
	kShowViewControllersSection= 3
};


#define kNoScoreReusableCellID @"ReusableNoScoreCell"
#define kScoredReusableCellID @"ReusableScoreCell"
#define kDisclosureReusableCellID @"ReusableDisclosureCell"
#define kDisclosureWithLabelReusableCellID @"ReusableDisclosureWithLabelCell"

@implementation TapperController

@synthesize gameCenterManager;

@synthesize gameButtonView;
@synthesize resetAchievementsView;

@synthesize currentScore;
@synthesize cachedHighestScore;

@synthesize personalBestScoreDescription;
@synthesize personalBestScoreString;
@synthesize leaderboardHighScoreDescription;
@synthesize leaderboardHighScoreString;

@synthesize currentLeaderBoard;

- (void) showAlertWithTitle: (NSString*) title message: (NSString*) message
{
	UIAlertView* alert= [[[UIAlertView alloc] initWithTitle: title message: message 
												  delegate: NULL cancelButtonTitle: @"OK" otherButtonTitles: NULL] autorelease];
	[alert show];
	
}


#pragma mark Score Handlers
- (void) checkAchievements
{
	NSString* identifier= NULL;
	double percentComplete= 0;
	switch(self.currentScore)
	{
		case 1:
		{
			identifier= kAchievementGotOneTap;
			percentComplete= 100.0;
			break;
		}
		case 10:
		{
			identifier= kAchievementHidden20Taps;
			percentComplete= 50.0;
			break;
		}
		case 20:
		{
			identifier= kAchievementHidden20Taps;
			percentComplete= 100.0;
			break;
		}
		case 50:
		{
			identifier= kAchievementBigOneHundred;
			percentComplete= 50.0;
			break;
		}
		case 75:
		{
			identifier= kAchievementBigOneHundred;
			percentComplete= 75.0;
			break;
		}
		case 100:
		{
			identifier= kAchievementBigOneHundred;
			percentComplete= 100.0;
			break;
		}
			
	}
	if(identifier!= NULL)
	{
		[self.gameCenterManager submitAchievement: identifier percentComplete: percentComplete];
	}
}

- (void) updateCurrentScore
{
	[self checkAchievements];
	[self.tableView reloadData];
}



- (NSString*) currentLeaderboardHumanName
{
	return NSLocalizedString(currentLeaderBoard, @"Mapping the Leaderboard IDS");
}

#pragma mark View Controller Methods
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	self.currentLeaderBoard= kEasyLeaderboardID;
	
	self.currentScore= 0;
	
	[super viewDidLoad];
	if([GameCenterManager isGameCenterAvailable])
	{
		self.gameCenterManager= [[[GameCenterManager alloc] init] autorelease];
		[self.gameCenterManager setDelegate: self];
		[self.gameCenterManager authenticateLocalUser];
		
		[self updateCurrentScore];
	}
	else
	{
		[self showAlertWithTitle: @"Game Center Support Required!"
						 message: @"The current device does not support Game Center, which this sample requires."];
	}
}

#pragma mark TableView Configuration

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger rowCount= 0;
	switch (section)
	{
		case kCurrentScoreSection:
			rowCount= 1;
			break;
		case kScoreHandlingSection:
			rowCount= 2;
			break;
		case kLeaderBoardSection:
			rowCount= 3;
			break;
		case kShowViewControllersSection:
			rowCount= 2;
			break;
		default:
			assert(0);//Every section MUST define it's count.
			break;
	}
	return rowCount;
}

- (UITableViewCell*) getReusableCellForID: (NSString*) cellID
{
	UITableViewCell* retCell = [self.tableView dequeueReusableCellWithIdentifier:cellID];
	if([cellID isEqualToString: kScoredReusableCellID])
	{
		if (retCell == NULL)
		{
			retCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kScoredReusableCellID] autorelease];
			retCell.selectionStyle= UITableViewCellSelectionStyleNone;
		}
	}
	else if([cellID isEqualToString: kNoScoreReusableCellID])
	{
		if (retCell == NULL)
		{
			retCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kNoScoreReusableCellID] autorelease];
			retCell.textLabel.textColor=  achievementButton.currentTitleColor;
			retCell.textLabel.font=  achievementButton.titleLabel.font;
			retCell.textLabel.textAlignment=  achievementButton.titleLabel.textAlignment;
		}
	}
	else if([cellID isEqualToString: kDisclosureReusableCellID])
	{
		if (retCell == NULL)
		{
			retCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDisclosureReusableCellID] autorelease];
			retCell.accessoryType= UITableViewCellAccessoryDisclosureIndicator;
		}
	}
	else if([cellID isEqualToString: kDisclosureWithLabelReusableCellID])
	{
		if (retCell == NULL)
		{
			retCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kDisclosureWithLabelReusableCellID] autorelease];
			retCell.accessoryType= UITableViewCellAccessoryDisclosureIndicator;
		}
	}
	assert(retCell!= NULL); //Undefined reusable cell, should never happen.
	return retCell;
}

- (UITableViewCell*) tableCellForCurrentScoreSectionWithRow: (NSUInteger) rowNumber tableView: (UITableView *)tableView
{
	UITableViewCell *retCell= NULL;
	switch (rowNumber)
	{
		case 0:
		{
			retCell= [self getReusableCellForID: kScoredReusableCellID];
			retCell.textLabel.text = @"Current Score";
			retCell.detailTextLabel.text= [NSString stringWithFormat: @"%ld", self.currentScore];
			break;
		}
		default:
		{
			assert(0);//The switch statement must define all rows!
		}
	}
	return retCell;
}

- (UITableViewCell*) tableCellForScoreHandlingSectionWithRow: (NSUInteger) rowNumber tableView: (UITableView *)tableView
{
	UITableViewCell *retCell= NULL;
	switch (rowNumber)
	{
		case 0:
		{
			retCell= [self getReusableCellForID: kNoScoreReusableCellID];
			retCell.textLabel.text= @"Submit High Score...";
			break;
		}
		case 1:
		{
			retCell= [self getReusableCellForID: kNoScoreReusableCellID];
			retCell.textLabel.text= @"Increment Score...";
			break;
		}
		default:
		{
			assert(0);//The switch statement must define all rows!
		}
	}
	return retCell;
}

- (UITableViewCell*) tableCellForLeaderBoardSectionWithRow: (NSUInteger) rowNumber tableView: (UITableView *)tableView
{
	UITableViewCell *retCell= NULL;
	switch (rowNumber)
	{
		case 0:
		{
			retCell= [self getReusableCellForID: kDisclosureWithLabelReusableCellID];
			retCell.textLabel.text = @"Leaderboard";
			retCell.detailTextLabel.text= [self currentLeaderboardHumanName];
			break;
		}
		case 1:
		{
			retCell= [self getReusableCellForID: kScoredReusableCellID];
			retCell.textLabel.text = personalBestScoreDescription;
			retCell.detailTextLabel.text= personalBestScoreString;
			break;
		}
		case 2:
		{
			retCell= [self getReusableCellForID: kScoredReusableCellID];
			retCell.textLabel.text = leaderboardHighScoreDescription;
			retCell.detailTextLabel.text= leaderboardHighScoreString;
			break;
		}
		default:
		{
			assert(0);//The switch statement must define all rows!
		}
	}
	return retCell;
}

- (UITableViewCell*) tableCellForViewControllerSectionWithRow: (NSUInteger) rowNumber tableView: (UITableView *)tableView
{
	UITableViewCell* retCell= [self getReusableCellForID: kDisclosureReusableCellID];
	switch (rowNumber)
	{
		case 0:
		{
			retCell.textLabel.text= @"Show Leaderboards";
			break;
		}
		case 1:
		{
			retCell.textLabel.text= @"Show Achievements";
			break;
		}
		default:
		{
			assert(0);//The switch statement must define all rows!
		}
	}
	return retCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger sectionNumber= [indexPath indexAtPosition: 0];
	NSUInteger rowNumber= [indexPath indexAtPosition: 1];
	
	UITableViewCell *retCell= NULL;
	switch (sectionNumber)
	{
		case kCurrentScoreSection:
		{
			retCell= [self tableCellForCurrentScoreSectionWithRow: rowNumber tableView: tableView];
			break;
		}
		case kScoreHandlingSection:
		{
			retCell= [self tableCellForScoreHandlingSectionWithRow: rowNumber tableView: tableView];
			break;
		}
		case kLeaderBoardSection:
		{
			retCell= [self tableCellForLeaderBoardSectionWithRow: rowNumber tableView: tableView];
			break;
		}
		case kShowViewControllersSection:
		{
			retCell= [self tableCellForViewControllerSectionWithRow: rowNumber tableView: tableView];
			break;
		}
		default:
			assert(0); //All cells should be explicitly defined.
			break;
	}
	return retCell;
}

#pragma mark TableView Footer Configuration

static const CGFloat kGapViewHeight= 2.f;
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	CGFloat retVal= kGapViewHeight;
	switch (section)
	{
		case kShowViewControllersSection:
			retVal= resetAchievementsView.frame.size.height;
			break;
	}
	return retVal;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	static UIView* gapView= NULL;
	if(NULL == gapView)
	{
		gapView= [[UIView alloc] initWithFrame: CGRectMake(resetAchievementsView.frame.origin.x, resetAchievementsView.frame.origin.y, resetAchievementsView.frame.size.width, kGapViewHeight)];
	}
	UIView* retVal= gapView;
	switch (section)
	{
		case kShowViewControllersSection:
			retVal= resetAchievementsView;
			break;
	}
	return retVal;
}

#pragma mark TableView Selection Handler
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	switch(buttonIndex)
	{
		case 0:
			currentLeaderBoard = kAwesomeLeaderboardID;
			break;
		case 1:
			currentLeaderBoard = kHardLeaderboardID;
			break;
		case 2:
			currentLeaderBoard = kEasyLeaderboardID;
			break;
		case 3: //Cancel...
			return;
		default:
			assert(0); //This should never happen...
			break;
	}
	self.currentScore= 0;
	[self.gameCenterManager reloadHighScoresForCategory: self.currentLeaderBoard];
	[self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger sectionNumber= [indexPath indexAtPosition: 0];
	NSUInteger rowNumber= [indexPath indexAtPosition: 1];

	switch (sectionNumber)
	{
		case kScoreHandlingSection:
		{
			if(rowNumber == 0)
			{
				[self submitHighScore];
			}
			else
			{
				if(rowNumber == 1)
				{
					[self addOne];
				}
			}
			break;
		}
		case kLeaderBoardSection:
		{
			if(rowNumber == 0)
			{
				UIActionSheet* selectLeaderboard= [[[UIActionSheet alloc] initWithTitle: @"Select Leaderboard" delegate:self cancelButtonTitle: @"Cancel" destructiveButtonTitle: NULL
																	  otherButtonTitles: [NSString stringWithFormat: @"%@ Leaderboard", NSLocalizedString(kAwesomeLeaderboardID, NULL)],
																						 [NSString stringWithFormat: @"%@ Leaderboard", NSLocalizedString(kHardLeaderboardID, NULL)],
																						 [NSString stringWithFormat: @"%@ Leaderboard", NSLocalizedString(kEasyLeaderboardID, NULL)], NULL] autorelease];
				[selectLeaderboard showInView: self.view];
			}
			[self.tableView deselectRowAtIndexPath: indexPath animated: NO];
			break;
		}
		case kShowViewControllersSection:
		{
			if(rowNumber== 0)
			{
				[self showLeaderboard];
			}
			else
			{
				[self showAchievements];
			}
			break;
		}
		default:
			[self.tableView deselectRowAtIndexPath: indexPath animated: NO];
			break;
	}
}





#pragma mark Action Methods
- (void) addOne;
{
	self.currentScore= self.currentScore + 1;
	[self updateCurrentScore];
}

- (void) submitHighScore
{
	if(self.currentScore > 0)
	{
		[self.gameCenterManager reportScore: self.currentScore forCategory: self.currentLeaderBoard];
	}
}

#pragma mark GameCenter View Controllers
- (void) showLeaderboard;
{
	GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];
	if (leaderboardController != NULL) 
	{
		leaderboardController.category = self.currentLeaderBoard;
		leaderboardController.timeScope = GKLeaderboardTimeScopeAllTime;
		leaderboardController.leaderboardDelegate = self; 
		[self presentModalViewController: leaderboardController animated: YES];
	}
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	[self dismissModalViewControllerAnimated: YES];
	[viewController release];
}

- (void) showAchievements
{
	GKAchievementViewController *achievements = [[GKAchievementViewController alloc] init];
	if (achievements != NULL)
	{
		achievements.achievementDelegate = self;
		[self presentModalViewController: achievements animated: YES];
	}
}

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController;
{
	[self dismissModalViewControllerAnimated: YES];
	[viewController release];
}

- (IBAction) resetAchievements: (id) sender
{
	[gameCenterManager resetAchievements];
}


#pragma mark GameCenterDelegateProtocol Methods
//Delegate method used by processGameCenterAuth to support looping waiting for game center authorization
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	[self.gameCenterManager authenticateLocalUser];
}

- (void) processGameCenterAuth: (NSError*) error
{
	if(error == NULL)
	{
		[self.gameCenterManager reloadHighScoresForCategory: self.currentLeaderBoard];
	}
	else
	{
		UIAlertView* alert= [[[UIAlertView alloc] initWithTitle: @"Game Center Account Required" 
									message: [NSString stringWithFormat: @"Reason: %@", [error localizedDescription]]
									delegate: self cancelButtonTitle: @"Try Again..." otherButtonTitles: NULL] autorelease];
		[alert show];
	}
	
}

- (void) mappedPlayerIDToPlayer: (GKPlayer*) player error: (NSError*) error;
{
	if((error == NULL) && (player != NULL))
	{
		self.leaderboardHighScoreDescription= [NSString stringWithFormat: @"%@ got:", player.alias];
		
		if(self.cachedHighestScore != NULL)
		{
			self.leaderboardHighScoreString= self.cachedHighestScore;
		}
		else
		{
			self.leaderboardHighScoreString= @"-";
		}

	}
	else
	{
		self.leaderboardHighScoreDescription= @"GameCenter Scores Unavailable";
		self.leaderboardHighScoreDescription=  @"-";
	}
	[self.tableView reloadData];
}

- (void) reloadScoresComplete: (GKLeaderboard*) leaderBoard error: (NSError*) error;
{
	if(error == NULL)
	{
		int64_t personalBest= leaderBoard.localPlayerScore.value;
		self.personalBestScoreDescription= @"Your Best:";
		self.personalBestScoreString= [NSString stringWithFormat: @"%ld", personalBest];
		if([leaderBoard.scores count] >0)
		{
			self.leaderboardHighScoreDescription=  @"-";
			self.leaderboardHighScoreString=  @"";
			GKScore* allTime= [leaderBoard.scores objectAtIndex: 0];
			self.cachedHighestScore= allTime.formattedValue;
			[gameCenterManager mapPlayerIDtoPlayer: allTime.playerID];
		}
	}
	else
	{
		self.personalBestScoreDescription= @"GameCenter Scores Unavailable";
		self.personalBestScoreString=  @"-";
		self.leaderboardHighScoreDescription= @"GameCenter Scores Unavailable";
		self.leaderboardHighScoreDescription=  @"-";
		[self showAlertWithTitle: @"Score Reload Failed!"
						 message: [NSString stringWithFormat: @"Reason: %@", [error localizedDescription]]];
	}
	[self.tableView reloadData];
}

- (void) scoreReported: (NSError*) error;
{
	if(error == NULL)
	{
		[self.gameCenterManager reloadHighScoresForCategory: self.currentLeaderBoard];
		[self showAlertWithTitle: @"High Score Reported!"
						 message: [NSString stringWithFormat: @"", [error localizedDescription]]];
	}
	else
	{
		[self showAlertWithTitle: @"Score Report Failed!"
						 message: [NSString stringWithFormat: @"Reason: %@", [error localizedDescription]]];
	}
}



- (void) achievementSubmitted: (GKAchievement*) ach error:(NSError*) error;
{
	if((error == NULL) && (ach != NULL))
	{
		if(ach.percentComplete == 100.0)
		{
			[self showAlertWithTitle: @"Achievement Earned!"
				  message: [NSString stringWithFormat: @"Great job!  You earned an achievement: \"%@\"", NSLocalizedString(ach.identifier, NULL)]];
		}
		else
		{
			if(ach.percentComplete > 0)
			{
				[self showAlertWithTitle: @"Achievement Progress!"
					  message: [NSString stringWithFormat: @"Great job!  You're %.0f\%% of the way to: \"%@\"",ach.percentComplete, NSLocalizedString(ach.identifier, NULL)]];
			}
		}
	}
	else
	{
		[self showAlertWithTitle: @"Achievement Submission Failed!"
			  message: [NSString stringWithFormat: @"Reason: %@", [error localizedDescription]]];
	}
}

- (void) achievementResetResult: (NSError*) error;
{
	self.currentScore= 0;
	[self.tableView reloadData];
	if(error != NULL)
	{
		[self showAlertWithTitle: @"Achievement Reset Failed!"
			  message: [NSString stringWithFormat: @"Reason: %@", [error localizedDescription]]];
	}
}
@end

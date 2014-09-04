/*
     File: RecipeListTableViewController.m 
 Abstract: The UITableViewController for displaying a list of recipes 
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

#import "RecipeListTableViewController.h"
#import "RecipeDetailViewController.h"

#import "Recipe.h"
#import "RecipesController.h"
#import "RecipePrintPageRenderer.h"

#import "RecipeTableViewCell.h"

@interface RecipeListTableViewController()

- (void)printSelectedRecipes:(id)sender;
@property (nonatomic, strong) RecipesController *recipesController;

@end



@implementation RecipeListTableViewController

// Custom initializer that makes the recipes/model controller available to the table view controller.
- (id)initWithStyle:(UITableViewStyle)style recipesController:(RecipesController *)aRecipesController {
	
    self = [super initWithStyle:style];
    if (self) {
        _recipesController = aRecipesController;
        
        self.title = NSLocalizedString(@"Recipes",@"");

        // Add a print button and use self -printSelectedRecipes: as the press handler
        UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Print", @"") 
                                                                          style:UIBarButtonItemStyleBordered 
                                                                         target:self 
                                                                         action:@selector(printSelectedRecipes:)];        
        // Set the Print button as the right side button item of this view controller's navigation bar
        self.navigationItem.rightBarButtonItem = addButtonItem;
        

        // Increase the height of the table rows - 1 pixel higher than the recipe thumbnails displayed in the table cells.
        self.tableView.rowHeight = 43.0;
	}
	return self;
}

// Release ownership.


#pragma mark -
#pragma mark Printing

// Print button handler that sends our print instructions to the OS
- (void)printSelectedRecipes:(id)sender {
    
    // Get a reference to the singleton iOS printing concierge
    UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];

    // Throw all recipes into an array to hand off to the printing code.
    NSArray *recipes = [self.recipesController.recipes copy];
    
    // Instruct the printing concierge to use our custom UIPrintPageRenderer subclass when printing this job
    printController.printPageRenderer = [[RecipePrintPageRenderer alloc] initWithRecipes:recipes];
    
    // Ask for a print job object and configure its settings to tailor the print request
    UIPrintInfo *info = [UIPrintInfo printInfo];
    
    // B&W or color, normal quality output for mixed text, graphics, and images
    info.outputType = UIPrintInfoOutputGeneral;
    
    // Select the job named this in the printer queue to cancel our print request.
    info.jobName = @"Recipes";
    
    // Instruct the printing concierge to use our custom print job settings. 
    printController.printInfo = info;
    
    // Present the standard iOS Print Panel that allows you to pick the target Printer, number of pages, double-sided, etc.
    [printController presentAnimated:YES completionHandler:^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        ;
    }];
}

#pragma mark -
#pragma mark UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark -
#pragma mark UITableView Delegate/Datasource

// Determines the number of sections within this table view
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // This displays a single list of recipes, so one section will do.
	return 1; 
}


// Determines the number of rows for the argument section number
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Since this sample has only one section, assume we were passed section = 1, and return the number of recipes.
	return self.recipesController.countOfRecipes;
}


// Create or Access and return appropriate cell identified by the argument indexPath (i.e. Section number and Row number combination)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Define an identifier we can associate with table cells. Used with cell reuse as follows.
	static NSString *recipeIdentifier = @"Recipe";

    // Ask for a cached cell that's been moved off the screen that we can therefore repurpose for a new cell coming onto the screen. 
    RecipeTableViewCell *recipeCell = (RecipeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:recipeIdentifier];
    
    // If no cached cells are available, create one. Depending on your table row height, we only need to create enough to fill one screen.
    // After that, the above call will start working to give us the cell that got scrolled off the screen.
	if (recipeCell == nil) {
		recipeCell = [[RecipeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:recipeIdentifier];
	}

	// Provide to the cell its corresponding recipe depending on the argument row
    recipeCell.recipe = [self.recipesController objectInRecipesAtIndex:indexPath.row];
    
    // Right arrow-looking indicator on the right side of the table view cell
    recipeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return recipeCell;
}

// Cell touch handler that pushes the recipe detail view onto the navigation controller stack
- (void)showRecipe:(Recipe *)recipe animated:(BOOL)animated {
    RecipeDetailViewController *detailViewController = [[RecipeDetailViewController alloc] initWithRecipe:recipe];
    [self.navigationController pushViewController:detailViewController animated:animated];
}


// Call the cell touch handler and pass in the recipe associated with the argument section/row
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Recipe *recipe = [self.recipesController objectInRecipesAtIndex:indexPath.row];
    [self showRecipe:recipe animated:YES];
}

@end

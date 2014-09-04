/*
     File: RecipeDetailViewController.m
 Abstract: Table view controller to manage an editable table view that displays information about a recipe.
 The table view uses different cell types for different row types.
 
  Version: 1.5
 
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

#import "RecipeDetailViewController.h"

#import "Recipe.h"
#import "Ingredient.h"

#import "InstructionsViewController.h"
#import "TypeSelectionViewController.h"
#import "RecipePhotoViewController.h"
#import "IngredientDetailViewController.h"

@interface IngredientCell : UITableViewCell
@end
@implementation IngredientCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{ return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]; }
@end


#pragma mark -

@interface RecipeDetailViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) NSMutableArray *ingredients;

@property (nonatomic, strong) IBOutlet UIView *tableHeaderView;
@property (nonatomic, strong) IBOutlet UIButton *photoButton;
@property (nonatomic, strong) IBOutlet UITextField *nameTextField;
@property (nonatomic, strong) IBOutlet UITextField *overviewTextField;
@property (nonatomic, strong) IBOutlet UITextField *prepTimeTextField;
@property (assign) BOOL singleEdit; // indicates user is swipe-deleting a particular ingredient

- (void)updatePhotoButton;

@end


#pragma mark -

@implementation RecipeDetailViewController

// table's section indexes
#define TYPE_SECTION            0
#define INGREDIENTS_SECTION     1
#define INSTRUCTIONS_SECTION    2

// segue ID when "Add Ingredient" cell is tapped
static NSString *kAddIngredientSegueID = @"addIngredient";

// segue ID when "Instructions" cell is tapped
static NSString *kShowInstructionsSegueID = @"showInstructions";

// segue ID when the recipe (category) cell is tapped
static NSString *kShowRecipeTypeSegueID = @"showRecipeType";


#pragma mark - View controller

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
	
    [self.photoButton setImage:self.recipe.thumbnailImage forState:UIControlStateNormal];
	self.navigationItem.title = self.recipe.name;
    self.nameTextField.text = self.recipe.name;
    self.overviewTextField.text = self.recipe.overview;
    self.prepTimeTextField.text = self.recipe.prepTime;
	[self updatePhotoButton];

	/*
	 Create a mutable array that contains the recipe's ingredients ordered by displayOrder.
	 The table view uses this array to display the ingredients.
	 Core Data relationships are represented by sets, so have no inherent order. Order is "imposed" using the displayOrder attribute, but it would be inefficient to create and sort a new array each time the ingredients section had to be laid out or updated.
	 */
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:&sortDescriptor count:1];
	
	NSMutableArray *sortedIngredients = [[NSMutableArray alloc] initWithArray:[self.recipe.ingredients allObjects]];
	[sortedIngredients sortUsingDescriptors:sortDescriptors];
	self.ingredients = sortedIngredients;

	// update recipe type and ingredients on return
    [self.tableView reloadData]; 
}


#pragma mark - Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
    
    if (!self.singleEdit) {
        [self updatePhotoButton];
        self.nameTextField.enabled = editing;
        self.overviewTextField.enabled = editing;
        self.prepTimeTextField.enabled = editing;
        [self.navigationItem setHidesBackButton:editing animated:YES];

        [self.tableView beginUpdates];
        
        NSUInteger ingredientsCount = self.recipe.ingredients.count;
        
        NSArray *ingredientsInsertIndexPath = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:ingredientsCount inSection:INGREDIENTS_SECTION]];
        
        if (editing) {
            [self.tableView insertRowsAtIndexPaths:ingredientsInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
            self.overviewTextField.placeholder = @"Overview";
        } else {
            [self.tableView deleteRowsAtIndexPaths:ingredientsInsertIndexPath withRowAnimation:UITableViewRowAnimationTop];
            self.overviewTextField.placeholder = @"";
        }
        
        [self.tableView endUpdates];
    }
    
	/*
	 If editing is finished, save the managed object context.
	 */
	if (!editing) {
		NSManagedObjectContext *context = self.recipe.managedObjectContext;
		NSError *error = nil;
		if (![context save:&error]) {
			/*
			 Replace this implementation with code to handle the error appropriately.
			 
			 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
			 */
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	
	if (textField == self.nameTextField) {
		self.recipe.name = self.nameTextField.text;
		self.navigationItem.title = self.recipe.name;
	}
	else if (textField == self.overviewTextField) {
		self.recipe.overview = self.overviewTextField.text;
	}
	else if (textField == self.prepTimeTextField) {
		self.recipe.prepTime = self.prepTimeTextField.text;
	}
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
	[textField resignFirstResponder];
	return YES;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSString *title = nil;
    
    // return a title or nil as appropriate for the section
    switch (section) {
        case TYPE_SECTION:
            title = @"Category";
            break;
        case INGREDIENTS_SECTION:
            title = @"Ingredients";
            break;
        default:
            break;
    }
    
    return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger rows = 0;
    
    /*
     The number of rows depends on the section.
     In the case of ingredients, if editing, add a row in editing mode to present an "Add Ingredient" cell.
	 */
    switch (section) {
        case TYPE_SECTION:
        case INSTRUCTIONS_SECTION:
            // these sections have only one row
            rows = 1;
            break;
        case INGREDIENTS_SECTION:
            rows = self.recipe.ingredients.count;
            if (self.editing) {
                rows++;
            }
            break;
		default:
            break;
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    // For the Ingredients section, if necessary create a new cell and configure it with
    // an additional label for the amount.  Give the cell a different identifier from that
    // used for cells in other sections so that it can be dequeued separately.
    //
    if (indexPath.section == INGREDIENTS_SECTION) {
		NSUInteger ingredientCount = self.recipe.ingredients.count;
        NSInteger row = indexPath.row;
		
        if (indexPath.row < (NSInteger)ingredientCount) {
            // If the row is within the range of the number of ingredients for the current recipe,
            // then configure the cell to show the ingredient name and amount.
			//
			cell = [tableView dequeueReusableCellWithIdentifier:@"IngredientsCell" forIndexPath:indexPath];

            Ingredient *ingredient = [self.ingredients objectAtIndex:row];
            cell.textLabel.text = ingredient.name;
			cell.detailTextLabel.text = ingredient.amount;
        } else {
            // If the row is outside the range, it's the row that was added to allow insertion
            // (see tableView:numberOfRowsInSection:) so give it an appropriate label.
            //
			cell = [tableView dequeueReusableCellWithIdentifier:@"AddIngredientCellIdentifier" forIndexPath:indexPath];
        }
    } else {
        switch (indexPath.section) {
            case TYPE_SECTION:  // recipe type cell
                cell = [tableView dequeueReusableCellWithIdentifier:@"RecipeType" forIndexPath:indexPath];
                cell.textLabel.text = [self.recipe.type valueForKey:@"name"];
                break;
                
            case INSTRUCTIONS_SECTION: // instructions cell
                cell = [tableView dequeueReusableCellWithIdentifier:@"Instructions" forIndexPath:indexPath];
                break;
                
            default:
                break;
        }
    }
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // user has started a swipe to delete operation
    self.singleEdit = YES;
}

- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // swipe to delete operation has ended
    self.singleEdit = NO;
}

- (Ingredient *)ingredientByName:(NSString *)ingredientName {
    
    Ingredient *ingredient = nil;
    NSArray *ingredients = [self.recipe.ingredients allObjects];
    for (ingredient in ingredients) {
        if ([ingredient.name isEqualToString:ingredientName])
            break;  // we found the right ingredient by title
    }
    return ingredient;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == TYPE_SECTION && indexPath.row == 0) {
        // edit the recipe "type"- pass the recipe
        //
        TypeSelectionViewController *typeSelectionViewController =
            [[TypeSelectionViewController alloc] initWithStyle:UITableViewStylePlain];
        typeSelectionViewController.recipe = self.recipe;
        
        // present modally the recipe type view controller
        UINavigationController *navController =
            [[UINavigationController alloc] initWithRootViewController:typeSelectionViewController];
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    }
    else if (indexPath.section == INGREDIENTS_SECTION) {
        // edit the recipe "ingredient" - pass the ingredient
        //
        IngredientDetailViewController *ingredientDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"IngredientDetailViewController"];
        ingredientDetailViewController.recipe = self.recipe;
        
        // find the selected ingredient table cell (based on indexPath),
        // use it's ingredient title to find the right ingredient object in this recipe.
        // note: you can't use indexPath.row to lookup the recipe's ingredient object because NSSet is not ordered
        //
        UITableViewCell *ingredientCell = [tableView cellForRowAtIndexPath:indexPath];
        ingredientDetailViewController.ingredient = [self ingredientByName:ingredientCell.textLabel.text];
        
        // present modally the ingredient detail view controller
        UINavigationController *navController =
            [[UINavigationController alloc] initWithRootViewController:ingredientDetailViewController];
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSIndexPath *rowToSelect = indexPath;
    NSInteger section = indexPath.section;
    BOOL isEditing = self.editing;
    
    // If editing, don't allow instructions to be selected
    // Not editing: Only allow instructions to be selected
    //
    if ((isEditing && section == INSTRUCTIONS_SECTION) || (!isEditing && section != INSTRUCTIONS_SECTION)) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        rowToSelect = nil;    
    }

	return rowToSelect;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:kAddIngredientSegueID]) {
        // add an ingredient
        //
        Recipe *recipe = nil;
        if ([sender isKindOfClass:[Recipe class]]) {
            // the sender is the actual recipe send from "didAddRecipe" delegate (user created a new recipe)
            // pass the recipe
            recipe = (Recipe *)sender;
            
            UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
            IngredientDetailViewController *ingredientDetailViewController = (IngredientDetailViewController *)navController.topViewController;
            ingredientDetailViewController.recipe = recipe;
        }
    }
    else if ([segue.identifier isEqualToString:kShowInstructionsSegueID]) {
        // show and/or edit the instructions - pass the recipe
        //
        InstructionsViewController *instructionsViewController = (InstructionsViewController *)segue.destinationViewController;
        instructionsViewController.recipe = self.recipe;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
    
    // Only allow editing in the ingredients section.
    // In the ingredients section, the last row (row number equal to the count of ingredients)
    // is added automatically (see tableView:cellForRowAtIndexPath:) to provide an insertion cell,
    // so configure that cell for insertion; the other cells are configured for deletion.
    //
    if (indexPath.section == INGREDIENTS_SECTION) {
        // If this is the last item, it's the insertion row.
        if (indexPath.row == (NSInteger)self.recipe.ingredients.count) {
            style = UITableViewCellEditingStyleInsert;
        }
        else {
            style = UITableViewCellEditingStyleDelete;
        }
    }
    
    return style;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Only allow deletion, and only in the ingredients section
    if ((editingStyle == UITableViewCellEditingStyleDelete) && (indexPath.section == INGREDIENTS_SECTION)) {
        // Remove the corresponding ingredient object from the recipe's ingredient list and delete the appropriate table view cell.
        Ingredient *ingredient = [self.ingredients objectAtIndex:indexPath.row];
        [self.recipe removeIngredientsObject:ingredient];
        [self.ingredients removeObject:ingredient];
        
        NSManagedObjectContext *context = ingredient.managedObjectContext;
        [context deleteObject:ingredient];
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // user tapped the "+" button to add a new ingredient
        
        [self performSegueWithIdentifier:kAddIngredientSegueID sender:self.recipe];
    }
}


#pragma mark - Moving rows

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BOOL canMove = NO;
    // Moves are only allowed within the ingredients section.  Within the ingredients section, the last row (Add Ingredient) cannot be moved.
    if (indexPath.section == INGREDIENTS_SECTION) {
        canMove = indexPath.row != (NSInteger)self.recipe.ingredients.count;
    }
    return canMove;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    
    NSIndexPath *target = proposedDestinationIndexPath;
    
    // Moves are only allowed within the ingredients section, so make sure the destination
    // is in the ingredients section. If the destination is in the ingredients section,
    // make sure that it's not the Add Ingredient row -- if it is, retarget for the penultimate row.
    //
	NSUInteger proposedSection = proposedDestinationIndexPath.section;
	
    if (proposedSection < INGREDIENTS_SECTION) {
        target = [NSIndexPath indexPathForRow:0 inSection:INGREDIENTS_SECTION];
    } else if (proposedSection > INGREDIENTS_SECTION) {
        target = [NSIndexPath indexPathForRow:(self.recipe.ingredients.count - 1) inSection:INGREDIENTS_SECTION];
    } else {
        NSUInteger ingredientsCount_1 = self.recipe.ingredients.count - 1;
        
        if (proposedDestinationIndexPath.row > (NSInteger)ingredientsCount_1) {
            target = [NSIndexPath indexPathForRow:ingredientsCount_1 inSection:INGREDIENTS_SECTION];
        }
    }
	
    return target;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
	/*
	 Update the ingredients array in response to the move.
	 Update the display order indexes within the range of the move.
	 */
    Ingredient *ingredient = [self.ingredients objectAtIndex:fromIndexPath.row];
    [self.ingredients removeObjectAtIndex:fromIndexPath.row];
    [self.ingredients insertObject:ingredient atIndex:toIndexPath.row];
	
	NSInteger start = fromIndexPath.row;
	if (toIndexPath.row < start) {
		start = toIndexPath.row;
	}
	NSInteger end = toIndexPath.row;
	if (fromIndexPath.row > end) {
		end = fromIndexPath.row;
	}
	for (NSInteger i = start; i <= end; i++) {
		ingredient = [self.ingredients objectAtIndex:i];
		ingredient.displayOrder = [NSNumber numberWithInteger:i];
	}
}


#pragma mark - Photo

- (IBAction)photoTapped {
    
    // If in editing state, then display an image picker; if not, create and push a photo view controller.
	if (self.editing) {
		UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
		imagePicker.delegate = self;
		[self presentViewController:imagePicker animated:YES completion:nil];
	} else {	
		RecipePhotoViewController *recipePhotoViewController = [[RecipePhotoViewController alloc] init];
        recipePhotoViewController.hidesBottomBarWhenPushed = YES;
		recipePhotoViewController.recipe = self.recipe;
		[self.navigationController pushViewController:recipePhotoViewController animated:YES];
	}
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)selectedImage editingInfo:(NSDictionary *)editingInfo {
	
	// Delete any existing image.
	NSManagedObject *oldImage = self.recipe.image;
	if (oldImage != nil) {
		[self.recipe.managedObjectContext deleteObject:oldImage];
	}
	
    // Create an image object for the new image.
	NSManagedObject *image =
        [NSEntityDescription insertNewObjectForEntityForName:@"Image"
                                      inManagedObjectContext:self.recipe.managedObjectContext];
	self.recipe.image = image;

	// Set the image for the image managed object.
	[image setValue:selectedImage forKey:@"image"];
	
	// Create a thumbnail version of the image for the recipe object.
	CGSize size = selectedImage.size;
	CGFloat ratio = 0;
	if (size.width > size.height) {
		ratio = 44.0 / size.width;
	} else {
		ratio = 44.0 / size.height;
	}
	CGRect rect = CGRectMake(0.0, 0.0, ratio * size.width, ratio * size.height);
	
	UIGraphicsBeginImageContext(rect.size);
	[selectedImage drawInRect:rect];
	self.recipe.thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updatePhotoButton {
    
	/*
	 How to present the photo button depends on the editing state and whether the recipe has a thumbnail image.
	 * If the recipe has a thumbnail, set the button's highlighted state to the same as the editing state (it's highlighted if editing).
	 * If the recipe doesn't have a thumbnail, then: if editing, enable the button and show an image that says "Choose Photo" or similar; if not editing then disable the button and show nothing.  
	 */
	BOOL editing = self.editing;
	
	if (self.recipe.thumbnailImage != nil) {
		self.photoButton.highlighted = editing;
	} else {
		self.photoButton.enabled = editing;
		
		if (editing) {
			[self.photoButton setImage:[UIImage imageNamed:@"choosePhoto.png"] forState:UIControlStateNormal];
		} else {
			[self.photoButton setImage:nil forState:UIControlStateNormal];
		}
	}
}

@end

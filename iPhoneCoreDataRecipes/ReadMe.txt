### iPhoneRecipes ###

================================================================================
DESCRIPTION:

This sample shows how you can use view controllers, table views, and Core Data in an iPhone application.

The application uses the domain of organizing and presenting recipes to show how you can use the view controller as the organizing unit to manage screenfuls of information, and how you can leverage table views to display and edit data in an elegant fashion.

Amongst the techniques shown are how to:
* Combine tab bar and navigation controllers to create a complex navigation flow
* Customize a navigation bar
* Implement custom table view cells that reformat themselves in response to editing, removing unnecessary information to ensure that the display remains uncluttered
* Customize a table header view
* Present modal views
* Use multiple entities in a Core Data application
* Provide a default Core Data persistent store

================================================================================
BUILD REQUIREMENTS:

iOS SDK 7.0 or later

================================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later

================================================================================
PACKAGING LIST:

Model and Model Classes
-----------------------

Recipes.xcdatamodel
Core Data model file containing the Core Data schema for the application.

Recipe.{h,m}
Model class to represent a recipe, including UIImageToDataTransformer -- a reversible value transformer to transform from a UIIMage object to an NSData object.

Ingredient.{h,m}
Model class to represent an ingredient.

Application Configuration
-------------------------
RecipesAppDelegate.{h,m}
Storyboard.storyboard
Application delegate that sets up a tab bar controller with two view controllers -- a navigation controller that in turn loads a table view controller to manage a list of recipes, and a unit converter view controller.

Recipes View Controllers
------------------------
RecipeListTableViewController.{h,m}
Table view controller to manage an editable table view that displays a list of recipes.
This is the "topmost" view controller in the Recipes stack.

RecipeDetailViewController.{h,m}
Table view controller to manage as table view that displays information about a recipe.  The table view header is loaded from a separate nib file.
The user can edit all aspects of the recipe -- the name, overview, and preparation time "inline" in the table view header; the type by navigating to a list of all the types and selecting one from the list (see IngredientDetailViewController); the photo by using a photo picker; and so on.

RecipeAddViewController.{h,m}
View controller to allow the user to add a new recipe and choose its name.

IngredientDetailViewController.{h,m}
Table view controller to manage editing details of a recipe ingredient -- its name and amount.

TypeSelectionViewController.{h,m}
Table view controller to allow the user to select the recipe type.

InstructionsViewController.{h,m}
View controller to manage a text view to allow the user to edit instructions for a recipe.

RecipePhotoViewController.{h,m}
View controller to manage a view to display a recipe's photo.


Conversion View Controllers
---------------------------
TemperatureConverterViewController.{h,m}
View controller to display a table view showing cooking temperatures in Centigrade, Fahrenheit, and Gas Mark.

WeightConverterViewController.{h,m}
View controller to manage conversion of metric to imperial units of weight and vice versa.
The controller uses two UIPicker objects to allow the user to select the weight in metric or imperial units.

ImperialPickerController.{h,m}
Controller to managed a picker view displaying imperial weights.

MetricPickerController.{h,m}
Controller to managed a picker view displaying metric weights.


Table view cells
----------------
EditingTableCell.{h,m}
A table view cell that displays a label on the left and a text field on the right so that the user can edit text in place.

RecipeTableViewCell.{h,m}
A table view cell that displays information about a Recipe.  It uses individual subviews of its content view to show the name, picture, description, and preparation time for each recipe.  If the table view switches to editing mode, the cell reformats itself to move the preparation time off-screen, and resizes the name and description fields accordingly.

TemperatureCell.{h,m}
A table view cell that displays temperature in Centigrade, Fahrenheit, and Gas Mark.


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.5
- Upgraded for iOS 7, modernized, and upgraded to use ARC, now uses storyboard.

Version 1.4
- Deployment target set to iPhone OS 3.2.

Version 1.3
- Replaced deprecated "didFinishPickingImage" method of UIImagePickerController
- Upgraded project to build with the iOS 4 SDK.

Version 1.2
- Corrected a memory management error in IngredientDetailViewController.m.
- Updated implementation of controller:didChangeObject:atIndexPath:forChangeType:newIndexPath: in RecipeListTableViewController.m.
- Changed base SDK to 3.1.

Version 1.1
- Added UIGraphicsEndImageContext and textFieldShouldReturn: method to RecipeDetailViewController.m.
- Added viewDidUnload methods to several view controllers.
- Cleaned up error-handling code.
- Added a xib file for TemperatureCell.

Version 1.0
- First version.

================================================================================
Copyright (C) 2010-2014 Apple Inc. All rights reserved.
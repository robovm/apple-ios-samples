/*
     File: RecipePrintPageRenderer.m 
 Abstract: A custom UIPrintPageRenderer to render one or more Recipes for printing 
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
  
 Copyright (C) 2013 Apple Inc. All Rights Reserved. 
  
 */ 

#import "RecipePrintPageRenderer.h"
#import "Recipe.h"
#import <objc/runtime.h>


/*
 Set up some values for the constant properties of our custom
 recipe printed presentation.
 */
#define HEADER_HEIGHT 20
#define FOOTER_HEIGHT 20
#define PADDING 10
#define TITLE_SIZE 24
#define SYSTEM_FONT [UIFont systemFontOfSize:[UIFont systemFontSize]]

@interface RecipePrintPageRenderer ()

@property (nonatomic) CGFloat recipeInfoHeight;

- (void)setupPrintFormatters;
- (CGRect)contentArea;
- (void)drawRecipe:(Recipe *)recipe inRect:(CGRect)rect;
- (void)drawRecipeImage:(UIImage *)image inRect:(CGRect)rect;
- (void)drawRecipeName:(NSString *)name inRect:(CGRect)rect;
- (void)drawRecipeInfo:(NSString *)info inRect:(CGRect)rect;

@end

@implementation RecipePrintPageRenderer
{
    NSRange pageRange;
    NSArray *recipes;
    NSMapTable *formatterToRecipeMap;
}

/*
 Initialize to our constant values.
 */
- (id)initWithRecipes:(NSArray *)someRecipes
{
    self = [super init];
    if (self) {
        recipes = [someRecipes copy];
        formatterToRecipeMap = [NSMapTable strongToStrongObjectsMapTable];
        self.headerHeight = HEADER_HEIGHT;
        self.footerHeight = FOOTER_HEIGHT;
        self.recipeInfoHeight = 150;
    }
    
    return self;
}

/*
 Release ownership.
 */

#pragma mark -

/*
 Calculate the content area based on the printableRect, that is, 
 the area in which the printer can print content. a.k.a the imageable area of the paper.
 */
- (CGRect)contentArea {
    CGRect r = self.printableRect;
    r.origin.y += self.headerHeight;
    r.size.height -= self.headerHeight + self.footerHeight;
    return r;
}

- (void)prepareForDrawingPages:(NSRange)range {
    pageRange = range;
    [super prepareForDrawingPages:range];
}

#pragma mark -

/*
 This method must be overriden when doing custom drawing as we are. 
 Since our custom drawing is really only for the borders and we are 
 relying on a series of UIMarkupTextPrintFormatter to display the recipe
 content, UIKit can calculate the number of pages based on informtation
 provided by those formatters. 
 
 Therefore, setup the formatters, and ask super to count the pages.
 */
- (NSInteger)numberOfPages {
    self.printFormatters = nil;
    [self setupPrintFormatters];
    return [super numberOfPages];
}

/*
 Iterate through the recipes setting each of their html representations into 
 a UIMarkupTextPrintFormatter and add that formatter to the printing job.
 */
- (void)setupPrintFormatters {
    NSInteger page = 0;
    CGFloat previousFormatterMaxY = CGRectGetMinY(self.contentArea);
    
    for (Recipe *recipe in recipes) {
        NSString *html = recipe.htmlRepresentation;
        
        UIMarkupTextPrintFormatter *formatter = [[UIMarkupTextPrintFormatter alloc] initWithMarkupText:html];
        [formatterToRecipeMap setObject:recipe forKey:formatter];
        
        // Make room for the recipe info
        UIEdgeInsets contentInsets = UIEdgeInsetsZero;
        contentInsets.top = previousFormatterMaxY + self.recipeInfoHeight;
        if (contentInsets.top > CGRectGetMaxY(self.contentArea)) {
            // Move to the next page
            page++;
            contentInsets.top = CGRectGetMinY(self.contentArea) + self.recipeInfoHeight;
        }
        formatter.contentInsets = contentInsets;
        
        // Add the formatter to the renderer at the specified page
        [self addPrintFormatter:formatter startingAtPageAtIndex:page];
        
        page = formatter.startPage + formatter.pageCount - 1;
        previousFormatterMaxY = CGRectGetMaxY([formatter rectForPageAtIndex:page]);
        
    }
}

#pragma mark -

/*
 Custom UIPrintPageRenderer's may override this class to draw a custom print page header. 
 To illustrate that, this class sets the date in the header.
 */
- (void)drawHeaderForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)headerRect {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM d, yyyy 'at' h:mm a"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    [dateString drawInRect:headerRect withAttributes:nil];
    
}

/*
 Custom UIPrintPageRenderer's may also override this class to draw a custom print page footer. 
 To illustrate that, this class sets the current and total page number in the footer.
 */
- (void)drawFooterForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)footerRect {
    NSString *footer = [NSString stringWithFormat:@"Page %d of %d", pageIndex - pageRange.location + 1, pageRange.length];
    
    [footer drawInRect:footerRect withAttributes:nil];
}

/*
 to intermix custom drawing with the drawing performed by an associated print formatter, this method is called for each 
 print formatter associated with a given page.
 
 We do this to intermix/overlay our custom drawing onto the recipe presentation.
 We draw the upper portion of the recipe presentation by hand (image, title, desc), 
    and the bottom portion is drawn via the UIMarkupTextPrintFormatter.
 */
- (void)drawPrintFormatter:(UIPrintFormatter *)printFormatter forPageAtIndex:(NSInteger)pageIndex {
    [super drawPrintFormatter:printFormatter forPageAtIndex:pageIndex];
    
    /*
     To keep our custom drawing in sync with the printFormatter, base our drawing
     on the formatters rect.
     */
    CGRect rect = [printFormatter rectForPageAtIndex:pageIndex];
    
    /*
     Use a bezier path to draw the borders.
     We may potentially choose not to draw either the top or bottom line
     of the border depending on whether our recipe extended from the previous
     page, or carries onto the subsequent page.
     */
    UIBezierPath *border = [UIBezierPath bezierPath];
    if (pageIndex == printFormatter.startPage) {
        
        // For border drawing, get the rect that includes the formatter area plus the header area.
        // Move the formatter's rect up the size of the custom drawn recipe presentation
        //  and essentially grow the rect's height by this amount.
        rect.origin.y -= self.recipeInfoHeight;
        rect.size.height += self.recipeInfoHeight;
        
        [border moveToPoint:rect.origin];
        [border addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))];
        
        Recipe *recipe = [formatterToRecipeMap objectForKey:printFormatter];
        
        // Run custom code to draw upper portion of the recipe presentation (image, title, desc)
        [self drawRecipe:recipe inRect:rect];
    }
    
    // Draw the left border
    [border moveToPoint:rect.origin];
    [border addLineToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))];
    
    // Draw the right border
    [border moveToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))];
    [border addLineToPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
    
    if (pageIndex == printFormatter.startPage + printFormatter.pageCount - 1) {
        [border addLineToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))];
    }
    
    /*
     Set the UIColor to be used by the current graphics context, and then stroke 
     stroke the current path that is defined by the border bezier path.
     */
    [[UIColor blackColor] set];
    [border stroke];
}

/*
 Custom code to draw upper portion of the recipe presentation (image, title, desc).
 The argument rect is the full size of the recipe presentation.
 */
- (void)drawRecipe:(Recipe *)recipe inRect:(CGRect)rect {
    [self drawRecipeImage:recipe.image inRect:rect];
    [self drawRecipeName:recipe.name inRect:rect];
    [self drawRecipeInfo:recipe.aggregatedInfo inRect:rect];
}

- (void)drawRecipeImage:(UIImage *)image inRect:(CGRect)rect {
    
    // Create a new rect based on the size of the header area
    CGRect imageRect = CGRectZero;
    
    // Scale the image to fit in the infoRect
    CGFloat maxImageDimension = self.recipeInfoHeight - PADDING*2;
    CGFloat largestImageDimension = MAX(image.size.width, image.size.height);
    CGFloat scale = maxImageDimension / largestImageDimension;    
    imageRect.size.width = image.size.width * scale;
    imageRect.size.height = image.size.height * scale;
    
    // Place the image rect at the x,y defined by the argument rect
    imageRect.origin = CGPointMake(CGRectGetMinX(rect) + PADDING, CGRectGetMinY(rect) + PADDING);

    // Ask the image to draw in the image rect
    [image drawInRect:imageRect];
}

// Custom drawing code to put the recipe name in the title section of the recipe presentation's header
- (void)drawRecipeName:(NSString *)name inRect:(CGRect)rect {
    CGRect nameRect = CGRectZero;
    nameRect.origin.x = CGRectGetMinX(rect) + self.recipeInfoHeight;
    nameRect.origin.y = CGRectGetMinY(rect) + PADDING;
    nameRect.size.width = CGRectGetWidth(rect) - self.recipeInfoHeight;
    nameRect.size.height = self.recipeInfoHeight;
    
    [name drawInRect:nameRect withAttributes:nil];
}

// Custom drawing code to put the recipe recipe description, and prep time 
// in the title section of the recipe presentation's header
- (void)drawRecipeInfo:(NSString *)info inRect:(CGRect)rect {
    CGRect infoRect = CGRectZero;
    infoRect.origin.x = CGRectGetMinX(rect) + self.recipeInfoHeight;
    infoRect.origin.y = CGRectGetMinY(rect) + TITLE_SIZE*2;
    infoRect.size.width = CGRectGetWidth(rect) - self.recipeInfoHeight;
    infoRect.size.height = self.recipeInfoHeight - TITLE_SIZE*2;
    
    [[UIColor darkGrayColor] set];
    [info drawInRect:infoRect withAttributes:nil];
}

@end

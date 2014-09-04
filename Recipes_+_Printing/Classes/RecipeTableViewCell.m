/*
     File: RecipeTableViewCell.m 
 Abstract: A UITableViewCell for displaying a Recipe in the RecipeListTableViewController 
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

#import "RecipeTableViewCell.h"

#define IMAGE_SIZE          42.0
#define EDITING_INSET       10.0
#define TEXT_LEFT_MARGIN    8.0
#define TEXT_RIGHT_MARGIN   5.0
#define PREP_TIME_WIDTH     80.0

@implementation RecipeTableViewCell
{
    UIImageView *imageView;
    UILabel *nameLabel;
    UILabel *descriptionLabel;
    UILabel *prepTimeLabel;
}

/*
 Since this sample is intended to focus more on printing versus UI demonstration, see the
 sample code titled TableViewSuite for more information on creating custom UITableViewCells.
 */
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier])) {
        imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:imageView];

        descriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [descriptionLabel setFont:[UIFont systemFontOfSize:12.0]];
        [descriptionLabel setTextColor:[UIColor darkGrayColor]];
        [descriptionLabel setHighlightedTextColor:[UIColor whiteColor]];
        [self.contentView addSubview:descriptionLabel];

        prepTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [prepTimeLabel setFont:[UIFont systemFontOfSize:12.0]];
        [prepTimeLabel setTextColor:[UIColor blackColor]];
        [prepTimeLabel setHighlightedTextColor:[UIColor whiteColor]];
        [self.contentView addSubview:prepTimeLabel];

        nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [nameLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
        [nameLabel setTextColor:[UIColor blackColor]];
        [nameLabel setHighlightedTextColor:[UIColor whiteColor]];
        [self.contentView addSubview:nameLabel];
	}

	return self;
}

- (CGRect)_imageViewFrame {
    if (self.editing) {
        return CGRectMake(EDITING_INSET, 0.0, IMAGE_SIZE, IMAGE_SIZE);
    } else {
        return CGRectMake(0.0, 0.0, IMAGE_SIZE, IMAGE_SIZE);
    }
}

- (CGRect)_nameLabelFrame {
    if (self.editing) {
        return CGRectMake(IMAGE_SIZE + EDITING_INSET + TEXT_LEFT_MARGIN, 4.0, self.contentView.bounds.size.width - IMAGE_SIZE - EDITING_INSET - TEXT_LEFT_MARGIN, 16.0);
    } else {
        return CGRectMake(IMAGE_SIZE + TEXT_LEFT_MARGIN, 4.0, self.contentView.bounds.size.width - IMAGE_SIZE - TEXT_LEFT_MARGIN - PREP_TIME_WIDTH, 16.0);
    }
}

- (CGRect)_descriptionLabelFrame {
    if (self.editing) {
        return CGRectMake(IMAGE_SIZE + EDITING_INSET + TEXT_LEFT_MARGIN, 22.0, self.contentView.bounds.size.width - IMAGE_SIZE - EDITING_INSET - TEXT_LEFT_MARGIN, 16.0);
    } else {
        return CGRectMake(IMAGE_SIZE + TEXT_LEFT_MARGIN, 22.0, self.contentView.bounds.size.width - IMAGE_SIZE - TEXT_LEFT_MARGIN, 16.0);
    }
}

- (CGRect)_prepTimeLabelFrame {
    CGRect contentViewBounds = self.contentView.bounds;
    return CGRectMake(contentViewBounds.size.width - PREP_TIME_WIDTH - TEXT_RIGHT_MARGIN, 4.0, PREP_TIME_WIDTH, 16.0);
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [imageView setFrame:[self _imageViewFrame]];
    [nameLabel setFrame:[self _nameLabelFrame]];
    [descriptionLabel setFrame:[self _descriptionLabelFrame]];
    [prepTimeLabel setFrame:[self _prepTimeLabelFrame]];
    if (self.editing) {
        prepTimeLabel.alpha = 0.0;
    } else {
        prepTimeLabel.alpha = 1.0;
    }
}

- (void)setRecipe:(Recipe *)newRecipe {
    if (newRecipe != _recipe) {
        _recipe = newRecipe;
        
        imageView.image = _recipe.thumbnailImage;
        nameLabel.text = _recipe.name;
        descriptionLabel.text = _recipe.description;
        prepTimeLabel.text = _recipe.prepTime;
    }
}



@end

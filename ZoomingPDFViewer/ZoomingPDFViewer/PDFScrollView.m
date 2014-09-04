/*
     File: PDFScrollView.m
 Abstract: UIScrollView subclass that handles the user input to zoom the PDF page.  This class handles swapping the TiledPDFViews when the zoom level changes.
  Version: 3.1
 
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

#import "PDFScrollView.h"
#import "TiledPDFView.h"
#import <QuartzCore/QuartzCore.h>


@implementation PDFScrollView
{
    CGPDFPageRef _PDFPage;
}


@synthesize backgroundImageView=_backgroundImageView, tiledPDFView=_tiledPDFView, oldTiledPDFView=_oldTiledPDFView;


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame {
    if( self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

-(void)initialize {
    NSLog(@"%s",__PRETTY_FUNCTION__);
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    self.delegate = self;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = 5;    
    self.minimumZoomScale = .25;
    self.maximumZoomScale = 5;
}


- (void)setPDFPage:(CGPDFPageRef)PDFPage;
{
    if( PDFPage != NULL ) CGPDFPageRetain(PDFPage);
    if( _PDFPage != NULL ) CGPDFPageRelease(_PDFPage);
    _PDFPage = PDFPage;
    
    // PDFPage is null if we're requested to draw a padded blank page by the parent UIPageViewController
    if( PDFPage == NULL ) {
        self.pageRect = self.bounds;
    } else {
        self.pageRect = CGPDFPageGetBoxRect( _PDFPage, kCGPDFMediaBox );
        _PDFScale = self.frame.size.width/self.pageRect.size.width;
        self.pageRect = CGRectMake( self.pageRect.origin.x, self.pageRect.origin.y, self.pageRect.size.width*_PDFScale, self.pageRect.size.height*_PDFScale );
    }
    // Create the TiledPDFView based on the size of the PDF page and scale it to fit the view.
    [self replaceTiledPDFViewWithFrame:self.pageRect];
}


- (void)dealloc
{
    // Clean up.
    if( _PDFPage != NULL ) CGPDFPageRelease(_PDFPage);
}


#pragma mark -
#pragma mark Override layoutSubviews to center content

// Use layoutSubviews to center the PDF page in the view.

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    //NSLog(@"%s bounds: %@",__PRETTY_FUNCTION__,NSStringFromCGRect(self.bounds));
    
    // Center the image as it becomes smaller than the size of the screen.
    
    CGSize boundsSize = self.bounds.size;
        
    CGRect frameToCenter = self.tiledPDFView.frame;
    
    // Center horizontally.
    
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // Center vertically.
    
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    self.tiledPDFView.frame = frameToCenter;
    self.backgroundImageView.frame = frameToCenter;
    
    /*
     To handle the interaction between CATiledLayer and high resolution screens, set the tiling view's contentScaleFactor to 1.0.
     If this step were omitted, the content scale factor would be 2.0 on high resolution screens, which would cause the CATiledLayer to ask for tiles of the wrong scale.
     */
    self.tiledPDFView.contentScaleFactor = 1.0;
}



#pragma mark -
#pragma mark UIScrollView delegate methods

/*
 A UIScrollView delegate callback, called when the user starts zooming.
 Return the current TiledPDFView.
 */
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.tiledPDFView;
}

/*
 A UIScrollView delegate callback, called when the user begins zooming.
 When the user begins zooming, remove the old TiledPDFView and set the current TiledPDFView to be the old view so we can create a new TiledPDFView when the zooming ends.
 */
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    NSLog(@"%s scrollView.zoomScale=%f",__PRETTY_FUNCTION__,self.zoomScale);
    // Remove back tiled view.
    [self.oldTiledPDFView removeFromSuperview];
    
    // Set the current TiledPDFView to be the old view.
    self.oldTiledPDFView = self.tiledPDFView;
    //[self addSubview:self.oldTiledPDFView];
}


/*
 A UIScrollView delegate callback, called when the user stops zooming.
 When the user stops zooming, create a new TiledPDFView based on the new zoom level and draw it on top of the old TiledPDFView.
 */
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    
    NSLog(@"BEFORE  %s scale=%f, _PDFScale=%f",__PRETTY_FUNCTION__,scale,_PDFScale);
    // Set the new scale factor for the TiledPDFView.
    _PDFScale *= scale;
    NSLog(@"AFTER  %s scale=%f, _PDFScale=%f newFrame=%@",__PRETTY_FUNCTION__,scale,_PDFScale,NSStringFromCGRect(self.oldTiledPDFView.frame));

    // Create a new tiled PDF View at the new scale
    [self replaceTiledPDFViewWithFrame:self.oldTiledPDFView.frame];
}

-(void)replaceTiledPDFViewWithFrame:(CGRect)frame {
    // Create a new tiled PDF View at the new scale
    TiledPDFView *tiledPDFView = [[TiledPDFView alloc] initWithFrame:frame scale:_PDFScale];
    [tiledPDFView setPage:_PDFPage];
    // Add the new TiledPDFView to the PDFScrollView.
    [self addSubview:tiledPDFView];
    self.tiledPDFView = tiledPDFView;
}

@end

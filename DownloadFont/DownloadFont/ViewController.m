/*
     File: ViewController.m
 Abstract: Demonstrates how to download fonts on demand.
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

#import "ViewController.h"
#import <CoreText/CoreText.h>

@interface ViewController ()

@property (strong, nonatomic) NSString *errorMessage;

@end

@implementation ViewController

- (void)asynchronouslySetFontName:(NSString *)fontName
{
	UIFont* aFont = [UIFont fontWithName:fontName size:12.];
    // If the font is already downloaded
	if (aFont && ([aFont.fontName compare:fontName] == NSOrderedSame || [aFont.familyName compare:fontName] == NSOrderedSame)) {
        // Go ahead and display the sample text.
		NSUInteger sampleIndex = [_fontNames indexOfObject:fontName];
		_fTextView.text = [_fontSamples objectAtIndex:sampleIndex];
		_fTextView.font = [UIFont fontWithName:fontName size:24.];
		return;
	}
	
    // Create a dictionary with the font's PostScript name.
	NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:fontName, kCTFontNameAttribute, nil];
    
    // Create a new font descriptor reference from the attributes dictionary.
	CTFontDescriptorRef desc = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)attrs);
    
    NSMutableArray *descs = [NSMutableArray arrayWithCapacity:0];
    [descs addObject:(__bridge id)desc];
    CFRelease(desc);
    
	__block BOOL errorDuringDownload = NO;
	
	// Start processing the font descriptor..
    // This function returns immediately, but can potentially take long time to process.
    // The progress is notified via the callback block of CTFontDescriptorProgressHandler type.
    // See CTFontDescriptor.h for the list of progress states and keys for progressParameter dictionary.
    CTFontDescriptorMatchFontDescriptorsWithProgressHandler( (__bridge CFArrayRef)descs, NULL,  ^(CTFontDescriptorMatchingState state, CFDictionaryRef progressParameter) {
        
		//NSLog( @"state %d - %@", state, progressParameter);
		
		double progressValue = [[(__bridge NSDictionary *)progressParameter objectForKey:(id)kCTFontDescriptorMatchingPercentage] doubleValue];
		
		if (state == kCTFontDescriptorMatchingDidBegin) {
			dispatch_async( dispatch_get_main_queue(), ^ {
                // Show an activity indicator
				[_fActivityIndicatorView startAnimating];
				_fActivityIndicatorView.hidden = NO;
                
                // Show something in the text view to indicate that we are downloading
                _fTextView.text= [NSString stringWithFormat:@"Downloading %@", fontName];
				_fTextView.font = [UIFont systemFontOfSize:14.];
				
				NSLog(@"Begin Matching");
			});
		} else if (state == kCTFontDescriptorMatchingDidFinish) {
			dispatch_async( dispatch_get_main_queue(), ^ {
                // Remove the activity indicator
				[_fActivityIndicatorView stopAnimating];
				_fActivityIndicatorView.hidden = YES;
                
                // Display the sample text for the newly downloaded font
				NSUInteger sampleIndex = [_fontNames indexOfObject:fontName];
				_fTextView.text = [_fontSamples objectAtIndex:sampleIndex];
				_fTextView.font = [UIFont fontWithName:fontName size:24.];
				
                // Log the font URL in the console
				CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName, 0., NULL);
                CFStringRef fontURL = CTFontCopyAttribute(fontRef, kCTFontURLAttribute);
				NSLog(@"%@", (__bridge NSURL*)(fontURL));
                CFRelease(fontURL);
				CFRelease(fontRef);
                
				if (!errorDuringDownload) {
					NSLog(@"%@ downloaded", fontName);
				}
			});
		} else if (state == kCTFontDescriptorMatchingWillBeginDownloading) {
			dispatch_async( dispatch_get_main_queue(), ^ {
                // Show a progress bar
				_fProgressView.progress = 0.0;
				_fProgressView.hidden = NO;
				NSLog(@"Begin Downloading");
			});
		} else if (state == kCTFontDescriptorMatchingDidFinishDownloading) {
			dispatch_async( dispatch_get_main_queue(), ^ {
                // Remove the progress bar
				_fProgressView.hidden = YES;
				NSLog(@"Finish downloading");
			});
		} else if (state == kCTFontDescriptorMatchingDownloading) {
			dispatch_async( dispatch_get_main_queue(), ^ {
                // Use the progress bar to indicate the progress of the downloading
				[_fProgressView setProgress:progressValue / 100.0 animated:YES];
				NSLog(@"Downloading %.0f%% complete", progressValue);
			});
		} else if (state == kCTFontDescriptorMatchingDidFailWithError) {
            // An error has occurred.
            // Get the error message
            NSError *error = [(__bridge NSDictionary *)progressParameter objectForKey:(id)kCTFontDescriptorMatchingError];
            if (error != nil) {
                _errorMessage = [error description];
            } else {
                _errorMessage = @"ERROR MESSAGE IS NOT AVAILABLE!";
            }
            // Set our flag
            errorDuringDownload = YES;
            
            dispatch_async( dispatch_get_main_queue(), ^ {
                _fProgressView.hidden = YES;
				NSLog(@"Download error: %@", _errorMessage);
			});
		}
        
		return (bool)YES;
	});
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_fontNames count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{	
	static NSString *MyIdentifier = @"MyIdentifier";
	
	// Try to retrieve from the table view a now-unused cell with the given identifier.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	
	// If no cell is available, create a new one using the given identifier.
	if (cell == nil) {
		// Use the default cell style.
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
	}
	
	// Set up the cell.
	cell.textLabel.text = _fontNames[indexPath.row];
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self asynchronouslySetFontName:_fontNames[indexPath.row]];
    
    // Dismiss the keyboard in the text view if it is currently displayed
    if ([self.fTextView isFirstResponder])
        [self.fTextView resignFirstResponder];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.fontNames = [[NSArray alloc] initWithObjects:
						@"STXingkai-SC-Light",
						@"DFWaWaSC-W5",
						@"FZLTXHK--GBK1-0",
						@"STLibian-SC-Regular",
						@"LiHeiPro",
					    @"HiraginoSansGB-W3",
						nil];
	self.fontSamples = [[NSArray alloc] initWithObjects:
						@"汉体书写信息技术标准相",
						@"容档案下载使用界面简单",
						@"支援服务升级资讯专业制",
						@"作创意空间快速无线上网",
						@"兙兛兞兝兡兣嗧瓩糎",
						@"㈠㈡㈢㈣㈤㈥㈦㈧㈨㈩",
						nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

	
@end

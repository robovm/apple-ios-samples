/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This UIButton subclass programatically draws a transport button with a particular drawing style.
         It features a fill color that can be an accent color.
         If the button has the recordEnabledButtonStyle, it pulses on and off.
  
         These buttons resize themselves dynamically at runtime so that their bounds is a minimum of 44 x 44 pts
         in order to make them easy to press.
         The button image will draw at the original size specified in the storyboard
 */

@import UIKit;

typedef enum {
	rewindButtonStyle = 1,
	pauseButtonStyle,
	playButtonStyle,
	recordButtonStyle,
	recordEnabledButtonStyle,
    stopButtonStyle
} CAUITransportButtonStyle;

@interface CAUITransportButton : UIButton {
	CAUITransportButtonStyle drawingStyle;
	CGColorRef fillColor;
	
	CGRect imageRect;
};

@property CAUITransportButtonStyle drawingStyle;
@property CGColorRef fillColor;

@end

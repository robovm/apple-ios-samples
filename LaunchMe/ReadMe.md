# LaunchMe


## DESCRIPTION:
+ The LaunchMe sample application demonstrates how to implement a custom URL scheme to allow other applications to interact with your application.  It registers the "launchme" URL scheme, of which URLs contain an HTML color code (for example, #FF0000 or #F00).  The sample shows how to handle an incoming URL request by overriding -application:openURL:sourceApplication:annotation: to properly parse and extract information from the requested URL before updating the user interface.

+ Refer to the "Implementing Custom URL Schemes" section of the "iOS App Programming Guide" for information about registering a custom URL scheme, including an overview of the necessary info.plist keys.
<https://developer.apple.com/library/ios/redirect/DTS/CustomURLSchemes>


## BUILD REQUIREMENTS:
+ iOS 8.0 SDK or later


## RUNTIME REQUIREMENTS:
+ iOS 7.0 or later


Copyright (C) 2008-2015 Apple Inc. All rights reserved.
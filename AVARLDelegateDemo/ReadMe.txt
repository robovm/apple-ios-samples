### AVARLDelegateDemo ###

===========================================================================
DESCRIPTION:

The sample code depicts three different use cases of AVAssetResourceLoaderDelegate (for Identity encryption use case scenarios) for HLS (HTTP Live streaming):
		- Redirect handler (redirection for the HTTP live streaming media files)
		- Fetching Encryption keys for the HTTP live streaming media (segments)
		- Custom play list generation (index file) for the HTTP live streaming.

===========================================================================
BUILD REQUIREMENTS:

Xcode 5.0 or later, iOS 7.0 or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later

===========================================================================
PACKAGING LIST:

APLCustomAVARLDelegateDemo (.h/.m)
This class defines the custom resource delegate handlers. It implements the AVAssetResourceLoaderDelegate protocol and shows how to handle
different custom URLs.

APLPlayerView (.h/.m)
This is the UIView based viewer class for the player.

APLViewController (.h/.m)
The View controller class, defines the UI controls (buttons etc.) associated with the view.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- First version.

===========================================================================
Copyright (C) 2013-14 Apple Inc. All rights reserved.

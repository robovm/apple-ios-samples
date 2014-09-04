iAdInterstitialSuite
==========

iAdInterstitialSuite demonstrates how to use ADInterstitialAd in two common scenarios: magazine-style applications and games.

"ADMagazine" is a simple paged application that will insert an ADInterstitialAd as a page when one becomes available using -presentInView: with a container view for the page. It listens for the -interstitialAdDidLoad: delegate callback to know when an interstitial has been loaded and inserts it as the next page in the sequence. If the user dismisses the ad, then it will remove the interstitial and adjust its layout, request a new interstitial, and wait for that request to be filled. To remain simple, ADMagazine does not attempt to rate limit or place interstitial ads on specific pages, whereas a real magazine-style application would want to take more care in the placement of interstitials.

"ADGame" is a simple game that displays an ADInterstitialAd when the game is complete, if one is available, using presentFromViewController:. ADGame will create an interstitial as early as possible to attempt to ensure that an interstitial is available when the game completes, but if one is not available it will continue on to a new game.

Build Requirements
Latest iOS SDK

Runtime Requirements
iOS 4.3 SDK or later.

Changes from Previous Versions
1.0 - First release
1.1 - Revisions for API updates and bug fixes.
1.2 - Fixed layout issues when rotating the device while the ad unit was displayed.

Copyright (C) 2010-2011 Apple Inc. All rights reserved.

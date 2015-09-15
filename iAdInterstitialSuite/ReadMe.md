# iAdInterstitialSuite

## iAdInterstitialSuite demonstrates how to use ADInterstitialAd in two common scenarios: magazine-style applications and games.

### "ADMagazine" is a simple paged application that will display an ADInterstitialAd on top of a given page when one becomes available. It shows how to implement two different strategies of “ADInterstitialPresentationPolicy”, one using requestInterstitialAdPresentation API, the other automatic.

### "ADGame" is a simple game that displays an ADInterstitialAd when the game is complete, if one is available, using presentFromViewController:. ADGame will create an interstitial as early as possible to attempt to ensure that an interstitial is available when the game completes, but if one is not available it will continue on to a new game.

## Build Requirements
+ iOS 8.0 iOS SDK or later

## Runtime Requirements
+ iOS 8.0 or later

Copyright (C) 2010-2015 Apple Inc. All rights reserved.


### AVPlayerDemo ###

===========================================================================
DESCRIPTION:

Uses AVPlayer to play videos from the iPod Library, Camera Roll, or via iTunes File Sharing. Also displays metadata information for the video.

===========================================================================
BUILD REQUIREMENTS:

iOS 7.0 SDK or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later

===========================================================================
USING THE SAMPLE:

The sample will list all videos in the iPod Library, Camera Roll or those available via iTunes File Sharing. Navigate to each of these different lists with the tab bar icons. Select a video from any of these lists and a playback window will be brought up complete with a movie controller. Touch the play control and the video will begin playing. Tap the info. icon to view metadata for the video.

===========================================================================
NOTES:

As discussed in "Enhancements for HTTP Live Streaming" in the AV Foundation Release Notes for iOS 4.3, the inspection features of AVURLAsset have been enhanced to handle HTTP Live Streaming Media resources. For this reason, starting with iOS 4.3 you can prepare any asset for playback in a uniform way, according to the best practices originally outlined for file-based assets in the AV Foundation Programming Guide. Those steps are as follows:
1. Create an asset using AVURLAsset and load its tracks using loadValuesAsynchronouslyForKeys:completionHandler:.
2. When the asset has loaded its tracks, create an instance of AVPlayerItem using the asset. 

3. Associate the item with an instance of AVPlayer. 

4. Wait until the item’s status indicates that it’s ready to play.
Typically you use key-value observing to receive a notification when the status changes.


Duration of Timed Media Resources for Playback
Because of the dynamic nature of HTTP Live Streaming Media the best practice for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3. Prior to iOS 4.3, you would obtain the duration of a player item by fetching the value of the duration property of its associated AVAsset object. However, note that for HTTP Live Streaming Media the duration of a player item during any particular playback session may differ from the duration of its asset. For this reason a new key-value observable duration property has been defined on AVPlayerItem.
To make your code compatible with all available revisions of AV Foundation, you can check whether the duration property of an AVPlayerItem instance is available and obtain the duration for playback as follows:

CMTime itemDuration = kCMTimeInvalid;// Once the AVPlayerItem becomes ready to play, i.e. [playerItem status] == AVPlayerItemStatusReadyToPlay),// its duration can be fetched from the item as follows.

if ([AVPlayerItem instancesRespondToSelector:@selector (duration)]) 
{// Fetch the duration directly from the AVPlayerItem.itemDuration = [playerItem duration];}else 
{// Reach through the AVPlayerItem to its asset to get the duration.itemDuration = [[playerItem asset] duration];}

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.2 - Fixed problem where the metadata screen would not dismiss properly. Fixed deprecated call warnings. Other miscellaneous changes.

1.1 - Update for iOS 4.3 to show how to prepare any asset for playback in a uniform way, plus new technique for obtaining duration of a AVPlayerItem.

1.0 - First Release

===========================================================================
Copyright (C) 2010-2014 Apple Inc. All rights reserved.
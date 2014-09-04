
### StitchedStreamPlayer ###

===========================================================================
DESCRIPTION:

A simple AVFoundation demonstration of how timed metadata can be used to identify different content in a stream, supporting a custom seek UI.

This sample expects the content to contain plists encoded as timed metadata. AVPlayer turns these into NSDictionaries.

In this example, the metadata payload is either a list of ads ("ad-list") or an ad record ("url"). Each ad in the list of ads is specified by a start-time and end-time pair of values. Each ad record is specified by a URL which points to the ad video to play.

The ID3 key
AVMetadataID3MetadataKeyGeneralEncapsulatedObject is used to identify the metadata in the stream.

===========================================================================
DETAILS:

You can add various kinds of metadata to media stream segments. For example, you can add the album art, artist’s name, and song title to an audio stream. As another example, you could add the current batter’s name and statistics to video of a baseball game.
If an audio-only stream includes an image as metadata, the Apple client software automatically displays it. Currently, the only metadata that is automatically displayed by the Apple-supplied client software is a still image accompanying an audio-only stream.
If you are writing your own client software, however, using either MPMoviePlayerController or AVPlayerItem, you can access streamed metadata using the timedMetaData property.
You can add timed metadata by specifying a metadata file in the -F command line option to either the HTTP Live Streaming stream segmenter or the file segmenter tool (download the current version of the HTTP Live Streaming Tools from the Apple Developer website. You can access them if you are a member of the iPhone Developer Program. One way to navigate to the tools is to log onto connect.apple.com, then click iPhone under the Downloads heading. The Timed Metadata for HTTP Live Streaming specification is available on the website as well). 

The specified metadata source can be a file in ID3 format or an image file (JPEG or PNG). Metadata specified this way is automatically inserted into every media segment.
This is called timed metadata because it is inserted into a media stream at a given time offset. Timed metadata can optionally be inserted into all segments after a given time.
To add timed metadata to a live stream, use the id3taggenerator tool, with its output set to the stream segmenter (the id3taggenerator tool can be downloaded along with the HTTP Live Streaming tools from the Apple Developer website as described above). The tool generates ID3 metadata and passes it the stream segmenter for inclusion in the outbound stream.The tag generator can be run from a shell script, for example, to insert metadata at the desired time, or at desired intervals. New timed metadata automatically replaces any existing metadata.
Once metadata has been inserted into a media segment, it is persistent. If a live broadcast is re-purposed as video on demand, for example, it retains any metadata inserted during the original broadcast.
Adding timed metadata to a stream created using the file segmenter is slightly more complicated.
1.	First, generate the metadata samples. You can generate ID3 metadata using the id3taggenerator command-line tool, with the output set to file.
2.	Next, create a metadata macro file—a text file in which each line contains the time to insert the metadata, the type of metadata, and the path and filename of a metadata file.
For example, the following metadata macro file would insert a picture at 1.2 seconds into the stream, then an ID3 tag at 10 seconds:
1.2 picture /meta/images/picture.jpg10 id3 /meta/id3/title.id3
3.	Finally, specify the metadata macro file by name when you invoke the media file segmenter, using the -M command line option.
For additional details, see the man pages for mediastreamsegmenter, mediafilesegmenter, and id3taggenerator.

===========================================================================
BUILD REQUIREMENTS:

iOS 4.3 SDK or later

===========================================================================
RUNTIME REQUIREMENTS:

iPhone OS 4.3 or later

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.3 - Update for iOS 4.3

===========================================================================
Copyright (C) 2008-2011 Apple Inc. All rights reserved.
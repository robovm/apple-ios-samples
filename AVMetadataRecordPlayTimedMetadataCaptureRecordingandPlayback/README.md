# AVMetadataRecordPlay: Record And Play QuickTime Movies With Timed Medata Using AVFoundation

### Description

AVMetadataRecordPlay demonstrates using AV Foundation capture APIs to
record and play movies with timed metadata content. In addition to audio
and video tracks, AVMetadataRecordPlay records detected faces, video
orientation, and GPS as timed metadata tracks. When playing back
content, AVMetadataRecordPlay renders bounding boxes around detected
faces, and superimposes the current GPS coordinates over a region of the
AVPlayerLayer. It also reads the video orientation metadata and
dynamically adjusts the video layer's orientation to properly render the
content. This sample only runs on an actual device (iPad or iPhone), and
cannot be run in the simulator.

### Recording Timed Metadata

AVMetadataRecordPlay demonstrates a new-for-iOS-9 way of recording timed
metadata to a QuickTime movie file using AVCaptureMovieFileOutput, which
for many common scenarios improves upon the method shown in Session 505
of WWDC 2014 entitled "Harnessing Metadata in Audiovisual Media".

Session 505 demonstrates the use of AVAssetWriter to add timed metadata
content while also recording audio and video. AVAssetWriter is perfect
for situations where clients want to access audio and video samples
before writing them to a file. AVCaptureMovieFileOutput is used in
situations where clients don't need per-sample access, but instead just
want the AVCaptureSession to record media from inputs into the movie.
Here are some advantages of using AVCaptureMovieFileOutput:

1. AVCaptureMovieFileOutput requires less set-up code.

2. AVCaptureMovieFileOutput does not require client-oriented processing;
it handles issues like compression and file writing for the client.

3. Because the client application does not need to  interact with the
real-time media, there is less processing overhead involved in getting
the media written to the QuickTime movie.

New for iOS 9 is the ability for clients to write timed metadata samples
to QuickTime movies using an AVCaptureMovieFileOutput. This new method
should be investigated by clients who satisfy the following conditions:

1. They do not need access to the audio and video samples before they
are written to the file.

2. They want to record framework supplied metadata (currently detected face
information and device orientation).

3. They want to record metadata that they create and that does not rely
on the audio or video samples, such as location (GPS) data.

Typically AVCaptureSession will intelligently make AVCaptureConnections
between its inputs and outputs. In case of AVCaptureMovieFileOutput each
connection corresponds to a track in the movie. Because writing timed
metadata increases file size and CPU usage, and metadata availability
may differ from device to device, an AVCaptureSession does not
automatically make connections to an AVCaptureMovieFileOutput for
metadata; clients must opt-in for the specific metadata that they wish
to capture.

As mentioned earlier, there are currently two kinds of framework supplied timed
metadata that are available for capture: detected face information and
video orientation. The opt-in mechanism for each kind is different.

#### Capturing Detected Face Timed Metadata

Detected face information has been available to client applications
since iOS 6. AVMetadataFaceObjects are provided to clients by an
AVCaptureMetadataOutput. The source of the face objects is an
AVCaptureDeviceInput's input port that also delivers other types of
metadata objects, such as detected barcodes. AVCaptureMovieFileOutput
does not support the writing of disparately timed metadata to a common
track, therefore in iOS 9, AVCaptureInputs may expose a new type of port
that delivers just one kind of metadata. The mediaType of this input
port is AVMediaTypeMetadata. In order to determine what metadata is
available from this new type of port, a client uses the port's
formatDescription property. AVMetadataRecordPlay includes the following
method that demonstrates finding and connecting the proper input port:

``
        - (void)connectSpecificMetadataPort:(NSString *)metadataIdentifier
        {
            for ( AVCaptureInputPort *inputPort in self.videoDeviceInput.ports ) {
                CMFormatDescriptionRef desc = inputPort.formatDescription;
                if ( desc && ( kCMMediaType_Metadata == CMFormatDescriptionGetMediaType( desc ) ) ) {
                    CFArrayRef metadataIdentifiers = CMMetadataFormatDescriptionGetIdentifiers( desc );
                    if ( [(__bridge NSArray *)metadataIdentifiers containsObject:metadataIdentifier] )
                    {
                        AVCaptureConnection *connection = [AVCaptureConnection connectionWithInputPorts:@[inputPort] output:self.movieFileOutput];
                        [self.session addConnection:connection];
                    }
                }
            }
        }
``

Note that AVCaptureSession never automatically forms connections between
eligible outputs and input ports of type AVMediaTypeMetadata.
AVCaptureSession _does_ automatically form connections between eligible
outputs and input ports of type AVMediaTypeMetadataObject. To test the
eligibility of a particular manually created connection, be sure to call
`[session canAddConnection:proposedConnection]`. Beware that when removing
AVCaptureInputs (such as when changing cameras), all connections are
severed, and new manual connections must be formed.

#### Capturing Video Orientation Timed Metadata

Often users start recording a movie with their iOS device in one
orientation and then partway through, rotate the device to a new
orientation. This results in a movie that plays back sideways or upside
down from the point at which the user rotated the device. A video
orientation timed metadata track allows playback applications to
discover when these orientation changes occur and adjust the playback of
their video accordingly. To opt-in, the client must enable
setRecordsVideoOrientationAndMirroringChanges:
asMetadataTrackForConnection on the movieFileOutput object with the
connection they made, as shown in the following code fragment:

``
        [self.session addOutput:movieFileOutput];
        AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        ...
        [movieFileOutput setRecordsVideoOrientationAndMirroringChanges:YES asMetadataTrackForConnection:connection];
``

Once set, any time the client app changes the connection's
videoOrientation or videoMirrored properties during the recording of a
QuickTime movie, a representation of the properties are written to a
timed metadata track. The actual representation takes the form of an
EXIF orientation tag value. Beware that when removing AVCaptureInputs
(such as when changing cameras), the
`setRecordsVideoOrinetationAndMirroringChanges:
asMetadataTrackForConnection:` property must be set again for the new
camera connection.

#### Capturing Client Supplied Metadata

New for iOS 9 is the AVCaptureMetadataInput class, which provides a
timed metadata conduit between the client application and the
AVCaptureMovieFileOutput. This allows applications to record their own
timed metadata to a movie. One such example is location (GPS) data. To
make use of this new feature the client application needs to do three
things:

1. Create and add an AVCaptureMetadataInput. Required for creation is a
CMFormatDescription that describes the metadata to be provided, and a
CMClock that provides a timing reference. The CMClock is critical in
allowing the AVCaptureSession to synchronize the client's metadata
stream with the other media being captured. Here is how
AVMetadataRecordPlay creates its input for location data: 

``
        // Create a format description for the location metadata.
        NSArray *specs = @[@{ (__bridge id)kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier : AVMetadataIdentifierQuickTimeMetadataLocationISO6709,
                               (__bridge id)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType   : (__bridge id)kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709 }];
        CMFormatDescriptionRef locationMetadataDesc = NULL;
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault, kCMMetadataFormatType_Boxed, (__bridge CFArrayRef)specs, &locationMetadataDesc);
    
        // Create the metadata input for location metadata.
        AVCaptureMetadataInput *newLocationMetadataInput = [[AVCaptureMetadataInput alloc] initWithFormatDescription:locationMetadataDesc clock:CMClockGetHostTimeClock()];
        CFRelease( locationMetadataDesc );
    
        [self.session addInputWithNoConnections:newLocationMetadataInput];
``

2. Create and add a connection between the AVCaptureMetadataInput's sole
AVCaptureInputPort and the AVCaptureMovieFileOutput.
AVMetadataRecordPlay does the following:

``
        AVCaptureInputPort *inputPort = [newLocationMetadataInput.ports firstObject];
        [self.session addConnection:[AVCaptureConnection connectionWithInputPorts:@[inputPort] output:self.movieFileOutput]];
    
        [self setLocationMetadataInput:newLocationMetadataInput];
``

3. When the session is running, provide metadata in the form of
AVTimedMetadataGroups. An AVTimedMetadataGroup consists of an array of
AVMetadataItems and a timestamp (in the context of the CMClock provided
on creation). It is important that the AVMetadataItems strictly adhere
to the CMFormatDescription provided to the AVCaptureMetadataInput's init
method. The following steps are taken:

* One or more AVMetadataItems are created. To store GPS data,
AVMetadataRecordPlay does the following:

``
        AVMutableMetadataItem *newLocationMetadataItem = [[AVMutableMetadataItem alloc] init];
    
        newLocationMetadataItem.identifier = AVMetadataIdentifierQuickTimeMetadataLocationISO6709;
        newLocationMetadataItem.dataType = (__bridge NSString *)kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709;
        ...
        newLocationMetadataItem.value = iso6709Notation;
``

* An AVTimedMetadataGroup is created. Here is the code in
AVMetadataRecordPlay for this:

``
        AVTimedMetadataGroup *metadataItemGroup = [[AVTimedMetadataGroup alloc] initWithItems:@[newLocationMetadataItem] timeRange:CMTimeRangeMake( CMClockGetTime( CMClockGetHostTimeClock() ), kCMTimeInvalid )];
``

* The AVTimedMetadataGroup is provided to the AVCaptureMetadataInput
using its appendTimedMetadataGroup method. For example,
AVMetadataRecordPlay does:

``
        NSError *error = nil;
        if ( ! [self.locationMetadataInput appendTimedMetadataGroup:metadataItemGroup error:&error] ) {
            NSLog( @"appendTimedMetadataGroup failed with error %@", error );
        }
``

The AVCaptureSession serializes the AVMetadataItems and creates a sample
with the timing information provided by the AVTimedMetadataGroup. The
sample is written to the file, and its duration is determined by the
addition of a follow-on AVTimedMetadataGroup. If a client wishes to
express a period where there is no valid metadata available, they need
to simply supply an AVTimedMetadataGroup that has no items:

``
        AVTimedMetadataGroup *metadataItemGroupToDeclareNoMetadataIsAvailableStartingAtThisTime = [[AVTimedMetadataGroup alloc] initWithItems:@[] timeRange:CMTimeRangeMake( theTime ), kCMTimeInvalid )];
``

### Visualizing Timed Metadata During Playback

There are a few different ways to retrieve timed metadata from a
QuickTime movie, depending on what an application wants to do:

1. For offline processing of media (such as an export operation), an
AVAssetReader can be used. In this case, an
AVAssetReaderOutputMetadataAdaptor provides AVTimedMetadataGroups from
metadata tracks in the QuickTime movie. This technique is demonstrated
by the AVLocationPlayer sample code.

2. AVMetadataRecordPlay demonstrates how to visualize timed metadata
during realtime playback. The app implements a class conforming to the
AVPlayerItemMetadataOutputPushDelegate protocol, which creates an
AVMutableComposition, and plays the composition with an AVPlayerItem.
Detected face metadata is shown by drawing bounding boxes on the video
where faces were detected. Video orientation metadata is "visualized" as
the app updates the video track's display layer's transform property.
Location (GPS) metadata is shown as a string in a UI label.

#### Delegate For Receiving Timed Metadata

The sample's AAPLPlayerViewController conforms to
AVPlayerItemMetadataOutputPushDelegate by implementing the
`metadataOutput:didOutputTimedMetadataGroups:fromPlayerItemTrack:` method.
It also stores the AVPlayerItemMetadataOutput in a property:

``
        - (void)viewDidLoad
        {
            ...
            self.itemMetadataOutput = [[AVPlayerItemMetadataOutput alloc] initWithIdentifiers:nil];
            [self.itemMetadataOutput setDelegate:self queue:metadataQueue];
``

This AVPlayerItemMetadataOutput is added to the AVPlayerItem created for
the movie (the movie is selected by the user via the app's image picker).

When the image picker provides a QuickTime movie URL, the app creates an
AVMutableComposition that contains all the tracks to be played. For
AVMetadataRecordPlay this is a video track, an audio track, and all of
the metadata tracks. Check the method setupPlayerURL to see how a
mutable composition and AVPlayerItem are created for the provided URL.

Since the property for AVPlayerItemMetadataOutput is set up with player view
controller as the delegate, the AAPLPlayerViewController
`metadataOutput:didOutputTimedMetadataGroups:fromPlayerItemTrack:` method
gets called with AVTimedMetadataGroups as the movie is played. The
metadata tracks are honored for playback in the callback. The callback
receives NSArrays of AVTimedMetadataGroups. The AVTimedMetadataGroups
contain AVMetadataItems that represent the metadata for a given period
of time.

#### Detecting Periods Of No Metadata

If a particular AVTimedMetadataGroup has no items, it means that there
is no metadata to display for the group's time range. Rendering of “No
Metadata” is context dependent:

1. Detected face track: if there is no metadata, all bounding boxes are
removed from the display layer.

2. Video orientation metadata: if there is no metadata, the display
orientation is left alone. If the movie being played back was generated
by AVMetadataRecordPlay, then this will never actually occur;
AVMetadataRecordPlay ensures that there is always a video orientation
metadata sample that is valid.

3. GPS metadata: if there is no metadata, the label is set to an empty
string.

To see how this is accomplished, look for the following line in
AAPLPlayerViewController's
`metadataOutput:didOutputTimedMetadataGroups:fromPlayerItemTrack:` method:

``
        if ( group.items.count == 0 ) {
``

#### Visualizing Metadata

When the AVTimedMetadataGroup has AVMetadataItems, each item's
identifier and dataType properties specify the encapsulated metadata
values. A loop can be used to go through the items and apply some
effects whenever valid items are received from the metadata tracks. This
is shown in AAPLPlayerViewController's
`metadataOutput:didOutputTimedMetadataGroups:fromPlayerItemTrack:` method,
starting with the following line:

``
        for ( AVMetadataItem *item in group.items ) {
``

Note that the value property of a detected face AVMetadataItem is an
AVMetadataFaceObject.

The last thing to note is how video orientation metadata is visualized.
The contents of this track is an EXIF orientation tag value, which is a
signed 16 bit integer. The sample code has a utility method for
translating the EXIF orientation tag value into a CGTransform
(`_makeAffineTransform:fromVideoOrientation:forVideoDimensions:`). The
transform is then applied to the movie display layer.

## Requirements

### Build

iOS SDK 9.0

### Runtime

iOS 9.0 or later

## Changes from Previous Version

NA

Copyright (C) 2015 Apple Inc. All rights reserved.

/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  NSUserDefaults global keys for reading/writing user defaults
  
 */

#ifndef Breadcrumb_SettingsKeys_h
#define Breadcrumb_SettingsKeys_h

// value is a BOOL
NSString * const TrackLocationInBackgroundPrefsKey;

// value is a CLLocationAccuracy (double)
NSString * const LocationTrackingAccuracyPrefsKey;

// value is a BOOL
NSString * const PlaySoundOnLocationUpdatePrefsKey;

#endif

# ThreadedCoreData

## Description

This sample shows how to use Core Data in a multi-threaded environment.
Based on the SeismicXML sample, it downloads and parses an RSS feed from the United States Geological Survey (USGS) that provides data on recent earthquakes around the world.

What makes this sample different is that it persistently stores earthquakes using Core Data.
Each time you launch the app, it downloads new earthquake data, parses it in an NSOperation which checks for duplicates and stores newly founded earthquakes as managed objects.

This sample follows the first recommended pattern mentioned in the Core Data Programming Guide: Multi-Threading with Core Data; General Guidelines section - "Create a separate managed object context for each thread and share a single persistent store coordinator."

For those new to Core Data, it can be helpful to compare SeismicXML sample with this sample and notice the necessary ingredients to introduce Core Data in your application.

## Build Requirements

iOS SDK 9.0 or later


## Runtime Requirements

iOS 8.0 or later


Copyright (C) 2011-2016 Apple Inc. All rights reserved.
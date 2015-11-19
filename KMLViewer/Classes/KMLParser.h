/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Implements a limited KML parser.
      The following KML types are supported:
              Style,
              LineString,
              Point,
              Polygon,
              Placemark.
           All other types are ignored
*/

@import MapKit;

@class KMLPlacemark;
@class KMLStyle;

@interface KMLParser : NSObject <NSXMLParserDelegate> {
    NSMutableDictionary *_styles;
    NSMutableArray *_placemarks;
    
    KMLPlacemark *_placemark;
    KMLStyle *_style;
    
    NSXMLParser *_xmlParser;
}

- (instancetype)initWithURL:(NSURL *)url;
- (void)parseKML;

@property (unsafe_unretained, nonatomic, readonly) NSArray *overlays;
@property (unsafe_unretained, nonatomic, readonly) NSArray *points;

- (MKAnnotationView *)viewForAnnotation:(id <MKAnnotation>)point;
- (MKOverlayRenderer *)rendererForOverlay:(id <MKOverlay>)overlay;

@end

/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 KMLElement and subclasses declared here implement a class hierarchy for storing a KML document structure.  The actual KML file is parsed with a SAX parser and only the relevant document structure is retained in the object graph produced by the parser.  Data parsed is also transformed into appropriate UIKit and MapKit classes as necessary.
 
      Abstract KMLElement type.  Handles storing an element identifier (id="...") as well as a buffer for accumulating character data parsed from the xml. In general, subclasses should have beginElement and endElement classes for keeping track of parsing state.  The parser will call beginElement when an interesting element is encountered, then all character data found in the element will be stored into accum, and then when endElement is called accum will be parsed according to the conventions for that particular element type in order to save the data from the element.  Finally, clearString will be called to reset the character data accumulator.
 */

#import "KMLParser.h"

@interface KMLElement : NSObject {
    NSString *identifier;
    NSMutableString *accum;
}

- (instancetype)initWithIdentifier:(NSString *)ident;

@property (nonatomic, readonly) NSString *identifier;

// Returns YES if we're currently parsing an element that has character
// data contents that we are interested in saving.
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL canAddString;

// Add character data parsed from the xml
- (void)addString:(NSString *)str;

// Once the character data for an element has been parsed, use clearString to
// reset the character buffer to get ready to parse another element.
- (void)clearString;

@end

// Represents a KML <Style> element.  <Style> elements may either be specified
// at the top level of the KML document with identifiers or they may be
// specified anonymously within a Geometry element.
@interface KMLStyle : KMLElement {    
    UIColor *strokeColor;
    CGFloat strokeWidth;
    UIColor *fillColor;
    
    BOOL fill;
    BOOL stroke;
    
    struct { 
        int inLineStyle:1;
        int inPolyStyle:1;
        
        int inColor:1;
        int inWidth:1;
        int inFill:1;
        int inOutline:1;
    } flags;
}

- (void)beginLineStyle;
- (void)endLineStyle;

- (void)beginPolyStyle;
- (void)endPolyStyle;

- (void)beginColor;
- (void)endColor;

- (void)beginWidth;
- (void)endWidth;

- (void)beginFill;
- (void)endFill;

- (void)beginOutline;
- (void)endOutline;

- (void)applyToOverlayPathRenderer:(MKOverlayPathRenderer *)renderer;

@end

@interface KMLGeometry : KMLElement {
    struct {
        int inCoords:1;
    } flags;
}

- (void)beginCoordinates;
- (void)endCoordinates;

// Create (if necessary) and return the corresponding Map Kit MKShape object
// corresponding to this KML Geometry node.
@property (NS_NONATOMIC_IOSONLY, readonly, strong) MKShape *mapkitShape;

// Create (if necessary) and return the corresponding MKOverlayPathRenderer for
// the MKShape object.
- (MKOverlayPathRenderer *)createOverlayPathRenderer:(MKShape *)shape;

@end

// A KMLPoint element corresponds to an MKAnnotation and MKPinAnnotationView
@interface KMLPoint : KMLGeometry {
    CLLocationCoordinate2D point;
}

@property (nonatomic, readonly) CLLocationCoordinate2D point;

@end

// A KMLPolygon element corresponds to an MKPolygon and MKPolygonView
@interface KMLPolygon : KMLGeometry {
    NSString *outerRing;
    NSMutableArray *innerRings;
    
    struct {
        int inOuterBoundary:1;
        int inInnerBoundary:1;
        int inLinearRing:1;
    } polyFlags;
}

- (void)beginOuterBoundary;
- (void)endOuterBoundary;

- (void)beginInnerBoundary;
- (void)endInnerBoundary;

- (void)beginLinearRing;
- (void)endLinearRing;

@end

@interface KMLLineString : KMLGeometry {
    CLLocationCoordinate2D *points;
    NSUInteger length;
}

@property (nonatomic, readonly) CLLocationCoordinate2D *points;
@property (nonatomic, readonly) NSUInteger length;

@end

@interface KMLPlacemark : KMLElement {
    KMLStyle *style;
    KMLGeometry *geometry;
    
    NSString *name;
    NSString *placemarkDescription;
    
    NSString *styleUrl;
    
    MKShape *mkShape;
    
    MKAnnotationView *annotationView;
    MKOverlayPathRenderer *overlayPathRenderer;
    
    struct {
        int inName:1;
        int inDescription:1;
        int inStyle:1;
        int inGeometry:1;
        int inStyleUrl:1;
    } flags;
}

- (void)beginName;
- (void)endName;

- (void)beginDescription;
- (void)endDescription;

- (void)beginStyleWithIdentifier:(NSString *)ident;
- (void)endStyle;

- (void)beginGeometryOfType:(NSString *)type withIdentifier:(NSString *)ident;
- (void)endGeometry;

- (void)beginStyleUrl;
- (void)endStyleUrl;

// Corresponds to the title property on MKAnnotation
@property (nonatomic, readonly) NSString *name; 
// Corresponds to the subtitle property on MKAnnotation
@property (nonatomic, readonly) NSString *placemarkDescription;

@property (nonatomic, readonly) KMLGeometry *geometry;
@property (unsafe_unretained, nonatomic, readonly) KMLPolygon *polygon;

@property (nonatomic, strong) KMLStyle *style;
@property (nonatomic, readonly) NSString *styleUrl;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) id<MKOverlay> overlay;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) id<MKAnnotation> point;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) MKOverlayPathRenderer *overlayPathRenderer;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) MKAnnotationView *annotationView;

@end

// Convert a KML coordinate list string to a C array of CLLocationCoordinate2Ds.
// KML coordinate lists are longitude,latitude[,altitude] tuples specified by whitespace.
static void strToCoords(NSString *str, CLLocationCoordinate2D **coordsOut, NSUInteger *coordsLenOut) {
    NSUInteger read = 0, space = 10;
    CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * space);
    
    NSArray *tuples = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSString *tuple in tuples) {
        if (read == space) {
            space *= 2;
            coords = realloc(coords, sizeof(CLLocationCoordinate2D) * space);
        }
        
        double lat, lon;
        NSScanner *scanner = [[NSScanner alloc] initWithString:tuple];
        [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@","]];
        BOOL success = [scanner scanDouble:&lon];
        if (success) 
            success = [scanner scanDouble:&lat];
        if (success) {
            CLLocationCoordinate2D c = CLLocationCoordinate2DMake(lat, lon);
            if (CLLocationCoordinate2DIsValid(c))
                coords[read++] = c;
        }
    }
    
    *coordsOut = coords;
    *coordsLenOut = read;
}

@interface UIColor (KMLExtras)

// Parse a KML string based color into a UIColor.  KML colors are agbr hex encoded.
+ (UIColor *)colorWithKMLString:(NSString *)kmlColorString;

@end

@implementation KMLParser

// After parsing has completed, this method loops over all placemarks that have
// been parsed and looks up their corresponding KMLStyle objects according to
// the placemark's styleUrl property and the global KMLStyle object's identifier.
- (void)assignStyles {
    for (KMLPlacemark *placemark in _placemarks) {
        if (!placemark.style && placemark.styleUrl) {
            NSString *styleUrl = placemark.styleUrl;
            NSRange range = [styleUrl rangeOfString:@"#"];
            if (range.length == 1 && range.location == 0) {
                NSString *styleID = [styleUrl substringFromIndex:1];
                KMLStyle *style = _styles[styleID];
                placemark.style = style;
            }
        }
    }
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _styles = [[NSMutableDictionary alloc] init];
        _placemarks = [[NSMutableArray alloc] init];
        _xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
        
        [_xmlParser setDelegate:self];
    }
    return self;
}


- (void)parseKML {
    [_xmlParser parse];
    [self assignStyles];
}

// Return the list of KMLPlacemarks from the object graph that contain overlays
// (as opposed to simply point annotations).
- (NSArray *)overlays {
    NSMutableArray *overlays = [[NSMutableArray alloc] init];
    for (KMLPlacemark *placemark in _placemarks) {
        id <MKOverlay> overlay = [placemark overlay];
        if (overlay)
            [overlays addObject:overlay];
    }
    return overlays;
}

// Return the list of KMLPlacemarks from the object graph that are simply
// MKPointAnnotations and are not MKOverlays.
- (NSArray *)points {
    NSMutableArray *points = [[NSMutableArray alloc] init];
    for (KMLPlacemark *placemark in _placemarks) {
        id <MKAnnotation> point = [placemark point];
        if (point)
            [points addObject:point];
    }
    return points;
}

- (MKAnnotationView *)viewForAnnotation:(id <MKAnnotation>)point {
    // Find the KMLPlacemark object that owns this point and get
    // the view from it.
    for (KMLPlacemark *placemark in _placemarks) {
        if ([placemark point] == point)
            return [placemark annotationView];
    }
    return nil;
}

- (MKOverlayRenderer *)rendererForOverlay:(id <MKOverlay>)overlay {
    // Find the KMLPlacemark object that owns this overlay and get
    // the view from it.
    for (KMLPlacemark *placemark in _placemarks) {
        if ([placemark overlay] == overlay)
            return [placemark overlayPathRenderer];
    }
    return nil;
}

#pragma mark NSXMLParserDelegate

#define ELTYPE(typeName) (NSOrderedSame == [elementName caseInsensitiveCompare:@#typeName])

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
                                        namespaceURI:(NSString *)namespaceURI
                                       qualifiedName:(NSString *)qName
                                          attributes:(NSDictionary *)attributeDict {
    NSString *ident = attributeDict[@"id"];
    
    KMLStyle *style = [_placemark style] ? [_placemark style] : _style;
    
    // Style and sub-elements
    if (ELTYPE(Style)) {
        if (_placemark) {
            [_placemark beginStyleWithIdentifier:ident];
        } else if (ident != nil) {
            _style = [[KMLStyle alloc] initWithIdentifier:ident];
        }
    } else if (ELTYPE(PolyStyle)) {
        [style beginPolyStyle];
    } else if (ELTYPE(LineStyle)) {
        [style beginLineStyle];
    } else if (ELTYPE(color)) {
        [style beginColor];
    } else if (ELTYPE(width)) {
        [style beginWidth];
    } else if (ELTYPE(fill)) {
        [style beginFill];
    } else if (ELTYPE(outline)) {
        [style beginOutline];
    }
    // Placemark and sub-elements
    else if (ELTYPE(Placemark)) {
        _placemark = [[KMLPlacemark alloc] initWithIdentifier:ident];
    } else if (ELTYPE(Name)) {
        [_placemark beginName];
    } else if (ELTYPE(Description)) {
        [_placemark beginDescription];
    } else if (ELTYPE(styleUrl)) {
        [_placemark beginStyleUrl];
    } else if (ELTYPE(Polygon) || ELTYPE(Point) || ELTYPE(LineString)) {
        [_placemark beginGeometryOfType:elementName withIdentifier:ident];
    }
    // Geometry sub-elements
    else if (ELTYPE(coordinates)) {
        [_placemark.geometry beginCoordinates];
    } 
    // Polygon sub-elements
    else if (ELTYPE(outerBoundaryIs)) {
        [_placemark.polygon beginOuterBoundary];
    } else if (ELTYPE(innerBoundaryIs)) {
        [_placemark.polygon beginInnerBoundary];
    } else if (ELTYPE(LinearRing)) {
        [_placemark.polygon beginLinearRing];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
                                      namespaceURI:(NSString *)namespaceURI
                                     qualifiedName:(NSString *)qName {
    KMLStyle *style = [_placemark style] ? [_placemark style] : _style;
    
    // Style and sub-elements
    if (ELTYPE(Style)) {
        if (_placemark) {
            [_placemark endStyle];
        } else if (_style) {
            _styles[_style.identifier] = _style;
            _style = nil;
        }
    } else if (ELTYPE(PolyStyle)) {
        [style endPolyStyle];
    } else if (ELTYPE(LineStyle)) {
        [style endLineStyle];
    } else if (ELTYPE(color)) {
        [style endColor];
    } else if (ELTYPE(width)) {
        [style endWidth];
    } else if (ELTYPE(fill)) {
        [style endFill];
    } else if (ELTYPE(outline)) {
        [style endOutline];
    }
    // Placemark and sub-elements
    else if (ELTYPE(Placemark)) {
        if (_placemark) {
            [_placemarks addObject:_placemark];
            _placemark = nil;
        }
    } else if (ELTYPE(Name)) {
        [_placemark endName];
    } else if (ELTYPE(Description)) {
        [_placemark endDescription];
    } else if (ELTYPE(styleUrl)) {
        [_placemark endStyleUrl];
    } else if (ELTYPE(Polygon) || ELTYPE(Point) || ELTYPE(LineString)) {
        [_placemark endGeometry];
    }
    // Geometry sub-elements
    else if (ELTYPE(coordinates)) {
        [_placemark.geometry endCoordinates];
    } 
    // Polygon sub-elements
    else if (ELTYPE(outerBoundaryIs)) {
        [_placemark.polygon endOuterBoundary];
    } else if (ELTYPE(innerBoundaryIs)) {
        [_placemark.polygon endInnerBoundary];
    } else if (ELTYPE(LinearRing)) {
        [_placemark.polygon endLinearRing];
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    KMLElement *element = _placemark ? (KMLElement *)_placemark : (KMLElement *)_style;
    [element addString:string];
}

@end

// Begin the implementations of KMLElement and subclasses.  These objects
// act as state machines during parsing time and then once the document is
// fully parsed they act as an object graph for describing the placemarks and
// styles that have been parsed.

@implementation KMLElement

@synthesize identifier;

- (instancetype)initWithIdentifier:(NSString *)ident {
    if (self = [super init]) {
        identifier = ident;
    }
    return self;
}


- (BOOL)canAddString {
    return NO;
}

- (void)addString:(NSString *)str {
    if ([self canAddString]) {
        if (!accum) {
            accum = [[NSMutableString alloc] init];
        }
        [accum appendString:str];
    }
}

- (void)clearString {
    accum = nil;
}

@end

@implementation KMLStyle 

- (BOOL)canAddString {
    return flags.inColor || flags.inWidth || flags.inFill || flags.inOutline;
}

- (void)beginLineStyle {
    flags.inLineStyle = YES;
}

- (void)endLineStyle {
    flags.inLineStyle = NO;
}

- (void)beginPolyStyle {
    flags.inPolyStyle = YES;
}

- (void)endPolyStyle {
    flags.inPolyStyle = NO;
}

- (void)beginColor {
    flags.inColor = YES;
}

- (void)endColor {
    flags.inColor = NO;
    
    if (flags.inLineStyle) {
        strokeColor = [UIColor colorWithKMLString:accum];
    } else if (flags.inPolyStyle) {
        fillColor = [UIColor colorWithKMLString:accum];
    }
    
    [self clearString];
}

- (void)beginWidth {
    flags.inWidth = YES;
}

- (void)endWidth {
    flags.inWidth = NO;
    strokeWidth = [accum floatValue];
    [self clearString];
}

- (void)beginFill {
    flags.inFill = YES;
}

- (void)endFill {
    flags.inFill = NO;
    fill = [accum boolValue];
    [self clearString];
}

- (void)beginOutline {
    flags.inOutline = YES;
}

- (void)endOutline {
    stroke = [accum boolValue];
    [self clearString];
}

- (void)applyToOverlayPathRenderer:(MKOverlayPathRenderer *)renderer {
    renderer.strokeColor = strokeColor;
    renderer.fillColor = fillColor;
    renderer.lineWidth = strokeWidth;
}

@end

@implementation KMLGeometry

- (BOOL)canAddString {
    return flags.inCoords;
}

- (void)beginCoordinates {
    flags.inCoords = YES;
}

- (void)endCoordinates {
    flags.inCoords = NO;
}

- (MKShape *)mapkitShape {
    return nil;
}

- (MKOverlayPathRenderer *)createOverlayPathRenderer:(MKShape *)shape {
    return nil;
}

@end

@implementation KMLPoint

@synthesize point;

- (void)endCoordinates {
    flags.inCoords = NO;
    
    CLLocationCoordinate2D *points = NULL;
    NSUInteger len = 0;
    
    strToCoords(accum, &points, &len);
    if (len == 1) {
        point = points[0];
    }
    free(points);
    
    [self clearString];
}

- (MKShape *)mapkitShape {
    // KMLPoint corresponds to MKPointAnnotation
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = point;
    return annotation;
}

// KMLPoint does not override MKOverlayPathRenderer: because there is no such
// thing as an overlay view for a point.  They use MKAnnotationViews which
// are vended by the KMLPlacemark class.

@end

@implementation KMLPolygon


- (BOOL)canAddString {
    return polyFlags.inLinearRing && flags.inCoords;
}

- (void)beginOuterBoundary {
    polyFlags.inOuterBoundary = YES;
}

- (void)endOuterBoundary {
    polyFlags.inOuterBoundary = NO;
    outerRing = [accum copy];
    [self clearString];
}

- (void)beginInnerBoundary {
    polyFlags.inInnerBoundary = YES;
}

- (void)endInnerBoundary {
    polyFlags.inInnerBoundary = NO;
    NSString *ring = [accum copy];
    if (!innerRings) {
        innerRings = [[NSMutableArray alloc] init];
    }
    [innerRings addObject:ring];
    [self clearString];
}

- (void)beginLinearRing {
    polyFlags.inLinearRing = YES;
}

- (void)endLinearRing {
    polyFlags.inLinearRing = NO;
}

- (MKShape *)mapkitShape {
    // KMLPolygon corresponds to MKPolygon
    
    // The inner and outer rings of the polygon are stored as kml coordinate
    // list strings until we're asked for mapkitShape.  Only once we're here
    // do we lazily transform them into CLLocationCoordinate2D arrays.
    
    // First build up a list of MKPolygon cutouts for the interior rings.
    NSMutableArray *innerPolys = nil;
    if (innerRings) {
        innerPolys = [[NSMutableArray alloc] initWithCapacity:[innerPolys count]];
        for (NSString *coordStr in innerRings) {
            CLLocationCoordinate2D *coords = NULL;
            NSUInteger coordsLen = 0;
            strToCoords(coordStr, &coords, &coordsLen);
            [innerPolys addObject:[MKPolygon polygonWithCoordinates:coords count:coordsLen]];
            free(coords);
        }
    }
    // Now parse the outer ring.
    CLLocationCoordinate2D *coords = NULL;
    NSUInteger coordsLen = 0;
    strToCoords(outerRing, &coords, &coordsLen);
    
    // Build a polygon using both the outer coordinates and the list (if applicable)
    // of interior polygons parsed.
    MKPolygon *poly = [MKPolygon polygonWithCoordinates:coords count:coordsLen interiorPolygons:innerPolys];
    free(coords);
    return poly;
}

- (MKOverlayPathRenderer *)createOverlayPathRenderer:(MKShape *)shape {
    MKPolygonRenderer *polyPath = [[MKPolygonRenderer alloc] initWithPolygon:(MKPolygon *)shape];
    return polyPath;
}

@end

@implementation KMLLineString

@synthesize points, length;

- (void)endCoordinates {
    flags.inCoords = NO;
    
    if (points) {
        free(points);
    }
    
    strToCoords(accum, &points, &length);
    
    [self clearString];
}

- (MKShape *)mapkitShape {
    // KMLLineString corresponds to MKPolyline
    return [MKPolyline polylineWithCoordinates:points count:length];
}

- (MKOverlayPathRenderer *)createOverlayPathRenderer:(MKShape *)shape {
    MKPolylineRenderer *polyLine = [[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline *)shape];
    return polyLine;
}

@end

@implementation KMLPlacemark

@synthesize style, styleUrl, geometry, name, placemarkDescription;

- (BOOL)canAddString {
    return flags.inName || flags.inStyleUrl || flags.inDescription;
}

- (void)addString:(NSString *)str {
    if (flags.inStyle) {
        [style addString:str];
    } else if (flags.inGeometry) {
        [geometry addString:str];
    } else {
        [super addString:str];
    }
}

- (void)beginName {
    flags.inName = YES;
}

- (void)endName {
    flags.inName = NO;
    name = [accum copy];
    [self clearString];
}

- (void)beginDescription {
    flags.inDescription = YES;
}

- (void)endDescription {
    flags.inDescription = NO;
    placemarkDescription = [accum copy];
    [self clearString];
}

- (void)beginStyleUrl {
    flags.inStyleUrl = YES;
}

- (void)endStyleUrl {
    flags.inStyleUrl = NO;
    styleUrl = [accum copy];
    [self clearString];
}

- (void)beginStyleWithIdentifier:(NSString *)ident {
    flags.inStyle = YES;
    style = [[KMLStyle alloc] initWithIdentifier:ident];
}

- (void)endStyle {
    flags.inStyle = NO;
}

- (void)beginGeometryOfType:(NSString *)elementName withIdentifier:(NSString *)ident {
    flags.inGeometry = YES;
    if (ELTYPE(Point)) {
        geometry = [[KMLPoint alloc] initWithIdentifier:ident];
    } else if (ELTYPE(Polygon)) {
        geometry = [[KMLPolygon alloc] initWithIdentifier:ident];
    } else if (ELTYPE(LineString)) {
        geometry = [[KMLLineString alloc] initWithIdentifier:ident];
    }
}

- (void)endGeometry {
    flags.inGeometry = NO;
}

- (KMLGeometry *)geometry {
    return geometry;
}

- (KMLPolygon *)polygon {
    return [geometry isKindOfClass:[KMLPolygon class]] ? (id)geometry : nil;
}

- (void)_createShape {
    if (!mkShape) {
        mkShape = [geometry mapkitShape];
        mkShape.title = name;
        // Skip setting the subtitle for now because they're frequently
        // too verbose for viewing on in a callout in most kml files.
//        mkShape.subtitle = placemarkDescription;
    }
}

- (id <MKOverlay>)overlay {
    [self _createShape];
    
    if ([mkShape conformsToProtocol:@protocol(MKOverlay)]) {
        return (id <MKOverlay>)mkShape;
    }
    
    return nil;
}

- (id <MKAnnotation>)point {
    [self _createShape];
    
    // Make sure to check if this is an MKPointAnnotation.  MKOverlays also
    // conform to MKAnnotation, so it isn't sufficient to just check to
    // conformance to MKAnnotation.
    if ([mkShape isKindOfClass:[MKPointAnnotation class]]) {
        return (id <MKAnnotation>)mkShape;
    }
    
    return nil;
}

- (MKOverlayPathRenderer *)overlayPathRenderer {
    if (!overlayPathRenderer) {
        id <MKOverlay> overlay = [self overlay];
        if (overlay) {
            overlayPathRenderer = [geometry createOverlayPathRenderer:overlay];
            [style applyToOverlayPathRenderer:overlayPathRenderer];
        }
    }
    return overlayPathRenderer;
}

- (MKAnnotationView *)annotationView {
    if (!annotationView) {
        id <MKAnnotation> annotation = [self point];
        if (annotation) {
            MKPinAnnotationView *pin =
                [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
            pin.canShowCallout = YES;
            pin.animatesDrop = YES;
            annotationView = pin;
        }
    }
    return annotationView;
}

@end

@implementation UIColor (KMLExtras)

+ (UIColor *)colorWithKMLString:(NSString *)kmlColorString {
    NSScanner *scanner = [[NSScanner alloc] initWithString:kmlColorString];
    unsigned color = 0;
    [scanner scanHexInt:&color];
    
    unsigned a = (color >> 24) & 0x000000FF;
    unsigned b = (color >> 16) & 0x000000FF;
    unsigned g = (color >> 8) & 0x000000FF;
    unsigned r = color & 0x000000FF;
    
    CGFloat rf = (CGFloat)r / 255.f;
    CGFloat gf = (CGFloat)g / 255.f;
    CGFloat bf = (CGFloat)b / 255.f;
    CGFloat af = (CGFloat)a / 255.f;
    
    return [UIColor colorWithRed:rf green:gf blue:bf alpha:af];
}

@end

/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
         Utility for loading OBJ model files
      
 */

#import <Foundation/Foundation.h>

#define AAPLOBJModelObjectDefaultKey    @"AAPLOBJModelObjectDefaultKey"

#define AAPLOBJModelGroupDefaultKey     @"AAPLOBJModelGroupDefaultKey"

typedef enum _AAPLObjVertexAttributeType
{
    AAPLObjVertexAttributeTypePosition = 0,
    AAPLObjVertexAttributeTypeNormal,
    AAPLObjVertexAttributeTypeColor,
	AAPLObjVertexAttributeTypeTexcoord0,
	AAPLObjVertexAttributeTypeTexcoord1,
    AAPLObjVertexAttributeTypeTangent,
	AAPLObjVertexAttributeTypeBitangent,
} AAPLObjVertexAttributeType;

@class AAPLOBJModelGroup;
@class AAPLObjVertexAttribute;
@class AAPLObjMaterial;
@class AAPLObjMaterialUsage;

#pragma mark -
#pragma mark AAPLOBJModel
#pragma mark -

@interface AAPLOBJModel : NSObject

- (id)initWithContentsOfFile:(NSString *)inputFilePath computeTangentSpace:(BOOL)computeTangentSpace normalizeNormals:(BOOL)normalizeNormals;


@property (readonly) size_t vertexDataAllocElementSize;

// A copy of the file path passed into initWithContentsOfFile
@property (readonly) NSString *filePath;

// An array of strings.
@property (readonly) NSArray *comments;

// An array of all the AAPLObjMaterials found during parsing
@property (readonly) NSArray *materials;

@property (readonly) NSData *vertexData;

// An array of AAPLObjVertexAttributes
@property (readonly) NSArray *vertexDataAttributes;

// A dictionary whose values are a dictionary of 'objects'. Each object dictionary contains a set of one or more groups
// whose type are AAPLOBJModelGroup objects.
//
// The objects member always contains the default 'object' object for the key, AAPLOBJModelObjectDefaultKey.
// Groups without objects will be stored here.
//
// Every object dictionary will contain the default 'group' object for the key, AAPLOBJModelGroupDefaultKey.
// Definitions without groups will be stored here.
@property (readonly) NSDictionary *objects;

@end

#pragma mark -
#pragma mark AAPLOBJModelGroup
#pragma mark -

@interface AAPLOBJModelGroup : NSObject
{
@public
    NSString *name;
    
    NSData *indexData;
    void *indexDataInternal;
    size_t bytesPerIndex;
    size_t indexCount;
    
    NSMutableArray *materialUsages;
    
    int *rawFaceData;
    size_t rawFaceDataAllocElementSize;
    int currentRawFaceIndex;
    int actualRawFaceVertexCount;
}

@property (readonly) NSString *name;

@property (readonly) NSData *indexData;
@property (readonly) size_t bytesPerIndex;
@property (readonly) size_t indexCount;

// An array of AAPLObjMaterialUsage objects
@property (readonly) NSArray *materialUsages;

@end

#pragma mark -
#pragma mark AAPLObjVertexAttribute
#pragma mark -

@interface AAPLObjVertexAttribute : NSObject
{
@public
    AAPLObjVertexAttributeType indexType;
    int size;
    size_t stride;
    size_t offset;
}

@property (readonly) AAPLObjVertexAttributeType indexType;
@property (readonly) int size;
@property (readonly) size_t stride;
@property (readonly) size_t offset;

@end

#pragma mark -
#pragma mark AAPLObjMaterial
#pragma mark -

@interface AAPLObjMaterial : NSObject
{
@public
    NSString *name;
    
    NSValue *ambientColor;
    float ambientColorArray[3];
    
    NSValue *diffuseColor;
    float diffuseColorArray[3];
    
    NSValue *specularColor;
    float specularColorArray[3];
    
    NSNumber *specularExponent;
    
    NSNumber *indexOfRefraction;
    
    NSNumber *illuminationModel;
    
    NSNumber *dissolve;
    
    NSNumber *transparency;
    
    NSValue *transmissionFilter;
    float transmissionFilterArray[3];
    
    NSString *ambientMapName;
    NSString *diffuseMapName;
    NSString *specularMapName;
    NSString *bumpMapName;
}

@property (readonly) NSString *name; // newmtl

@property (readonly) NSValue *ambientColor; // Ka, pointer to array of 3 floats
@property (readonly) NSValue *diffuseColor; // Kd, pointer to array of 3 floats
@property (readonly) NSValue *specularColor; // Ks, pointer to array of 3 floats

@property (readonly) NSNumber *specularExponent; // Ns, float from 0 to 1000

@property (readonly) NSNumber *indexOfRefraction; // Ni, float from 0.001 to 10

@property (readonly) NSNumber *illuminationModel; // illum, int from 0 to 10

@property (readonly) NSNumber *dissolve; // d, float from 0.0 to 1.0

@property (readonly) NSNumber *transparency; // Tr, float from 0.0 to 1.0

@property (readonly) NSValue *transmissionFilter; // Tf, pointer to array of 3 floats

@property (readonly) NSString *ambientMapName; // map_Ka
@property (readonly) NSString *diffuseMapName; // map_Kd
@property (readonly) NSString *specularMapName; // map_Ks
@property (readonly) NSString *bumpMapName; // map_bump

@end

#pragma mark -
#pragma mark AAPLObjMaterialUsage
#pragma mark -

@interface AAPLObjMaterialUsage : NSObject
{
@public
    NSString *name;
    AAPLObjMaterial *material;
    
    NSRange indexRange;
}

@property (readonly) NSString *name;
@property (readonly) AAPLObjMaterial *material;

@property (readonly) NSRange indexRange;

@end

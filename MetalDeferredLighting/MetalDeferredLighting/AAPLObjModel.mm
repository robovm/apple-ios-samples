/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Utility for loading OBJ model files
  
 */

#import <simd/simd.h>

#import <QuartzCore/QuartzCore.h>
#import <string.h>
#include <map>

#import "AAPLOBJModel.h"

#define REALLOC_ELEMENT_INCREASE  1000

static const uint32_t kSzFloat = sizeof(float);

using namespace std;

typedef enum
{
    PARSE_MODE_OBJ = 0,
    PARSE_MODE_MTL,
} ParseMode;

static void removeLeadingWhitespace(char *string)
{
    if (string == NULL)
        return;
    
    char *curr = string;
    
    while (*curr != '\0' && isspace(*curr))
        ++curr;
    
    memmove(string, curr, strlen(curr)+1);
}

static void removeTrailingWhitespace(char *string)
{
    if (string == NULL)
        return;
    
    size_t length = strlen(string);
    
    if (length > 0)
    {
        char *curr = string+length-1;
        
        while (isspace(*curr))
            --curr;
        
        *(curr+1) = '\0';
    }
}

struct FaceVertex
{
    uint32_t v;
    uint32_t vt;
    uint32_t vn;
};

static bool operator== (const FaceVertex &v1, const FaceVertex &v2)
{
    return ((v1.v == v2.v) && (v1.vt == v2.vt) && (v1.vn == v2.vn));
}

static bool operator< (const FaceVertex &v1, const FaceVertex &v2)
{
    bool result;
    if (v1.v < v2.v)
        result = true;
    else if (v1.v > v2.v)
        result = false;
    else if (v1.vt < v2.vt)
        result = true;
    else if (v1.vt > v2.vt)
        result = false;
    else if (v1.vn < v2.vn)
        result = true;
    else if (v1.vn > v2.vn)
        result = false;
    else
    {
        assert(v1 == v2);
        result = false;
    }
    
    return result;
}

typedef std::map<FaceVertex, uint32_t> FaceVertexMap;

#pragma mark -
#pragma mark AAPLOBJModel
#pragma mark -

@interface AAPLOBJModel ()
- (BOOL)parseString:(const char *)string mode:(ParseMode)mode;
- (BOOL)parseObjModeDefinitionArguments:(char *)readBuffer definitionIndex:(int)definitionIndex;
- (BOOL)parseMtlModeDefinitionArguments:(char *)readBuffer definitionIndex:(int)definitionIndex;
- (BOOL)constructOpenGLData;
@end

@implementation AAPLOBJModel
{
    NSString *filePath;
    BOOL shouldComputeTangentSpace;
    BOOL shouldNormalizeNormals;
    
    NSMutableArray *comments;
    NSMutableDictionary *objects;
    
    NSMutableDictionary *currentObject;
    AAPLOBJModelGroup *currentGroup;
    
    NSMutableArray *materials;
    AAPLObjMaterial *currentMaterial;
    
    float *rawVertexData;
    float *rawVertexTextureData;
    float *rawVertexNormalData;
    
    size_t rawVertexDataAllocElementSize;
    size_t rawVertexTextureDataAllocElementSize;
    size_t rawVertexNormalDataAllocElementSize;
    
    int currentRawVertexIndex;
    int currentRawVertexTextureIndex;
    int currentRawVertexNormalIndex;
    
    int actualRawVertexCount;
    int actualRawVertexTextureCount;
    int actualRawVertexNormalCount;
    
    BOOL faceDefinitionFound;
    
    BOOL faceDefinedVertex, faceDefinedVertexTexture, faceDefinedVertexNormal;
    
    // packed vertex data
    NSData *vertexData;
    float *vertexDataInternal;
    
    size_t vertexDataAllocElementSize;
    int currentVertexDataIndex;
    
    NSMutableArray *vertexDataAttributes;
}

@synthesize vertexDataAllocElementSize;
@synthesize filePath;
@synthesize comments;
@synthesize materials;
@synthesize vertexData;
@synthesize vertexDataAttributes;
@synthesize objects;

- (id)initWithContentsOfFile:(NSString *)inputFilePath computeTangentSpace:(BOOL)computeTangentSpace normalizeNormals:(BOOL)normalizeNormals
{
    self = [super init];
    if (self)
    {
        CFTimeInterval startTime = CACurrentMediaTime();
        
        filePath = [inputFilePath copy];
        
        shouldComputeTangentSpace = computeTangentSpace;
        shouldNormalizeNormals = normalizeNormals;
        
        NSError *error;
        NSString *fileString = [NSString stringWithContentsOfFile:inputFilePath encoding:NSUTF8StringEncoding error:&error];
        if (!fileString)
        {
            NSLog(@"Failed to open obj file: %@, error: %@", inputFilePath, error);
        }
        else
        {
            comments = [[NSMutableArray alloc] initWithCapacity:10];
            objects = [[NSMutableDictionary alloc] initWithCapacity:10];
            
            materials = [[NSMutableArray alloc] initWithCapacity:10];
            
            currentObject = [[NSMutableDictionary alloc] initWithCapacity:10];
            [objects setObject:currentObject forKey:AAPLOBJModelObjectDefaultKey];
            currentGroup = [[AAPLOBJModelGroup alloc] init];
            [currentObject setValue:currentGroup forKey:AAPLOBJModelGroupDefaultKey];
            
            rawVertexDataAllocElementSize = REALLOC_ELEMENT_INCREASE;
            rawVertexTextureDataAllocElementSize = REALLOC_ELEMENT_INCREASE;
            rawVertexNormalDataAllocElementSize = REALLOC_ELEMENT_INCREASE;
            
            rawVertexData = (float *)malloc(4 * rawVertexDataAllocElementSize * kSzFloat);
            rawVertexTextureData = (float *)malloc(3 * rawVertexTextureDataAllocElementSize * kSzFloat);
            rawVertexNormalData = (float *)malloc(3 * rawVertexNormalDataAllocElementSize * kSzFloat);
            
            if ([self parseString:[fileString UTF8String] mode:PARSE_MODE_OBJ])
            {
                NSLog(@"Parse successful");
                
                if ([self constructOpenGLData])
                    NSLog(@"Construction of OpenGL data successful");
                else
                    NSLog(@"Construction of OpenGL data failed");
            }
            else
                NSLog(@"Parse failed");
            
            for (NSDictionary *object in [objects allValues])
            {
                for (AAPLOBJModelGroup *group in [object allValues])
                {
                    if (group->rawFaceData)
                        free(group->rawFaceData);
                }
            }
            
            free(rawVertexData);
            free(rawVertexTextureData);
            free(rawVertexNormalData);
            
            NSLog(@"Time to parse and load file %@ was %f", inputFilePath, CACurrentMediaTime() - startTime);
        }
    }
    
    return self;
}

- (void)dealloc
{
    for (NSDictionary *object in [objects allValues])
    {
        for (AAPLOBJModelGroup *group in [object allValues])
        {
            group->indexData = nil;
            if (group->indexDataInternal)
                free(group->indexDataInternal);
        }
    }
    
    vertexData = nil;
    
    if (vertexDataInternal)
    {
        delete [] (vertexDataInternal);
    }
    
    vertexDataAttributes = nil;
    
    materials = nil;
    
    objects = nil;
    comments = nil;
    
    filePath = nil;
}

typedef struct _DefType
{
    const char string[10];
    size_t length;
} DefType;

enum
{
    OBJ_D_VERTEX_TEXTURE = 0,
    OBJ_D_VERTEX_NORMAL,
    OBJ_D_VERTEX,
    OBJ_D_FACE,
    OBJ_D_GROUP,
    OBJ_D_OBJECT,
    OBJ_D_COMMENT,
    OBJ_D_SMOOTH,
    OBJ_D_USE_MTL,
    OBJ_D_MTL_LIB,
    OBJ_D_COUNT,
};

DefType objDefTypes[OBJ_D_COUNT] =
{
    { "vt",     2 },
    { "vn",     2 },
    { "v",      1 },
    { "f",      1 },
    { "g",      1 },
    { "o",      1 },
    { "#",      1 },
    { "s",      1 },
    { "usemtl", 6 },
    { "mtllib", 6 },
};

enum
{
    MTL_D_NEW_MTL = 0,
    MTL_D_COMMENT,
    MTL_D_AMBIENT_COLOR,
    MTL_D_DIFFUSE_COLOR,
    MTL_D_SPECULAR_COLOR,
    MTL_D_SPECULAR_EXPONENT,
    MTL_D_INDEX_OF_REFRACTION,
    MTL_D_ILLUMINATION_MODEL,
    MTL_D_DISSOLVE,
    MTL_D_TRANSPARENCY,
    MTL_D_TRANSMISSION_FILTER,
    MTL_D_AMBIENT_MAP,
    MTL_D_DIFFUSE_MAP,
    MTL_D_SPECULAR_MAP,
    MTL_D_BUMP_MAP,
    MTL_D_COUNT,
};

DefType mtlDefTypes[MTL_D_COUNT] =
{
    { "newmtl",   6 },
    { "#",        1 },
    { "Ka",       2 },
    { "Kd",       2 },
    { "Ks",       2 },
    { "Ns",       2 },
    { "Ni",       2 },
    { "illum",    5 },
    { "d",        1 },
    { "Tr",       2 },
    { "Tf",       2 },
    { "map_Ka",   6 },
    { "map_Kd",   6 },
    { "map_Ks",   6 },
    { "map_bump", 8 },
};

- (BOOL)parseString:(const char *)string mode:(ParseMode)mode
{
    BOOL success = YES;
    
    DefType *defTypes = objDefTypes;
    int defTypeCount = OBJ_D_COUNT;
    if (mode == PARSE_MODE_MTL)
    {
        defTypes = mtlDefTypes;
        defTypeCount = MTL_D_COUNT;
    }
    
    BOOL foundDef;
    int foundDefIndex = 0;
    int defTypeCharsMatchCount;
    int i,j;
    
    const char *currStringPtr = string;
    size_t maxReadBufferSize = 1000;
    char readBuffer[maxReadBufferSize];
    int readCount;
    
    while (*currStringPtr != '\0')
    {
        foundDef = NO;
        
        for (i=0; i < defTypeCount && foundDef == NO; i++)
        {
            const char *currMatchStringPtr = currStringPtr;
            
            while (*(currMatchStringPtr) == '\t' || *(currMatchStringPtr) == ' ')
                ++currMatchStringPtr;
            
            defTypeCharsMatchCount = 0;
            for (j=0; j < defTypes[i].length && *(currMatchStringPtr+j) != '\0'; j++)
            {
                if (*(currMatchStringPtr+j) == defTypes[i].string[j])
                    ++defTypeCharsMatchCount;
            }
            if (defTypeCharsMatchCount == defTypes[i].length)
            {
                foundDef = YES;
                foundDefIndex = i;
            }
        }
        
        if (foundDef)
        {
            // increment by the definition string
            while (*(currStringPtr) == '\t' || *(currStringPtr) == ' ')
                ++currStringPtr;
            
            int lengthIncrCount = 0;
            while (*currStringPtr != '\0' && lengthIncrCount < defTypes[foundDefIndex].length)
            {
                ++currStringPtr;
                ++lengthIncrCount;
            }
            
            // consume data after definitions
            readCount = 0;
            while (*currStringPtr != '\0' && *currStringPtr != '\n')
            {
                if (readCount < maxReadBufferSize-1)
                    readBuffer[readCount] = *currStringPtr;
                
                ++currStringPtr;
                
                ++readCount;
            }
            readBuffer[readCount] = '\0';
            
            removeLeadingWhitespace(readBuffer);
            removeTrailingWhitespace(readBuffer);
            
            // parse the consumed data
            if (readCount > 0)
            {
                if (mode == PARSE_MODE_OBJ)
                    success = [self parseObjModeDefinitionArguments:readBuffer definitionIndex:foundDefIndex];
                else
                    success = [self parseMtlModeDefinitionArguments:readBuffer definitionIndex:foundDefIndex];
            }
        }
        else
        {
            // ignore any lines where a definition type wasn't found
            while (*currStringPtr != '\0' && *currStringPtr != '\n')
                ++currStringPtr;
        }
        
        // consume a character for the newline left over from consumption
        ++currStringPtr;
    }
    
    return success;
}

- (BOOL)parseObjModeDefinitionArguments:(char *)readBuffer definitionIndex:(int)definitionIndex
{
    if (definitionIndex == OBJ_D_COMMENT)
    {
        NSString *comment = [NSString stringWithCString:readBuffer encoding:NSUTF8StringEncoding];
        if (comment)
            [comments addObject:comment];
        else
            NSLog(@"Unable to add comment with read buffer: %s", readBuffer);
    }
    else if (definitionIndex == OBJ_D_OBJECT)
    {
        currentObject = [[NSMutableDictionary alloc] initWithCapacity:10];
        NSString *string = [NSString stringWithCString:readBuffer encoding:NSUTF8StringEncoding];
        if (string)
        {
            [objects setObject:currentObject forKey:string];
            currentGroup = [[AAPLOBJModelGroup alloc] init];
            [currentObject setValue:currentGroup forKey:AAPLOBJModelGroupDefaultKey];
        }
        else
            NSLog(@"Unable to add object with read buffer: %s", readBuffer);
    }
    else if (definitionIndex == OBJ_D_GROUP)
    {
        NSString *string = [NSString stringWithCString:readBuffer encoding:NSUTF8StringEncoding];
        if (string)
        {
            currentGroup = [[AAPLOBJModelGroup alloc] init];
            
            currentGroup->name = [string copy];
            
            [currentObject setValue:currentGroup forKey:string];
        }
        else
            NSLog(@"Unable to add group with read buffer: %s", readBuffer);
    }
    else if (definitionIndex == OBJ_D_USE_MTL)
    {
        AAPLObjMaterialUsage *materialUsage = [[AAPLObjMaterialUsage alloc] init];
        NSString *string = [NSString stringWithCString:readBuffer encoding:NSUTF8StringEncoding];
        if (string)
        {
            materialUsage->name = [string copy];
            
            materialUsage->indexRange = NSMakeRange(currentGroup->currentRawFaceIndex, 0);
            
            [currentGroup->materialUsages addObject:materialUsage];
            
            NSLog(@"Added material usage: %@, to group: %@", materialUsage->name, currentGroup->name);
        }
        else
            NSLog(@"Unable to add material usage to current group with read buffer: %s", readBuffer);
    }
    else if (definitionIndex == OBJ_D_MTL_LIB)
    {
        NSString *string = [NSString stringWithCString:readBuffer encoding:NSUTF8StringEncoding];
        if (string)
        {
            NSLog(@"Found material lib: %@", string);
            
            NSString *mtlFilePath = [filePath stringByDeletingLastPathComponent];
            mtlFilePath = [mtlFilePath stringByAppendingPathComponent:string];
            
            NSError *error;
            NSString *fileString = [NSString stringWithContentsOfFile:mtlFilePath encoding:NSUTF8StringEncoding error:&error];
            if (!fileString)
            {
                NSLog(@"Failed to open mtl file: %@, error: %@", mtlFilePath, error);
            }
            else
            {
                [self parseString:[fileString UTF8String] mode:PARSE_MODE_MTL];
            }
        }
        else
            NSLog(@"Found material lib, but unable to convert read buffer: %s", readBuffer);
    }
    else if (definitionIndex == OBJ_D_VERTEX || definitionIndex == OBJ_D_VERTEX_TEXTURE || definitionIndex == OBJ_D_VERTEX_NORMAL)
    {
        if (faceDefinitionFound)
        {
            NSLog(@"Found a vertex definition after a face definition, is this allowed?");
            return NO;
        }
        
        const char *sep = " \t";
        char *token;
        int count;
        float value;
        
        int defTypeVertexCount = 3;
        if (definitionIndex == OBJ_D_VERTEX)
            defTypeVertexCount = 4;
        
        int *ptrCurrentIndex = nullptr;
        size_t *ptrAllocElementSize = nullptr;
        float **ptrRawData = nullptr;
        int *ptrActualRawVertexCount = nullptr;
        
        if (definitionIndex == OBJ_D_VERTEX)
        {
            ptrCurrentIndex = &currentRawVertexIndex;
            ptrAllocElementSize = &rawVertexDataAllocElementSize;
            ptrRawData = &rawVertexData;
            ptrActualRawVertexCount = &actualRawVertexCount;
        }
        else if (definitionIndex == OBJ_D_VERTEX_TEXTURE)
        {
            ptrCurrentIndex = &currentRawVertexTextureIndex;
            ptrAllocElementSize = &rawVertexTextureDataAllocElementSize;
            ptrRawData = &rawVertexTextureData;
            ptrActualRawVertexCount = &actualRawVertexTextureCount;
        }
        else if (definitionIndex == OBJ_D_VERTEX_NORMAL)
        {
            ptrCurrentIndex = &currentRawVertexNormalIndex;
            ptrAllocElementSize = &rawVertexNormalDataAllocElementSize;
            ptrRawData = &rawVertexNormalData;
            ptrActualRawVertexCount = &actualRawVertexNormalCount;
        }
        
        for (count = 0, token = strtok(readBuffer, sep); token && count < defTypeVertexCount; token = strtok(NULL, sep), ++count)
        {
            value = strtof(token, NULL);
            
            (*ptrRawData)[(*ptrCurrentIndex) * defTypeVertexCount + count] = value;
        }
        
        ++(*ptrCurrentIndex);
        
        if (*ptrCurrentIndex >= *ptrAllocElementSize)
        {
            NSLog(@"increasing alloc element size from: %d, by: %d", *ptrCurrentIndex, REALLOC_ELEMENT_INCREASE);
            
            *ptrAllocElementSize += REALLOC_ELEMENT_INCREASE;
            float *temp = (float *)realloc(*ptrRawData, defTypeVertexCount * (*ptrAllocElementSize) * kSzFloat);
            if (!temp)
            {
                NSLog(@"Unable to realloc vertex type data");
                return NO;
            }
            else
                *ptrRawData = temp;
        }
        
        *ptrActualRawVertexCount = count;
    }
    else if (definitionIndex == OBJ_D_FACE)
    {
        faceDefinitionFound = YES;
        
        const char *sep = " \t";
        char *token;
        int vertexCount = 0;
        int maxFaceBufferSize = 100;
        int currentFaceBufferIndex;
        char faceBuffer[maxFaceBufferSize];
        int vertexTypeCount;
        int v, vt, vn;
        
        if (!currentGroup->rawFaceData)
        {
            currentGroup->rawFaceDataAllocElementSize = REALLOC_ELEMENT_INCREASE;
            currentGroup->rawFaceData = (int *)malloc(3 * 3 * currentGroup->rawFaceDataAllocElementSize * sizeof(int));
        }
        
        for (token = strtok(readBuffer, sep); token; token = strtok(NULL, sep))
        {
            if (vertexCount > 2)
            {
                NSLog(@"Found a face definition with more than three vertices");
                return NO;
            }
            
            currentFaceBufferIndex = 0;
            vertexTypeCount = 0;
            
            v = vt = vn = 0;
            
            while (1)
            {
                if (*token == '/' || *token == '\0')
                {
                    faceBuffer[currentFaceBufferIndex] = '\0';
                    currentFaceBufferIndex = 0;
                    
                    if (vertexTypeCount == 0)
                        v = (int)strtol(faceBuffer, (char **)NULL, 10);
                    else if (vertexTypeCount == 1)
                        vt = (int)strtol(faceBuffer, (char **)NULL, 10);
                    else if (vertexTypeCount == 2)
                        vn = (int)strtol(faceBuffer, (char **)NULL, 10);
                    
                    if (*token == '\0')
                        break;
                    
                    ++vertexTypeCount;
                }
                else
                {
                    faceBuffer[currentFaceBufferIndex++] = *token;
                }
                
                ++token;
            }
            
            currentGroup->rawFaceData[currentGroup->currentRawFaceIndex * 9 + (vertexCount * 3) + 0] = v;
            currentGroup->rawFaceData[currentGroup->currentRawFaceIndex * 9 + (vertexCount * 3) + 1] = vt;
            currentGroup->rawFaceData[currentGroup->currentRawFaceIndex * 9 + (vertexCount * 3) + 2] = vn;
            
            if (v != 0)
                faceDefinedVertex = YES;
            if (vt != 0)
                faceDefinedVertexTexture = YES;
            if (vn != 0)
                faceDefinedVertexNormal = YES;
            
            ++vertexCount;
        }
        
        ++(currentGroup->currentRawFaceIndex);
        
        if (currentGroup->currentRawFaceIndex >= currentGroup->rawFaceDataAllocElementSize)
        {
            currentGroup->rawFaceDataAllocElementSize += REALLOC_ELEMENT_INCREASE;
            int *temp = (int *)realloc(currentGroup->rawFaceData,
                                       3 * 3 * currentGroup->rawFaceDataAllocElementSize * sizeof(int));
            if (!temp)
            {
                NSLog(@"Unable to realloc face type data");
                return NO;
            }
            else
                currentGroup->rawFaceData = temp;
        }
        
        if (!currentGroup->actualRawFaceVertexCount)
            currentGroup->actualRawFaceVertexCount = vertexCount;
        
        if (currentGroup->actualRawFaceVertexCount != 3)
        {
            NSLog(@"Unsupported vertex count in face definition: %d", currentGroup->actualRawFaceVertexCount);
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)parseMtlModeDefinitionArguments:(char *)readBuffer definitionIndex:(int)definitionIndex
{
    NSString *string = [NSString stringWithCString:readBuffer encoding:NSUTF8StringEncoding];
    if (!string)
    {
        NSLog(@"Failed to create material string from readBuffer: %s", readBuffer);
        return NO;
    }
    
    if (definitionIndex == MTL_D_NEW_MTL)
    {
        currentMaterial = [[AAPLObjMaterial alloc] init];
        [materials addObject:currentMaterial];
        
        currentMaterial->name = [string copy];
    }
    else if (definitionIndex == MTL_D_AMBIENT_COLOR        ||
             definitionIndex == MTL_D_DIFFUSE_COLOR        ||
             definitionIndex == MTL_D_SPECULAR_COLOR       ||
             definitionIndex == MTL_D_TRANSMISSION_FILTER)
    {
        const char *sep = " \t";
        char *token;
        float *values = nullptr;
        int count;
        int countLimit = 3;
        
        if (definitionIndex == MTL_D_AMBIENT_COLOR)
        {
            values = currentMaterial->ambientColorArray;
            currentMaterial->ambientColor = [NSValue valueWithPointer:values];
        }
        else if (definitionIndex == MTL_D_DIFFUSE_COLOR)
        {
            values = currentMaterial->diffuseColorArray;
            currentMaterial->diffuseColor = [NSValue valueWithPointer:values];
        }
        else if (definitionIndex == MTL_D_SPECULAR_COLOR)
        {
            values = currentMaterial->specularColorArray;
            currentMaterial->specularColor = [NSValue valueWithPointer:values];
        }
        else if (definitionIndex == MTL_D_TRANSMISSION_FILTER)
        {
            values = currentMaterial->transmissionFilterArray;
            currentMaterial->transmissionFilter = [NSValue valueWithPointer:values];
        }
        
        for (count=0, token = strtok(readBuffer, sep); token && count < countLimit; token = strtok(NULL, sep), count++)
        {
            values[count] = strtof(token, NULL);
        }
    }
    else if (definitionIndex == MTL_D_SPECULAR_EXPONENT)
    {
        currentMaterial->specularExponent = [NSNumber numberWithFloat:strtof(readBuffer, NULL)];
    }
    else if (definitionIndex == MTL_D_INDEX_OF_REFRACTION)
    {
        currentMaterial->indexOfRefraction = [NSNumber numberWithFloat:strtof(readBuffer, NULL)];
    }
    else if (definitionIndex == MTL_D_ILLUMINATION_MODEL)
    {
        currentMaterial->illuminationModel = [NSNumber numberWithInt:(int)strtof(readBuffer, NULL)];
    }
    else if (definitionIndex == MTL_D_DISSOLVE)
    {
        currentMaterial->dissolve = [NSNumber numberWithFloat:strtof(readBuffer, NULL)];
    }
    else if (definitionIndex == MTL_D_TRANSPARENCY)
    {
        currentMaterial->transparency = [NSNumber numberWithFloat:strtof(readBuffer, NULL)];
    }
    else if (definitionIndex == MTL_D_AMBIENT_MAP)
    {
        currentMaterial->ambientMapName = [string copy];
    }
    else if (definitionIndex == MTL_D_DIFFUSE_MAP)
    {
        currentMaterial->diffuseMapName = [string copy];
    }
    else if (definitionIndex == MTL_D_SPECULAR_MAP)
    {
        currentMaterial->specularMapName = [string copy];
    }
    else if (definitionIndex == MTL_D_BUMP_MAP)
    {
        currentMaterial->bumpMapName = [string copy];
    }
    
    return YES;
}

- (BOOL)canComputeTangentSpace
{
    return (faceDefinedVertex && rawVertexData && actualRawVertexCount == 3 &&
            faceDefinedVertexNormal && rawVertexNormalData && actualRawVertexNormalCount == 3 &&
            faceDefinedVertexTexture && rawVertexTextureData && (actualRawVertexTextureCount == 2 || actualRawVertexTextureCount == 3) &&
            shouldComputeTangentSpace);
}

- (BOOL) constructOpenGLData
{
    NSMutableArray *faceGroups = [[NSMutableArray alloc] initWithCapacity:10];
    
    if(!faceGroups)
    {
        NSLog(@">> ERROR: failed creating a backing-store for face groups!");
        
        return NO;
    } // if

    FaceVertexMap uniqueVertices;
    
    FaceVertexMap::const_iterator it;
    
    // find all groups with face data
    for (NSDictionary *object in [objects allValues])
    {
        for (AAPLOBJModelGroup *group in [object allValues])
        {
            if (group->rawFaceData)
            {
                [faceGroups addObject:group];
            }
        }
    } // for
    
    int i;
    int j;
    
    int *faceData = NULL;
    
    FaceVertex fv;
    uint32_t   index;

    // unique face vertices
    for (AAPLOBJModelGroup *group in faceGroups)
    {
        group->bytesPerIndex = 2;
        group->indexCount = group->currentRawFaceIndex * group->actualRawFaceVertexCount;
        
        for (i=0; i < group->currentRawFaceIndex; ++i)
        {
            faceData = &group->rawFaceData[i * (group->actualRawFaceVertexCount * 3)];
            
            for (j=0; j < group->actualRawFaceVertexCount; ++j)
            {
                fv.v = faceData[(j * 3) + 0];
                fv.vt = faceData[(j * 3) + 1];
                fv.vn = faceData[(j * 3) + 2];
                
                it = uniqueVertices.find(fv);
                
                if (it == uniqueVertices.end())
                {
                    // map a new vertex
                    index = (uint32_t)uniqueVertices.size();
                    uniqueVertices[fv] = index;
                }
                else
                {
                    index = it->second;
                }
                
                if (index >= 65536)
                {
                    group->bytesPerIndex = 4;
                }
            } // for
        } // for
    } // for
    
    // allocate index data for groups
    for (AAPLOBJModelGroup *group in faceGroups)
    {
        group->indexDataInternal = malloc(group->currentRawFaceIndex *
                                          group->actualRawFaceVertexCount *
                                          group->bytesPerIndex);
        
        if(!group->indexDataInternal)
        {
            NSLog(@">> ERROR: failed creating a backing-store for internal index data group!");
            
            return NO;
        } // if

        group->indexData = [[NSData alloc] initWithBytesNoCopy:group->indexDataInternal
                                                        length:group->currentRawFaceIndex *
                            group->actualRawFaceVertexCount *
                            group->bytesPerIndex
                                                  freeWhenDone:NO];
        
        if(!group->indexData)
        {
            NSLog(@">> ERROR: failed creating a backing-store for index data group!");
            
            return NO;
        } // if
    } // for
    
    // normalize vertex normals if requested
    if (shouldNormalizeNormals &&
        (actualRawVertexNormalCount == 2 || actualRawVertexNormalCount == 3))
    {
        NSLog(@"Normalizing vertex normals");
        
        int i;
        int j = 0;
        
        simd::float2 u = 0;
        simd::float3 v = 0;
        
        for (i=0; i < currentRawVertexNormalIndex; i++)
        {
            j = i * actualRawVertexNormalCount;
            
            if (actualRawVertexNormalCount == 2)
            {
                u.x = rawVertexNormalData[j + 0];
                u.y = rawVertexNormalData[j + 1];
                
                u = simd::normalize(u);
                
                rawVertexNormalData[j + 0] = u.x;
                rawVertexNormalData[j + 1] = u.y;
            }
            else if (actualRawVertexNormalCount == 3)
            {
                v.x = rawVertexNormalData[j + 0];
                v.y = rawVertexNormalData[j + 1];
                v.z = rawVertexNormalData[j + 2];
                
                v = simd::normalize(v);
                
                rawVertexNormalData[j + 0] = v.x;
                rawVertexNormalData[j + 1] = v.y;
                rawVertexNormalData[j + 2] = v.z;
            }
        } // for
    } // if
    
    // define vertex attributes
    vertexDataAttributes = [[NSMutableArray alloc] initWithCapacity:10];
    
    if(!vertexDataAttributes)
    {
        NSLog(@">> ERROR: failed creating a backing-store for vertex data attributes!");
        
        return NO;
    } // if
    
    size_t stride = 0;
    int   elements = 0;
    
    if (faceDefinedVertex && rawVertexData)
    {
        AAPLObjVertexAttribute *attrib = [[AAPLObjVertexAttribute alloc] init];
        
        attrib->indexType = AAPLObjVertexAttributeTypePosition;
        attrib->size = actualRawVertexCount;
        attrib->offset = stride;
        
        stride += actualRawVertexCount * kSzFloat;
        elements += actualRawVertexCount;
        
        [vertexDataAttributes addObject:attrib];
    } // if
    
    if (faceDefinedVertexNormal && rawVertexNormalData)
    {
        AAPLObjVertexAttribute *attrib = [[AAPLObjVertexAttribute alloc] init];
        
        attrib->indexType = AAPLObjVertexAttributeTypeNormal;
        attrib->size = actualRawVertexNormalCount;
        attrib->offset = stride;
        
        stride += actualRawVertexNormalCount * kSzFloat;
        elements += actualRawVertexNormalCount;
        
        [vertexDataAttributes addObject:attrib];
    } // if
    
    if (faceDefinedVertexTexture && rawVertexTextureData)
    {
        AAPLObjVertexAttribute *attrib = [[AAPLObjVertexAttribute alloc] init];
        
        attrib->indexType = AAPLObjVertexAttributeTypeTexcoord0;
        attrib->size = actualRawVertexTextureCount;
        attrib->offset = stride;
        
        stride += actualRawVertexTextureCount * kSzFloat;
        elements += actualRawVertexTextureCount;
        
        [vertexDataAttributes addObject:attrib];
    } // if
    
    if ([self canComputeTangentSpace])
    {
        AAPLObjVertexAttribute *attrib = [[AAPLObjVertexAttribute alloc] init];
        
        int tangentSpaceElementCount = 3;
        attrib->indexType = AAPLObjVertexAttributeTypeTangent;
        attrib->size = tangentSpaceElementCount;
        attrib->offset = stride;
        
        stride += tangentSpaceElementCount * kSzFloat;
        elements += tangentSpaceElementCount;
        
        [vertexDataAttributes addObject:attrib];
        
        attrib = [[AAPLObjVertexAttribute alloc] init];
        attrib->indexType = AAPLObjVertexAttributeTypeBitangent;
        attrib->size = tangentSpaceElementCount;
        attrib->offset = stride;
        
        stride += tangentSpaceElementCount * kSzFloat;
        elements += tangentSpaceElementCount;
        
        [vertexDataAttributes addObject:attrib];
    } // if
    
    for (AAPLObjVertexAttribute *attrib in vertexDataAttributes)
    {
        attrib->stride = stride;
    }
    
    // allocate vertex data internal
    currentVertexDataIndex     = int(uniqueVertices.size());
    vertexDataAllocElementSize = currentVertexDataIndex;
    
    try
    {
        vertexDataInternal = new float[(stride / kSzFloat) * vertexDataAllocElementSize];
    } // try
    catch(std::bad_alloc& ba)
    {
        NSLog(@">> ERROR: failed creating a backing-store for internal vertex data!");
        
        return NO;
    } // catch

    int k;

    float *currentVertex = NULL;
    
    // fill out vertex data
    for (it = uniqueVertices.begin(); it != uniqueVertices.end(); it++)
    {
        fv = it->first;
        
        currentVertex = &vertexDataInternal[it->second * elements];
        
        if (fv.v)
        {
            for (k=0; k < actualRawVertexCount; ++k)
            {
                currentVertex[k] = rawVertexData[(fv.v-1) * 4 + k];
            }
        }
        
        if (fv.vn)
        {
            for (k=0; k < actualRawVertexNormalCount; ++k)
            {
                currentVertex[actualRawVertexCount + k] = rawVertexNormalData[(fv.vn-1) * 3 + k];
            }
        }
        
        if (fv.vt)
        {
            for (k=0; k < actualRawVertexTextureCount; ++k)
            {
                currentVertex[actualRawVertexCount + actualRawVertexNormalCount + k] = rawVertexTextureData[(fv.vt-1) * 3 + k];
            }
        } // if
    } // for
    
    int *pFaceData = NULL;
    
    
    uint32_t  va  = 0;
    uint32_t  vb  = 0;
    uint32_t  vta = 0;
    uint32_t  vtb = 0;
    
    int ja = 0;
    int jb = 0;

    uint8_t *groupIndexDataInternal = NULL;
    
    // iterate faces
    for (AAPLOBJModelGroup *group in faceGroups)
    {
        groupIndexDataInternal = (uint8_t *)group->indexDataInternal;
        
        for (i=0; i < group->currentRawFaceIndex; ++i)
        {
            pFaceData = &group->rawFaceData[i * (group->actualRawFaceVertexCount * 3)];
            
            for (j=0; j < group->actualRawFaceVertexCount; ++j)
            {
                fv.v  = pFaceData[(j * 3) + 0];
                fv.vt = pFaceData[(j * 3) + 1];
                fv.vn = pFaceData[(j * 3) + 2];
                
                ja  = (j+1)%3;
                va  = pFaceData[(ja * 3) + 0];
                vta = pFaceData[(ja * 3) + 2];
                
                jb  = (j+2)%3;
                vb  = pFaceData[(jb * 3) + 0];
                vtb = pFaceData[(jb * 3) + 2];
                
                index = uniqueVertices[fv];
                
                if (group->bytesPerIndex == 2)
                {
                    *((uint16_t *)groupIndexDataInternal) = uint16_t(index);
                }
                else
                {
                    *((uint32_t *)groupIndexDataInternal) = index;
                }
                
                groupIndexDataInternal += group->bytesPerIndex;
            } // for
        } // for
    } // for
    
    // compute tangent space tangents
    if ([self canComputeTangentSpace])
    {
        size_t i;
        
        AAPLObjVertexAttribute *vertexAttrib = nil, *normalAttrib = nil, *texCoordAttrib = nil, *tangentAttrib = nil;
        
        for (AAPLObjVertexAttribute *attrib in vertexDataAttributes)
        {
            if (attrib->indexType == AAPLObjVertexAttributeTypePosition)
            {
                vertexAttrib = attrib;
            }
            else if (attrib->indexType == AAPLObjVertexAttributeTypeNormal)
            {
                normalAttrib = attrib;
            }
            else if (attrib->indexType == AAPLObjVertexAttributeTypeTexcoord0)
            {
                texCoordAttrib = attrib;
            }
            else if (attrib->indexType == AAPLObjVertexAttributeTypeTangent)
            {
                tangentAttrib = attrib;
            }
        } // for
        
        simd::float4* tangents = NULL;
        
        try
        {
            tangents = new simd::float4[currentVertexDataIndex];
        } // try
        catch(std::bad_alloc& ba)
        {
            NSLog(@">> ERROR: failed creating a backing-store for tangents array!");
            
            return NO;
        } // catch

        simd::float3* biTangents = NULL;
        
        try
        {
            biTangents = new simd::float3[currentVertexDataIndex];
        } // try
        catch(std::bad_alloc& ba)
        {
            NSLog(@">> ERROR: failed creating a backing-store for bi-tangents array!");
            
            return NO;
        } // catch

        std::memset(tangents,   0x0, currentVertexDataIndex * sizeof(simd::float4));
        std::memset(biTangents, 0x0, currentVertexDataIndex * sizeof(simd::float3));
        
        simd::float3 vertex[3];
        simd::float2 texCoord[3];
        
        simd::float3 vertexEdge[2];
        simd::float2 texCoordEdge[2];
        
        simd::float3 tangent_3f   = 0.0f;
        simd::float3 biTangent_3f = 0.0f;
        
        simd::float4 tangent_4f = 0.0f;
        
        size_t dataIndex = 0;
        
        uint32_t vertexStride   = uint32_t(vertexAttrib->stride/kSzFloat);
        uint32_t vertexOffset   = uint32_t(vertexAttrib->offset/kSzFloat);
        uint32_t texCoordStride = uint32_t(texCoordAttrib->stride/kSzFloat);
        uint32_t texCoordOffset = uint32_t(texCoordAttrib->offset/kSzFloat);
        
        float *pVertexDataInternal   = NULL;
        float *pTexCoordDataInternal = NULL;
        
        float scale = 0.0f;
        float cp    = 0.0f;
        
        uint32_t index[3] = {0, 0, 0};
        
        // Again, index data is always in triangles
        for (AAPLOBJModelGroup *group in faceGroups)
        {
            index[0] = 0;
            index[1] = 0;
            index[2] = 0;
            
            for (i=0; i < group->indexCount; i += 3)
            {
                if (group->bytesPerIndex == 2)
                {
                    index[0] = (uint32_t)(((uint16_t *)(group->indexDataInternal))[i+0]);
                    index[1] = (uint32_t)(((uint16_t *)(group->indexDataInternal))[i+1]);
                    index[2] = (uint32_t)(((uint16_t *)(group->indexDataInternal))[i+2]);
                }
                else if (group->bytesPerIndex == 4)
                {
                    index[0] = ((uint32_t *)(group->indexDataInternal))[i+0];
                    index[1] = ((uint32_t *)(group->indexDataInternal))[i+1];
                    index[2] = ((uint32_t *)(group->indexDataInternal))[i+2];
                }
                
                // Vertices
                
                dataIndex = index[0] * vertexStride + vertexOffset;
                
                pVertexDataInternal = &vertexDataInternal[dataIndex];
                
                vertex[0].x = pVertexDataInternal[0];
                vertex[0].y = pVertexDataInternal[1];
                vertex[0].z = pVertexDataInternal[2];
                
                dataIndex = index[1] * vertexStride + vertexOffset;

                pVertexDataInternal = &vertexDataInternal[dataIndex];
                
                vertex[1].x = pVertexDataInternal[0];
                vertex[1].y = pVertexDataInternal[1];
                vertex[1].z = pVertexDataInternal[2];
                
                dataIndex = index[2] * vertexStride + vertexOffset;

                pVertexDataInternal = &vertexDataInternal[dataIndex];
                
                vertex[2].x = pVertexDataInternal[0];
                vertex[2].y = pVertexDataInternal[1];
                vertex[2].z = pVertexDataInternal[2];
                
                // Texture Coordinates
                
                dataIndex = index[0] * texCoordStride + texCoordOffset;

                pTexCoordDataInternal = &vertexDataInternal[dataIndex];
                
                texCoord[0].x = pTexCoordDataInternal[0];
                texCoord[0].y = pTexCoordDataInternal[1];
                
                dataIndex = index[1] * texCoordStride + texCoordOffset;

                pTexCoordDataInternal = &vertexDataInternal[dataIndex];
                
                texCoord[1].x = pTexCoordDataInternal[0];
                texCoord[1].y = pTexCoordDataInternal[1];
                
                dataIndex = index[2] * texCoordStride + texCoordOffset;

                pTexCoordDataInternal = &vertexDataInternal[dataIndex];
                
                texCoord[2].x = pTexCoordDataInternal[0];
                texCoord[2].y = pTexCoordDataInternal[1];
                
                // Edges
                
                vertexEdge[0] = vertex[1] - vertex[0];
                vertexEdge[1] = vertex[2] - vertex[0];
                
                texCoordEdge[0] = texCoord[1] - texCoord[0];
                texCoordEdge[1] = texCoord[2] - texCoord[0];
                
                cp = texCoordEdge[0].x * texCoordEdge[1].y - texCoordEdge[0].y * texCoordEdge[1].x;
                
                if (cp != 0.0f)
                {
                    scale = 1.0f / cp;
                    
                    tangent_3f  = (vertexEdge[0] * texCoordEdge[1].y) - (vertexEdge[1] * texCoordEdge[0].y);
                    tangent_3f *= scale;
                    
                    biTangent_3f  = (vertexEdge[1] * texCoordEdge[0].x) - (vertexEdge[0] * texCoordEdge[1].x);
                    biTangent_3f *= scale;
                    
                    tangent_4f.x = tangent_3f.x;
                    tangent_4f.y = tangent_3f.y;
                    tangent_4f.z = tangent_3f.z;
                    tangent_4f.w = 0.0f;
                    
                    tangents[index[0]] = tangents[index[0]] + tangent_4f;
                    tangents[index[1]] = tangents[index[1]] + tangent_4f;
                    tangents[index[2]] = tangents[index[2]] + tangent_4f;
                    
                    biTangents[index[0]] = biTangents[index[0]] + biTangent_3f;
                    biTangents[index[1]] = biTangents[index[1]] + biTangent_3f;
                    biTangents[index[2]] = biTangents[index[2]] + biTangent_3f;
                } // if
            } // for
        } // for
        
        simd::float3 normal_3f = 0.0f;
        
        uint32_t normalStride  = uint32_t(normalAttrib->stride/kSzFloat);
        uint32_t normalOffset  = uint32_t(normalAttrib->offset/kSzFloat);
        uint32_t tangentStride = uint32_t(tangentAttrib->stride/kSzFloat);
        uint32_t tangentOffset = uint32_t(tangentAttrib->offset/kSzFloat);
        
        float *pNormalDataInternal = NULL;
        
        for (i=0; i < currentVertexDataIndex; ++i)
        {
            dataIndex = i * normalStride + normalOffset;
            
            pNormalDataInternal = &vertexDataInternal[dataIndex];
            
            normal_3f.x = pNormalDataInternal[0];
            normal_3f.y = pNormalDataInternal[1];
            normal_3f.z = pNormalDataInternal[2];
            
            tangent_3f.x = tangents[i].x;
            tangent_3f.y = tangents[i].y;
            tangent_3f.z = tangents[i].z;
            
            tangent_3f -= (normal_3f * simd::dot(tangent_3f, normal_3f));
            tangent_3f  = simd::normalize(tangent_3f);
            
            dataIndex = i * tangentStride + tangentOffset;
            
            vertexDataInternal[dataIndex + 0] = tangents[i].x;
            vertexDataInternal[dataIndex + 1] = tangents[i].y;
            vertexDataInternal[dataIndex + 2] = tangents[i].z;
            
            vertexDataInternal[dataIndex + 3] = biTangents[i].x;
            vertexDataInternal[dataIndex + 4] = biTangents[i].y;
            vertexDataInternal[dataIndex + 5] = biTangents[i].z;
        } // for
        
        delete [] tangents;
        delete [] biTangents;
    } // if
    
    // create vertex data
    vertexData = [[NSData alloc] initWithBytesNoCopy:vertexDataInternal
                                              length:stride * currentVertexDataIndex
                                        freeWhenDone:NO];
    
    if(!vertexData)
    {
        NSLog(@">> ERROR: failed creating a backing-store for vertex data!");
        
        return NO;
    } // if
    
    AAPLObjMaterialUsage *materialUsage     = nil;
    AAPLObjMaterialUsage *nextMaterialUsage = nil;

    for (AAPLOBJModelGroup *group in faceGroups)
    {
        // update group's material usage index range
        if ([group->materialUsages count] > 0)
        {
            for (i=0; [group->materialUsages count] > 1 && i < [group->materialUsages count]-1; ++i)
            {
                materialUsage     = [group->materialUsages objectAtIndex:i];
                nextMaterialUsage = [group->materialUsages objectAtIndex:i+1];
                
                materialUsage->indexRange.length = nextMaterialUsage->indexRange.location - materialUsage->indexRange.location;
            } // for
            
            materialUsage = [group->materialUsages objectAtIndex:i];
            
            materialUsage->indexRange.length = (group->indexCount/3) - materialUsage->indexRange.location;
        } // if
        
        for (i=0; i < [group->materialUsages count]; ++i)
        {
            materialUsage = [group->materialUsages objectAtIndex:i];
            
            materialUsage->indexRange.location *= group->actualRawFaceVertexCount;
            materialUsage->indexRange.length *= group->actualRawFaceVertexCount;
            
            NSLog(@"Range for material: %@ in group: %@: %lu %lu",
                  materialUsage->name,
                  group->name,
                  (unsigned long)materialUsage->indexRange.location,
                  (unsigned long)materialUsage->indexRange.length);
        } // for
        
        // update group's material reference for each material usage
        for (materialUsage in group->materialUsages)
        {
            for (AAPLObjMaterial *material in materials)
            {
                if ([[material name] isEqualToString:[materialUsage name]])
                {
                    materialUsage->material = material;
                    break;
                } // if
            } // for
        } // for
    } // for
    
    return YES;
}

@end

#pragma mark -
#pragma mark AAPLOBJModelGroup
#pragma mark -

@implementation AAPLOBJModelGroup

@synthesize name;

@synthesize indexData;
@synthesize bytesPerIndex;
@synthesize indexCount;

@synthesize materialUsages;

- (id)init
{
    self = [super init];
    if (self)
    {
        bytesPerIndex = 2;
        
        materialUsages = [[NSMutableArray alloc] initWithCapacity:10];
    }
    
    return self;
}

- (void)dealloc
{
    name = nil;
    materialUsages = nil;
}

@end

#pragma mark -
#pragma mark AAPLObjVertexAttribute
#pragma mark -

@implementation AAPLObjVertexAttribute

@synthesize indexType;
@synthesize size;
@synthesize stride;
@synthesize offset;

@end

#pragma mark -
#pragma mark AAPLObjMaterial
#pragma mark -

@implementation AAPLObjMaterial

@synthesize name;

@synthesize ambientColor;
@synthesize diffuseColor;
@synthesize specularColor;

@synthesize specularExponent;

@synthesize indexOfRefraction;

@synthesize illuminationModel;

@synthesize dissolve;

@synthesize transparency;

@synthesize transmissionFilter;

@synthesize ambientMapName;
@synthesize diffuseMapName;
@synthesize specularMapName;
@synthesize bumpMapName;

- (id)init
{
    self = [super init];
    if (self)
    {
        
    }
    
    return self;
}

- (void)dealloc
{
    name= nil;
    
    ambientColor = nil;
    diffuseColor = nil;
    specularColor = nil;
    
    specularExponent = nil;
    
    indexOfRefraction = nil;
    
    illuminationModel = nil;
    
    dissolve = nil;
    
    transparency = nil;
    
    transmissionFilter = nil;
    
    ambientMapName = nil;
    diffuseMapName = nil;
    specularMapName = nil;
    bumpMapName = nil;
}

@end

#pragma mark -
#pragma mark AAPLObjMaterialUsage
#pragma mark -

@implementation AAPLObjMaterialUsage

@synthesize name;
@synthesize material;

@synthesize indexRange;

- (id)init
{
    self = [super init];
    if (self)
    {
        
    }
    
    return self;
}

- (void)dealloc
{
    name = nil;
    material = nil;
}

@end

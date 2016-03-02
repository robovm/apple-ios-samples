/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for creating a render pass descriptor.
 */

#import "MetalNBodyRenderPassDescriptor.h"

@implementation MetalNBodyRenderPassDescriptor
{
@private
    BOOL _haveTexture;
        
    MTLLoadAction  _load;
    MTLStoreAction _store;
    MTLClearColor  _color;
    
    MTLRenderPassDescriptor* _descriptor;
}

- (nullable MTLRenderPassDescriptor *) _newDescriptor
{
    MTLRenderPassDescriptor* pDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    if(pDescriptor)
    {
        pDescriptor.colorAttachments[0].loadAction  = _load;
        pDescriptor.colorAttachments[0].storeAction = _store;
        pDescriptor.colorAttachments[0].clearColor  = _color;
    } // if
    else
    {
        NSLog(@">> ERROR:  Failed to instantiate a Metal render pass decriptor!");
    } // else
    
    return pDescriptor;
} // _newDescriptor

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        _load        = MTLLoadActionClear;
        _store       = MTLStoreActionStore;
        _color       = MTLClearColorMake(0.0f, 0.0f, 0.0f, 0.0f);
        _haveTexture = NO;
        _descriptor  = [self _newDescriptor];
    } // if
    
    return self;
} // init

- (void) setColor:(MTLClearColor)color
{
    _color = color;
    
    if(_descriptor)
    {
        _descriptor.colorAttachments[0].clearColor = _color;
    } // if
} // setColor

- (void) setDrawable:(nullable id<CAMetalDrawable>)drawable
{
    _haveTexture = NO;
    
    if(drawable && _descriptor)
    {
        id<MTLTexture> texture = drawable.texture;
        
        if(texture)
        {
            _descriptor.colorAttachments[0].texture = texture;
            
            _haveTexture = YES;
        } // if
    } // if
} // setDrawable

@end

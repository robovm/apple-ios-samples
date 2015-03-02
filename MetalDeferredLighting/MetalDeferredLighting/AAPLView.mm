/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  View for Deferred lighting Metal Sample Code. Manages  framebuffers and expects a delegate to repond to render commands to perform drawing. Can be configured with 4 color attachments, depth and stencil attachments.
  
 */

#import "AAPLView.h"

@implementation AAPLView
{
@private
    __weak CAMetalLayer *_metalLayer;
    
    BOOL _layerSizeDidUpdate;
    
    id <MTLTexture>  _depthTex;
    id <MTLTexture>  _stencilTex;
    id <MTLTexture>  _colorTextures[3]; // these are for textures 1-3 (as needed), texture 0 is owned by the drawable
}

@synthesize currentDrawable    = _currentDrawable;
@synthesize renderPassDescriptor = _renderPassDescriptor;

+ (Class)layerClass
{
    return [CAMetalLayer class];
}

- (void)initCommon
{
    self.opaque          = YES;
    self.backgroundColor = nil;
    
    // setting this to yes will allow Main thread to display framebuffer when
    // view:setNeedDisplay: is called by main thread
    _metalLayer = (CAMetalLayer *)self.layer;
    
    _device = MTLCreateSystemDefaultDevice();
    
    _metalLayer.device          = _device;
    _metalLayer.pixelFormat     = MTLPixelFormatBGRA8Unorm;
    
    [self updateDrawableSize];
}

- (void)didMoveToWindow
{
    self.contentScaleFactor = self.window.screen.nativeScale;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
	if(self)
    {
        [self initCommon];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if(self)
    {
        [self initCommon];
    }
    return self;
}

- (void)releaseTextures
{
    _depthTex   = nil;
    _stencilTex = nil;
    
    for (int i = 0; i < 3; i++)
        _colorTextures[i] = nil;
}


- (MTLRenderPassColorAttachmentDescriptor *)colorAttachmentDescriptorWithTexture: (id <MTLTexture>) texture
                                                             clearColor: (MTLClearColor) clearColor
                                                             loadAction: (MTLLoadAction) loadAction
                                                            storeAction: (MTLStoreAction) storeAction
{
    MTLRenderPassColorAttachmentDescriptor *attachment = [MTLRenderPassColorAttachmentDescriptor new];
    attachment.texture = texture;
    attachment.loadAction = loadAction;
    attachment.storeAction = storeAction;
    attachment.clearColor = clearColor;

    return attachment;
}

- (void)setupRenderPassDescriptorForTexture:(id <MTLTexture>) texture
{
    // create renderpass descriptor lazily when we first need it
    if (_renderPassDescriptor == nil)
        _renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    // set up the first color attachment at index 0.
    // This will be the attachment we present to the screen so set its store action to store.
    MTLRenderPassColorAttachmentDescriptor *colorAttachment0 = [self colorAttachmentDescriptorWithTexture:texture
                                                                                     clearColor:colorAttachmentClearValue[0]
                                                                                     loadAction:MTLLoadActionClear
                                                                                    storeAction:MTLStoreActionStore];
    [_renderPassDescriptor.colorAttachments setObject:colorAttachment0 atIndexedSubscript:0];

    // we only need to update the other attachments if something has changed (ie, rotation or layer changed size)
    BOOL doUpdate = (!_colorTextures[0]) || ( _colorTextures[0].width != texture.width  ) ||  (  _colorTextures[0].height != texture.height );
    if (doUpdate)
    {
        // color attachments 1..3 will not be presented and should be discarded so set their store action to dont care
        for (int i = 1; i <= 3; i++)
        if (colorAttachmentFormat[i] != MTLPixelFormatInvalid)
        {
            // color format 0 is only used by the drawable so we skip it here
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: colorAttachmentFormat[i]
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            _colorTextures[i-1] = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassColorAttachmentDescriptor *colorAttachment = [self colorAttachmentDescriptorWithTexture:_colorTextures[i-1]
                                                                                            clearColor:colorAttachmentClearValue[i]
                                                                                            loadAction:MTLLoadActionClear
                                                                                           storeAction:MTLStoreActionDontCare];
            [_renderPassDescriptor.colorAttachments setObject:colorAttachment atIndexedSubscript:i];
        }
    }
    
    if(depthPixelFormat != MTLPixelFormatInvalid)
    {
        BOOL doUpdate = ( _depthTex.width != texture.width  ) ||  ( _depthTex.height != texture.height );
        if(!_depthTex || doUpdate)
        {
            //  If we need a depth texture and don't have one, or if the depth texture we have is the wrong size
            //  Then allocate one of the proper size
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: depthPixelFormat
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            desc.textureType = MTLTextureType2D;
            _depthTex = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassDepthAttachmentDescriptor *depthAttachment = _renderPassDescriptor.depthAttachment;
            depthAttachment.texture = _depthTex;
            depthAttachment.loadAction = MTLLoadActionClear;
            depthAttachment.storeAction = MTLStoreActionDontCare;
            depthAttachment.clearDepth = 1.0;
        }
    }
    
    if(stencilPixelFormat != MTLPixelFormatInvalid)
    {
        BOOL doUpdate  =  ( _stencilTex.width != texture.width  ) || ( _stencilTex.height != texture.height );
        if(!_stencilTex || doUpdate)
        {
            //  If we need a stencil texture and don't have one, or if the depth texture we have is the wrong size
            //  Then allocate one of the proper size
            
            MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: stencilPixelFormat
                                                                                            width: texture.width
                                                                                           height: texture.height
                                                                                        mipmapped: NO];
            
            desc.textureType =  MTLTextureType2D;
            _stencilTex = [_device newTextureWithDescriptor: desc];
            
            MTLRenderPassStencilAttachmentDescriptor* stencilAttachment = _renderPassDescriptor.stencilAttachment;
            stencilAttachment.texture = _stencilTex;
            stencilAttachment.loadAction = MTLLoadActionClear;
            stencilAttachment.storeAction = MTLStoreActionDontCare;
            stencilAttachment.clearStencil = 0;
        }
    }
}

- (MTLRenderPassDescriptor *)renderPassDescriptor
{
    id <CAMetalDrawable> drawable = self.currentDrawable;
    if(!drawable)
    {
        NSLog(@">> ERROR: Failed to get a drawable!");
        _renderPassDescriptor = nil;
    }
    else
    {
        [self setupRenderPassDescriptorForTexture: drawable.texture];
    }
    
    return _renderPassDescriptor;
}

- (id <CAMetalDrawable>)currentDrawable
{
    if (_currentDrawable == nil)
    {
        _currentDrawable = [_metalLayer nextDrawable];
        
        if(!_currentDrawable)
        {
            NSLog(@"CurrentDrawable is nil");
        }
    }
    
    return _currentDrawable;
}

- (void)updateDrawableSize
{
    CGSize drawableSize = self.bounds.size;
    drawableSize.width  *= self.contentScaleFactor;
    drawableSize.height *= self.contentScaleFactor;
    _metalLayer.drawableSize = drawableSize;
}

- (void)display
{
    // Create autorelease pool per frame to avoid possible deadlock situations
    // because there are 3 CAMetalDrawables sitting in an autorelease pool.
    @autoreleasepool
    {
        if(_layerSizeDidUpdate)
        {
            [self updateDrawableSize];
                        
            [_delegate reshape:self];
            
            _layerSizeDidUpdate = NO;
        }
        
        // draw
        [self.delegate render:self];
        
        _currentDrawable    = nil;
    }
}

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    [super setContentScaleFactor:contentScaleFactor];
    
    _layerSizeDidUpdate = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _layerSizeDidUpdate = YES;
}

@end

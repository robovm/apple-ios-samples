/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLShaderCollectionViewController.h"
#import "AAPLView.h"
#import "AAPLViewController.h"
#import "AAPLRenderer.h"
#import "AAPLTeapotMesh.h"
#import "AAPLCubeMesh.h"
#import "AAPLParticleSystemRenderer.h"

@interface AAPLShaderCollectionViewController ()
{
    NSArray *shaderImages;
    AAPLRenderer *_renderer;
    AAPLViewController *_controller;
    AAPLTeapotMesh *_teapotMesh;
    AAPLCubeMesh *_cubeMesh;
    AAPLTexture *_sphereMapTexture;
    AAPLTexture *_normalMapTexture;
}
@end

@implementation AAPLShaderCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    shaderImages = [NSArray arrayWithObjects:@"PhongShader", @"WoodShader", @"FogShader", @"CelShader", @"SphereMapShader", @"NormalMapShader", @"ParticleShader", nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CGFloat currentWidthOfCollectionView = self.collectionView.frame.size.width;
    // the width of the collectionView is about to become the height
    CGFloat newDimension = (currentWidthOfCollectionView - 2.0f) / 2.0f;
    
    UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    flow.itemSize = CGSizeMake(newDimension, newDimension);
    
    [flow invalidateLayout];
    
    // Remove the references so we don't have a cycle
    _renderer = nil;
    if (_controller) {
        _controller.view = nil;
    }
    _controller = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showShader"])
    {
        NSArray *indexPaths = [self.collectionView indexPathsForSelectedItems];
        NSIndexPath *indexPath = [indexPaths objectAtIndex:0];
        NSInteger index = indexPath.row;
        
        _controller = (AAPLViewController *)[segue destinationViewController];
        _device = MTLCreateSystemDefaultDevice();
        _teapotMesh = [AAPLTeapotMesh sharedInstance];
        _cubeMesh = [AAPLCubeMesh sharedInstance];
        
        if(!_controller)
        {
            NSLog(@">> ERROR: Failed creating a view controller!");
        }
        
        _sphereMapTexture = [[AAPLTexture alloc] initWithResourceName:@"SphereMap" extension:@"jpg"];
        BOOL isAcquired = [_sphereMapTexture finalize:_device];
        if(!isAcquired)
        {
            NSLog(@">> ERROR: Failed creating an input 2d texture!");
            assert(0);
        }
        _normalMapTexture = [[AAPLTexture alloc] initWithResourceName:@"NormalMap" extension:@"png"];
        isAcquired = [_normalMapTexture finalize:_device];
        if(!isAcquired)
        {
            NSLog(@">> ERROR: Failed creating an input 2d texture!");
            assert(0);
        }
        
        // Create a renderer based on the index of the shader the user picks
        switch (index) {
            case Phong:
                _renderer = [[AAPLRenderer alloc] initWithName:@"Phong Shader" vertexShader:@"phong_vertex" fragmentShader:@"phong_fragment" mesh:_teapotMesh];
                break;
            case Wood:
                _renderer = [[AAPLRenderer alloc] initWithName:@"Wood Shader" vertexShader:@"wood_vertex" fragmentShader:@"wood_fragment" mesh:_teapotMesh];
                break;
            case Fog:
                _renderer = [[AAPLRenderer alloc] initWithName:@"Fog Shader" vertexShader:@"fog_vertex" fragmentShader:@"fog_fragment" mesh:_teapotMesh];
                break;
            case CelShading:
                _renderer = [[AAPLRenderer alloc] initWithName:@"Cel Shader" vertexShader:@"cel_shading_vertex" fragmentShader:@"cel_shading_fragment" mesh:_teapotMesh];
                break;
            case SphereMap:
                _renderer = [[AAPLRenderer alloc] initWithName:@"Sphere Map" vertexShader:@"sphere_map_vertex" fragmentShader:@"sphere_map_fragment" mesh:_teapotMesh texture:_sphereMapTexture];
                break;
            case NormalMap:
                _renderer = [[AAPLRenderer alloc] initWithName:@"Normal Map" vertexShader:@"normal_map_vertex" fragmentShader:@"normal_map_fragment" mesh:_cubeMesh texture:_normalMapTexture];
                break;
            case ParticleSystem:
                _renderer = [[AAPLParticleSystemRenderer alloc] initWithName:@"Particle System" vertexShader:@"particle_vertex" fragmentShader:@"particle_fragment" mesh:nil];
                break;
            default:
                _renderer = [[AAPLRenderer alloc] initWithName:@"Default Shader" vertexShader:@"phong_vertex" fragmentShader:@"phong_fragment" mesh:_teapotMesh];
                break;
        }
        
        if(!_renderer)
        {
            NSLog(@">> ERROR: Failed creating a renderer!");
        }
        
        _controller.navigationItem.title = _renderer.name;
        _controller.delegate = _renderer;
        
        AAPLView *renderView = (AAPLView *)_controller.view;
        
        if(!renderView)
        {
            NSLog(@">> ERROR: Failed creating a renderer view!");
        }
        
        renderView.delegate = _renderer;
        
        // load all renderer assets before starting game loop
        [_renderer configure:renderView];
        
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return shaderImages.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    UIImageView *shaderImageView = (UIImageView *)[cell viewWithTag:100];
    shaderImageView.image = [UIImage imageNamed:[shaderImages objectAtIndex:indexPath.row]];
    
    UILabel *shaderLabel = (UILabel *)[cell viewWithTag:200];
    
    // Set the text for the label 
    NSInteger index = indexPath.row;
    switch (index) {
        case Phong:
            shaderLabel.text = @"Phong";
            break;
        case Wood:
            shaderLabel.text = @"Wood";
            break;
        case Fog:
            shaderLabel.text = @"Fog";
            break;
        case CelShading:
            shaderLabel.text = @"Cel Shading";
            break;
        case SphereMap:
            shaderLabel.text = @"Sphere Map";
            break;
        case NormalMap:
            shaderLabel.text = @"Normal Map";
            break;
        case ParticleSystem:
            shaderLabel.text = @"Particle System";
            break;
        default:
            shaderLabel.text = @"Default";
            break;
    }
    
    return cell;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                duration:(NSTimeInterval)duration
{
    CGFloat currentWidthOfCollectionHeight = self.collectionView.frame.size.height;
    // the height of the collectionView is about to become the width
    CGFloat newDimension = (currentWidthOfCollectionHeight - 2.0f) / 2.0f;
    
    UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    flow.itemSize = CGSizeMake(newDimension, newDimension);
    [flow invalidateLayout];
    
    [super willRotateToInterfaceOrientation:orientation duration:duration];
}

@end

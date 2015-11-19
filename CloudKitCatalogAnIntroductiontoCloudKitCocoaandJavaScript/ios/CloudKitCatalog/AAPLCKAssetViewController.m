/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This view controller lets you add a CKAsset with an image.
 */

#import "AAPLCKAssetViewController.h"
#import "AAPLCloudManager.h"

@interface AAPLCKAssetViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, copy) NSString *assetRecordName;
@property (weak) IBOutlet UIImageView *assetPreview;

@end

@implementation AAPLCKAssetViewController

- (IBAction)takePhoto {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    
    imagePicker.sourceType = sourceType;
    imagePicker.delegate = self;

    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        
        // retrieve the image and resize it down
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        CGSize newSize = CGSizeMake(512, 512);
        
        if (image.size.width > image.size.height) {
            newSize.height = round(newSize.width * image.size.height / image.size.width);
        } else {
            newSize.width = round(newSize.height * image.size.width / image.size.height);
        }
        
        UIGraphicsBeginImageContext(newSize);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        NSData *data = UIImageJPEGRepresentation(UIGraphicsGetImageFromCurrentImageContext(), 0.75);
        UIGraphicsEndImageContext();
        
        // write the image out to a cache file
        NSURL *cachesDirectory = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
        NSString *temporaryName = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"jpeg"];
        NSURL *localURL = [cachesDirectory URLByAppendingPathComponent:temporaryName];
        [data writeToURL:localURL atomically:YES];
        
        // upload the cache file as a CKAsset
        [self.cloudManager uploadAssetWithURL:localURL completionHandler:^(CKRecord *record) {
            
            if (!record) {
                NSLog(@"Handle this gracefully in your own app.");
            }
            else {
                self.assetRecordName = record.recordID.recordName;
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CloudKit Catalog" message:@"Successfully Uploaded" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];

                [alert addAction:action];
                
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)downloadPhoto {
    if (!self.assetRecordName) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CloudKit Catalog" message:@"Upload an asset to retrieve it." preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];

        [alert addAction:action];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else {
        [self.cloudManager fetchRecordWithID:self.assetRecordName completionHandler:^(CKRecord *record) {
            CKAsset *photoAsset = record[PhotoAssetField];
            
            UIImage *image = [UIImage imageWithContentsOfFile:photoAsset.fileURL.path];
            [self.assetPreview setImage:image];
        }];
    }
}

@end

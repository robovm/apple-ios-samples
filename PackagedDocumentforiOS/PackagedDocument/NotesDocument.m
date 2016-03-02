/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Class representing our document format.
 */

#import "NotesDocument.h"
#import "Note.h"

NSString *kFileExtension = @"notes";    // our document's extension

// the text wrapper
static NSString *TextFileName = @"Text.txt";
static NSStringEncoding TextFileEncoding = NSUTF8StringEncoding;

// the image wrapper
static NSString *ImageFileName = @"Image.png";

@interface NotesDocument ()

@property (nonatomic, strong) NSFileWrapper *textFileWrapper;
@property (nonatomic, strong) NSFileWrapper *imageFileWrapper;

@end


#pragma mark -

@implementation NotesDocument

- (id)initWithFileURL:(NSURL *)url
{
    self = [super initWithFileURL:url];
    if (self != nil)
    {
        _note = [[Note alloc] init];
    }
    return self;
}

// read contents
- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError
{
    NSFileWrapper *fileWrapper = (NSFileWrapper *)contents;
    
    self.textFileWrapper = fileWrapper.fileWrappers[TextFileName];
    NSData *textData = (self.textFileWrapper).regularFileContents;
    self.note.notes = [[NSString alloc] initWithData:textData encoding:TextFileEncoding];
    
    self.imageFileWrapper = fileWrapper.fileWrappers[ImageFileName];
    NSData *imageData = (self.imageFileWrapper).regularFileContents;
    self.note.image = [UIImage imageWithData:imageData];
    
    return YES;
}

// save contents
- (id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
    NSFileWrapper *contentsFileWrapper =
        [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
    
    // write out the note text
    NSData *textData = [self.note.notes dataUsingEncoding:TextFileEncoding];
    self.textFileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:textData];
    (self.textFileWrapper).preferredFilename = TextFileName;
    [contentsFileWrapper addFileWrapper:self.textFileWrapper];
    
    // write out the image data
    NSData *imageData = UIImagePNGRepresentation(self.note.image);
    self.imageFileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:imageData];
    (self.imageFileWrapper).preferredFilename = ImageFileName;
    [contentsFileWrapper addFileWrapper:self.imageFileWrapper];
    
    return contentsFileWrapper;
}

@end



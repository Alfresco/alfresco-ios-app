//
//  ThumbnailManager.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 23/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ThumbnailManager.h"
#import "Utility.h"

@interface ThumbnailManager ()

@property (nonatomic, strong) NSMutableDictionary *thumbnails;
@property (nonatomic, strong) NSString *repositoryId;

@end

@implementation ThumbnailManager

+ (ThumbnailManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.thumbnails = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)saveThumbnailMappingForFolder:(AlfrescoNode *)folder
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *mappingsFolderPath = [fileManager thumbnailsMappingFolderPath];
    
    if (![fileManager fileExistsAtPath:mappingsFolderPath])
    {
        NSError *folderCreationError = nil;
        [fileManager createDirectoryAtPath:mappingsFolderPath withIntermediateDirectories:YES attributes:nil error:&folderCreationError];
        
        if (folderCreationError)
        {
            AlfrescoLogError([folderCreationError localizedDescription]);
        }
    }
    
    NSError *dictionarySavingError = nil;
    NSString *fileNameForDisplayedFolder = uniqueFileNameForNode(folder);
    NSString *completeFilePath = [mappingsFolderPath stringByAppendingPathComponent:fileNameForDisplayedFolder];
    NSMutableDictionary *folderThumbnails = [self.thumbnails objectForKey:folder.identifier];
    NSData *thumbnailDictionaryData = [NSKeyedArchiver archivedDataWithRootObject:folderThumbnails];
    
    [fileManager createFileAtPath:completeFilePath contents:thumbnailDictionaryData error:&dictionarySavingError];
    
    if (dictionarySavingError)
    {
        AlfrescoLogError([dictionarySavingError localizedDescription]);
    }
    else
    {
        if (folder)
        {
            [self.thumbnails removeObjectForKey:folder.identifier];
        }
    }
}

- (UIImage *)thumbnailForNode:(AlfrescoDocument *)document withParentNode:(AlfrescoNode *)parentNode session:(id<AlfrescoSession>)session completionBlock:(ThumbnailCompletionBlock)completionBlock
{
    // get unique identifier of the document - last modified date will be suffixed
    NSString *uniqueIdentifier = uniqueFileNameForNode(document);
    
    NSMutableDictionary *folderThumbnails = [self.thumbnails objectForKey:parentNode.identifier];
    if (!folderThumbnails)
    {
        [self loadThumbnailMappingForFolder:parentNode];
        folderThumbnails = [self.thumbnails objectForKey:parentNode.identifier];
    }
    
    UIImage *thumbnailImage = nil;
    
    // file has been downloaded completely for this document
    if ([folderThumbnails objectForKey:uniqueIdentifier])
    {
        thumbnailImage = [self thumbnailFromDiskForDocumentUniqueIdentifier:uniqueIdentifier parentNode:parentNode];
    }
    else if (!thumbnailImage || ![[ThumbnailDownloader sharedManager] thumbnailHasBeenRequestedForDocument:document])
    {
        // request the file to be downloaded, only if an existing request for this document hasn't been made.
        // set a placeholder image
        thumbnailImage = imageForType([document.name pathExtension]);
        
        [[ThumbnailDownloader sharedManager] retrieveImageForDocument:document toFolderAtPath:[[AlfrescoFileManager sharedManager] thumbnailsDocLibFolderPath] renditionType:@"doclib" session:session completionBlock:^(NSString *savedFileName, NSError *error) {
            if (!error)
            {
                [folderThumbnails setValue:savedFileName forKey:uniqueIdentifier];
                completionBlock(savedFileName, nil);
            }
        }];
    }
    return thumbnailImage;
}

- (UIImage *)thumbnailFromDiskForDocument:(AlfrescoDocument *)document
{
    UIImage *returnImage = nil;
    NSString *thumbnailsExtension = @".png";
    
    NSString *savedFileName = [uniqueFileNameForNode(document) stringByAppendingString:thumbnailsExtension];
    if (savedFileName)
    {
        NSString *filePathToFile = [[[AlfrescoFileManager sharedManager] thumbnailsDocLibFolderPath] stringByAppendingPathComponent:savedFileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePathToFile];
        NSData *imageData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:fileURL];
        returnImage = [UIImage imageWithData:imageData];
    }
    return returnImage;
}

#pragma mark - private functions

- (UIImage *)thumbnailFromDiskForDocumentUniqueIdentifier:(NSString *)uniqueIdentifier parentNode:(AlfrescoNode *)parentNode
{
    UIImage *returnImage = nil;
    
    NSMutableDictionary *folderThumbnails = [self.thumbnails objectForKey:parentNode.identifier];
    NSString *savedFileNamePath = [folderThumbnails objectForKey:uniqueIdentifier];
    if (savedFileNamePath)
    {
        NSURL *fileURL = [NSURL fileURLWithPath:savedFileNamePath];
        NSData *imageData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:fileURL];
        
        returnImage = [UIImage imageWithData:imageData];
    }
    return returnImage;
}

- (void)loadThumbnailMappingForFolder:(AlfrescoNode *)folder
{
    if (!folder)
    {
        return;
    }
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *mappingsFolderPath = [fileManager thumbnailsMappingFolderPath];
    NSString *fileNameForDisplayedFolder = uniqueFileNameForNode(folder);
    NSURL *completeFilePathURL = [NSURL fileURLWithPath:[mappingsFolderPath stringByAppendingPathComponent:fileNameForDisplayedFolder]];
    NSData *thumbnailDictionaryData = [fileManager dataWithContentsOfURL:completeFilePathURL];
    
    NSMutableDictionary *folderThumbnails = nil;
    if (thumbnailDictionaryData)
    {
        folderThumbnails = (NSMutableDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:thumbnailDictionaryData];
    }
    else
    {
        folderThumbnails = [NSMutableDictionary dictionary];
    }
    [self.thumbnails setValue:folderThumbnails forKey:folder.identifier];
}

@end

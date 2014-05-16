//
//  DocumentPreviewManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "DocumentPreviewManager.h"
#import "Utility.h"

static NSString * const kTempFileFolderNamePath = @"tmp";
// notifictations
NSString * const kDocumentPreviewManagerWillStartDownloadNotification = @"DocumentPreviewManagerWillStartDownloadNotification";
NSString * const kDocumentPreviewManagerProgressNotification = @"DocumentPreviewManagerProgressNotification";
NSString * const kDocumentPreviewManagerDocumentDownloadCompletedNotification = @"DocumentPreviewManagerDocumentDownloadCompletedNotification";
// keys
NSString * const kDocumentPreviewManagerDocumentIdentifierNotificationKey = @"DocumentPreviewManagerDocumentIdentifierNotificationKey";
NSString * const kDocumentPreviewManagerProgressBytesRecievedNotificationKey = @"DocumentPreviewManagerProgressBytesRecievedNotificationKey";
NSString * const kDocumentPreviewManagerProgressBytesTotalNotificationKey = @"DocumentPreviewManagerProgressBytesTotalNotificationKey";

@interface DocumentPreviewManager ()

@property (nonatomic, strong) NSString *tmpDownloadFolderPath;
@property (nonatomic, strong) NSString *downloadFolderPath;
@property (nonatomic, strong) NSMutableArray *downloadDocumentIdentifiers;

@end

@implementation DocumentPreviewManager

+ (instancetype)sharedManager
{
    static dispatch_once_t predicate = 0;
    static DocumentPreviewManager *sharedManager = nil;
    dispatch_once(&predicate, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self setupTempDownloadFolder];
        [self setupDownloadFolder];
        self.downloadDocumentIdentifiers = [NSMutableArray array];
    }
    return self;
}

- (BOOL)isCurrentlyDownloadingDocument:(AlfrescoDocument *)document
{
    NSString *documentIdentifier = [self documentIdentifierForDocument:document];
    return [self.downloadDocumentIdentifiers containsObject:documentIdentifier];
}

- (BOOL)hasLocalContentOfDocument:(AlfrescoDocument *)document
{
    NSString *fileLocation = [self filePathForDocument:document];
    BOOL hasContentLocally = [[AlfrescoFileManager sharedManager] fileExistsAtPath:fileLocation];
    return hasContentLocally;
}

- (NSString *)filePathForDocument:(AlfrescoDocument *)document
{
    return [self.downloadFolderPath stringByAppendingPathComponent:filenameAppendedWithDateModified(document.name, document)];
}

- (NSString *)documentIdentifierForDocument:(AlfrescoDocument *)document
{
    return [[self filePathForDocument:document] lastPathComponent];
}

- (AlfrescoRequest *)downloadDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session
{
    AlfrescoRequest *request = nil;
    NSString *documentIdentifier = [self documentIdentifierForDocument:document];
    
    if ([self hasLocalContentOfDocument:document])
    {
        AlfrescoLogInfo(@"Document is already cached locally at path");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDocumentPreviewManagerDocumentDownloadCompletedNotification
                                                            object:document
                                                          userInfo:@{kDocumentPreviewManagerDocumentIdentifierNotificationKey : documentIdentifier}];
    }
    else
    {
        if (![self.downloadDocumentIdentifiers containsObject:documentIdentifier])
        {
            NSString *downloadLocation = [self.tmpDownloadFolderPath stringByAppendingPathComponent:filenameAppendedWithDateModified(document.name, document)];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kDocumentPreviewManagerWillStartDownloadNotification
                                                                object:document
                                                              userInfo:@{kDocumentPreviewManagerDocumentIdentifierNotificationKey : documentIdentifier}];
            
            __weak typeof(self) weakSelf = self;
            request = [self downloadDocument:document toPath:downloadLocation session:session completionBlock:^(NSString *filePath) {
                // move out of temp location
                AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
                NSString *finalDestinationPath = [weakSelf.downloadFolderPath stringByAppendingPathComponent:filenameAppendedWithDateModified(document.name, document)];
                
                NSError *movingError = nil;
                [fileManager moveItemAtPath:filePath toPath:finalDestinationPath error:&movingError];
                
                if (movingError)
                {
                    AlfrescoLogError(@"Unable to move from path %@ to %@", filePath, finalDestinationPath);
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kDocumentPreviewManagerDocumentDownloadCompletedNotification
                                                                    object:document
                                                                  userInfo:@{kDocumentPreviewManagerDocumentIdentifierNotificationKey : documentIdentifier}];
                
            } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kDocumentPreviewManagerProgressNotification
                                                                    object:document
                                                                  userInfo:@{kDocumentPreviewManagerDocumentIdentifierNotificationKey : documentIdentifier,
                                                                             kDocumentPreviewManagerProgressBytesRecievedNotificationKey : @(bytesTransferred),
                                                                             kDocumentPreviewManagerProgressBytesTotalNotificationKey : @(bytesTotal)}];
            }];
        }
    }
    
    return request;
}

#pragma mark - Private Functions

- (void)setupTempDownloadFolder
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    self.tmpDownloadFolderPath = [[fileManager documentPreviewDocumentFolderPath] stringByAppendingPathComponent:kTempFileFolderNamePath];
    if (![fileManager fileExistsAtPath:self.tmpDownloadFolderPath])
    {
        NSError *creationError = nil;
        [fileManager createDirectoryAtPath:self.tmpDownloadFolderPath withIntermediateDirectories:YES attributes:nil error:&creationError];
        
        if (creationError)
        {
            AlfrescoLogError(@"Error creating document preview temp folder");
        }
    }
}

- (void)setupDownloadFolder
{
    self.downloadFolderPath = [[AlfrescoFileManager sharedManager] documentPreviewDocumentFolderPath];
}

- (AlfrescoRequest *)downloadDocument:(AlfrescoDocument *)document toPath:(NSString *)downloadPath session:(id<AlfrescoSession>)session completionBlock:(DocumentPreviewManagerFileSavedBlock)completionBlock progressBlock:(AlfrescoProgressBlock)progressBlock
{
    if (!document)
    {
        AlfrescoLogError(@"Download operation attempted with nil AlfrescoDocument object");
        return nil;
    }
    
    AlfrescoRequest *request = nil;
    if (completionBlock != NULL)
    {
        if ([[AlfrescoFileManager sharedManager] fileExistsAtPath:downloadPath])
        {
            progressBlock(1, 1);
            completionBlock(downloadPath);
        }
        else
        {
            NSString *documentIdentifier = downloadPath.lastPathComponent;
            
            if (![self.downloadDocumentIdentifiers containsObject:documentIdentifier])
            {
                [self.downloadDocumentIdentifiers addObject:documentIdentifier];
                NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:downloadPath append:NO];
                AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
                
                __weak typeof(self) weakSelf = self;
                request = [documentService retrieveContentOfDocument:document outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
                    [weakSelf.downloadDocumentIdentifiers removeObject:documentIdentifier];
                    if (succeeded)
                    {
                        completionBlock(downloadPath);
                    }
                    else
                    {
                        [[AlfrescoFileManager sharedManager] removeItemAtPath:downloadPath error:nil];
                        [Notifier notifyWithAlfrescoError:error];
                    }
                } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                    progressBlock(bytesTransferred, bytesTotal);
                }];
            }
        }
    }
    return request;
}

@end

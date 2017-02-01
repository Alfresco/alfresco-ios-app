//
//  FileMetadata.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 20/02/2015.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FileMetadataStatus)
{
    FileMetadataStatusPendingUpload = 0,
    FileMetadataStatusUploading
};

typedef NS_ENUM(NSUInteger, FileMetadataSaveLocation)
{
    FileMetadataSaveLocationRepository = 0,
    FileMetadataSaveLocationLocalFiles
};

@class AlfrescoNode;

@interface FileMetadata : NSObject <NSCoding>

@property (nonatomic, strong) NSString *accountIdentifier;
@property (nonatomic, strong) NSString *networkIdentifier;
@property (nonatomic, strong) AlfrescoNode *repositoryNode;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSDate *lastAccessed;
@property (nonatomic, assign) FileMetadataStatus status;
@property (nonatomic, assign) FileMetadataSaveLocation saveLocation;
@property (nonatomic, assign) UIDocumentPickerMode mode;

- (instancetype)initWithAccountIdentififer:(NSString *)accountId networkIdentifier:(NSString *)networkIdentifier repositoryNode:(AlfrescoNode *)repoNode fileURL:(NSURL *)fileURL sourceLocation:(FileMetadataSaveLocation)location mode:(UIDocumentPickerMode)mode;

@end

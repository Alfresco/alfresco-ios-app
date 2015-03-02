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

typedef NS_ENUM(NSUInteger, FileMetadataSourceLocation)
{
    FileMetadataSourceLocationRepository = 0,
    FileMetadataSourceLocationLocalFiles
};

@class AlfrescoNode;

@interface FileMetadata : NSObject <NSCoding>

@property (nonatomic, strong) NSString *accountIdentifier;
@property (nonatomic, strong) AlfrescoNode *repositoryNode;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, assign) FileMetadataStatus status;
@property (nonatomic, assign) FileMetadataSourceLocation sourceLocation;

- (instancetype)initWithAccountIdentififer:(NSString *)accountId repositoryNode:(AlfrescoNode *)repoNode fileURL:(NSURL *)fileURL sourceLocation:(FileMetadataSourceLocation)location;

@end

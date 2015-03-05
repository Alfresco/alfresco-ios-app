//
//  FileMetadata.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 20/02/2015.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import "FileMetadata.h"

static NSString * const kFileMetadataAccountIdentifier = @"FileMetadataAccountIdentifier";
static NSString * const kFileMetadataRepositoryNodeIdentifier = @"FileMetadataRepositoryNodeIdentifier";
static NSString * const kFileMetadataFileURLIdentifier = @"FileMetadataFileURLIdentifier";
static NSString * const kFileMetadataLastAccessedIdentifier = @"FileMetadataLastAccessedIdentifier";
static NSString * const kFileMetadataStatusIdentifier = @"FileMetadataStatusIdentifier";
static NSString * const kFileMetadataSourceLocationIdentifier = @"FileMetadataSourceLocationIdentifier";

@interface FileMetadata ()

@end

@implementation FileMetadata

- (instancetype)initWithAccountIdentififer:(NSString *)accountId repositoryNode:(AlfrescoNode *)repoNode fileURL:(NSURL *)fileURL sourceLocation:(FileMetadataSaveLocation)location
{
    self = [self init];
    if (self)
    {
        self.accountIdentifier = accountId;
        self.repositoryNode = repoNode;
        self.fileURL = fileURL;
        self.lastAccessed = [NSDate date];
        self.saveLocation = location;
    }
    return self;
}

#pragma mark - NSCoding Methods

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.accountIdentifier forKey:kFileMetadataAccountIdentifier];
    [aCoder encodeObject:self.repositoryNode forKey:kFileMetadataRepositoryNodeIdentifier];
    [aCoder encodeObject:self.fileURL forKey:kFileMetadataFileURLIdentifier];
    [aCoder encodeObject:self.lastAccessed forKey:kFileMetadataLastAccessedIdentifier];
    [aCoder encodeInteger:self.status forKey:kFileMetadataStatusIdentifier];
    [aCoder encodeInteger:self.saveLocation forKey:kFileMetadataSourceLocationIdentifier];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.accountIdentifier = [aDecoder decodeObjectForKey:kFileMetadataAccountIdentifier];
        self.repositoryNode = [aDecoder decodeObjectForKey:kFileMetadataRepositoryNodeIdentifier];
        self.fileURL = [aDecoder decodeObjectForKey:kFileMetadataFileURLIdentifier];
        self.lastAccessed = [aDecoder decodeObjectForKey:kFileMetadataLastAccessedIdentifier];
        self.status = [aDecoder decodeIntegerForKey:kFileMetadataStatusIdentifier];
        self.saveLocation = [aDecoder decodeIntegerForKey:kFileMetadataSourceLocationIdentifier];
    }
    return self;
}

@end

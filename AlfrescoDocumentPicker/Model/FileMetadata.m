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
static NSString * const kFileMetadataStatusIdentifier = @"FileMetadataStatusIdentifier";
static NSString * const kFileMetadataSourceLocationIdentifier = @"FileMetadataSourceLocationIdentifier";

@interface FileMetadata ()

@end

@implementation FileMetadata

- (instancetype)initWithAccountIdentififer:(NSString *)accountId repositoryNode:(AlfrescoNode *)repoNode fileURL:(NSURL *)fileURL sourceLocation:(FileMetadataSourceLocation)location
{
    self = [self init];
    if (self)
    {
        self.accountIdentifier = accountId;
        self.repositoryNode = repoNode;
        self.fileURL = fileURL;
        self.sourceLocation = location;
    }
    return self;
}

#pragma mark - NSCoding Methods

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.accountIdentifier forKey:kFileMetadataAccountIdentifier];
    [aCoder encodeObject:self.repositoryNode forKey:kFileMetadataRepositoryNodeIdentifier];
    [aCoder encodeObject:self.fileURL forKey:kFileMetadataFileURLIdentifier];
    [aCoder encodeInteger:self.status forKey:kFileMetadataStatusIdentifier];
    [aCoder encodeInteger:self.sourceLocation forKey:kFileMetadataSourceLocationIdentifier];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.accountIdentifier = [aDecoder decodeObjectForKey:kFileMetadataAccountIdentifier];
        self.repositoryNode = [aDecoder decodeObjectForKey:kFileMetadataRepositoryNodeIdentifier];
        self.fileURL = [aDecoder decodeObjectForKey:kFileMetadataFileURLIdentifier];
        self.status = [aDecoder decodeIntegerForKey:kFileMetadataStatusIdentifier];
        self.sourceLocation = [aDecoder decodeIntegerForKey:kFileMetadataSourceLocationIdentifier];
    }
    return self;
}

@end

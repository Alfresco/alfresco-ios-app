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

@synthesize accountIdentifier = _accountIdentifier;
@synthesize repositoryNode = _repositoryNode;
@synthesize fileURL = _fileURL;
@synthesize lastAccessed = _lastAccessed;
@synthesize status = _status;
@synthesize saveLocation = _saveLocation;

- (instancetype)initWithAccountIdentififer:(NSString *)accountId repositoryNode:(AlfrescoNode *)repoNode fileURL:(NSURL *)fileURL sourceLocation:(FileMetadataSaveLocation)location
{
    self = [self init];
    if (self)
    {
        self.accountIdentifier = accountId;
        self.repositoryNode = repoNode;
        self.fileURL = fileURL;
        self.lastAccessed = [NSDate date];
        self.status = FileMetadataStatusPendingUpload;
        self.saveLocation = location;
    }
    return self;
}

#pragma mark - Custom Getters

- (NSString *)accountIdentifier
{
    [self updateAccessDate];
    return _accountIdentifier;
}

- (AlfrescoNode *)repositoryNode
{
    [self updateAccessDate];
    return _repositoryNode;
}

- (NSURL *)fileURL
{
    [self updateAccessDate];
    return _fileURL;
}

- (FileMetadataStatus)status
{
    [self updateAccessDate];
    return _status;
}

- (FileMetadataSaveLocation)saveLocation
{
    [self updateAccessDate];
    return _saveLocation;
}

#pragma mark - Custom Setters

- (void)setAccountIdentifier:(NSString *)accountIdentifier
{
    [self updateAccessDate];
    _accountIdentifier = accountIdentifier;
}

- (void)setRepositoryNode:(AlfrescoNode *)repositoryNode
{
    [self updateAccessDate];
    _repositoryNode = repositoryNode;
}

- (void)setFileURL:(NSURL *)fileURL
{
    [self updateAccessDate];
    _fileURL = fileURL;
}

- (void)setStatus:(FileMetadataStatus)status
{
    [self updateAccessDate];
    _status = status;
}

- (void)setSaveLocation:(FileMetadataSaveLocation)saveLocation
{
    [self updateAccessDate];
    _saveLocation = saveLocation;
}

#pragma mark - Private Methods

- (void)updateAccessDate
{
    self.lastAccessed = [NSDate date];
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

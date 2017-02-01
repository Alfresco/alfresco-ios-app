//
//  FileMetadata.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 20/02/2015.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import "FileMetadata.h"

static NSString * const kFileMetadataAccountIdentifier = @"FileMetadataAccountIdentifier";
static NSString * const kFileMetadataNetworkIdentifier = @"FileMetadataNetworkIdentifier";
static NSString * const kFileMetadataRepositoryNodeIdentifier = @"FileMetadataRepositoryNodeIdentifier";
static NSString * const kFileMetadataFileURLIdentifier = @"FileMetadataFileURLIdentifier";
static NSString * const kFileMetadataLastAccessedIdentifier = @"FileMetadataLastAccessedIdentifier";
static NSString * const kFileMetadataStatusIdentifier = @"FileMetadataStatusIdentifier";
static NSString * const kFileMetadataSourceLocationIdentifier = @"FileMetadataSourceLocationIdentifier";
static NSString * const kFileMetadataModeIdentifier = @"FileMetadataModeIdentifier";

@interface FileMetadata ()
@end

@implementation FileMetadata

@synthesize accountIdentifier = _accountIdentifier;
@synthesize networkIdentifier = _networkIdentifier;
@synthesize repositoryNode = _repositoryNode;
@synthesize fileURL = _fileURL;
@synthesize lastAccessed = _lastAccessed;
@synthesize status = _status;
@synthesize saveLocation = _saveLocation;
@synthesize mode = _mode;

- (instancetype)initWithAccountIdentififer:(NSString *)accountId networkIdentifier:(NSString *)networkIdentifier repositoryNode:(AlfrescoNode *)repoNode fileURL:(NSURL *)fileURL sourceLocation:(FileMetadataSaveLocation)location mode:(UIDocumentPickerMode)mode
{
    self = [self init];
    if (self)
    {
        self.accountIdentifier = accountId;
        self.networkIdentifier = networkIdentifier;
        self.repositoryNode = repoNode;
        self.fileURL = fileURL;
        self.lastAccessed = [NSDate date];
        self.status = FileMetadataStatusPendingUpload;
        self.saveLocation = location;
        self.mode = mode;
    }
    return self;
}

#pragma mark - Custom Getters

- (NSString *)accountIdentifier
{
    [self updateAccessDate];
    return _accountIdentifier;
}

- (NSString *)networkIdentifier
{
    [self updateAccessDate];
    return _networkIdentifier;
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

- (UIDocumentPickerMode)mode
{
    [self updateAccessDate];
    return _mode;
}

#pragma mark - Custom Setters

- (void)setAccountIdentifier:(NSString *)accountIdentifier
{
    [self updateAccessDate];
    _accountIdentifier = accountIdentifier;
}

- (void)setNetworkIdentifier:(NSString *)networkIdentifier
{
    [self updateAccessDate];
    _networkIdentifier = networkIdentifier;
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

- (void)setMode:(UIDocumentPickerMode)mode
{
    [self updateAccessDate];
    _mode = mode;
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
    [aCoder encodeObject:self.networkIdentifier forKey:kFileMetadataNetworkIdentifier];
    [aCoder encodeObject:self.repositoryNode forKey:kFileMetadataRepositoryNodeIdentifier];
    [aCoder encodeObject:self.fileURL forKey:kFileMetadataFileURLIdentifier];
    [aCoder encodeObject:self.lastAccessed forKey:kFileMetadataLastAccessedIdentifier];
    [aCoder encodeInteger:self.status forKey:kFileMetadataStatusIdentifier];
    [aCoder encodeInteger:self.saveLocation forKey:kFileMetadataSourceLocationIdentifier];
    [aCoder encodeInteger:self.mode forKey:kFileMetadataModeIdentifier];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.accountIdentifier = [aDecoder decodeObjectForKey:kFileMetadataAccountIdentifier];
        self.networkIdentifier = [aDecoder decodeObjectForKey:kFileMetadataNetworkIdentifier];
        self.repositoryNode = [aDecoder decodeObjectForKey:kFileMetadataRepositoryNodeIdentifier];
        self.fileURL = [aDecoder decodeObjectForKey:kFileMetadataFileURLIdentifier];
        self.lastAccessed = [aDecoder decodeObjectForKey:kFileMetadataLastAccessedIdentifier];
        self.status = [aDecoder decodeIntegerForKey:kFileMetadataStatusIdentifier];
        self.saveLocation = [aDecoder decodeIntegerForKey:kFileMetadataSourceLocationIdentifier];
        self.mode = [aDecoder decodeIntegerForKey:kFileMetadataModeIdentifier];
    }
    return self;
}

@end

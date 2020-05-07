/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
 
#import "AvatarManager.h"
#import "CoreDataCacheHelper.h"

@implementation AvatarConfiguration

+ (AvatarConfiguration *)defaultConfiguration
{
    AvatarConfiguration *configuration = [[AvatarConfiguration alloc] init];
    
    configuration.ignoreCache = NO;
    configuration.placeholderImage = [UIImage imageNamed:@"avatar.png"];
    
    return configuration;
}

+ (AvatarConfiguration *)defaultConfigurationWithIdentifier: (NSString *)identifier session:(id<AlfrescoSession>)session
{
    AvatarConfiguration *configuration = [AvatarConfiguration defaultConfiguration];
    configuration.identifier = identifier;
    configuration.session = session;
    
    return configuration;
}

@end


@interface AvatarManager ()

@property (nonatomic, strong) NSMutableDictionary *avatars;
@property (nonatomic, strong) NSMutableDictionary *requestedUsernamesAndCompletionBlocks;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, strong) CoreDataCacheHelper *coreDataCacheHelper;

@end

@implementation AvatarManager

+ (AvatarManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static AvatarManager *sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.avatars = [NSMutableDictionary dictionary];
        self.requestedUsernamesAndCompletionBlocks = [NSMutableDictionary dictionary];
        self.coreDataCacheHelper = [[CoreDataCacheHelper alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionRefreshedNotification object:nil];
    }
    return self;
}

// should never get here. Added for completeness
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Functions

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
    
    self.personService = [[AlfrescoPersonService alloc] initWithSession:self.session];
    
    [self clearOldAvatarRequests];
}

#pragma mark - Public Functions

- (UIImage *)avatarForIdentifier:(NSString *)identifier
{
    AvatarImageCache *retrievedImageCacheObject = [self.coreDataCacheHelper retrieveAvatarForIdentifier:identifier inManagedObjectContext:nil];
    return [retrievedImageCacheObject avatarImage];
}

- (void)retrieveAvatarWithConfiguration:(AvatarConfiguration *)configuration completionBlock:(ImageCompletionBlock)completionBlock
{
    if (![self.session isEqual:configuration.session])
    {
        self.session = configuration.session;
        self.personService = [[AlfrescoPersonService alloc] initWithSession:configuration.session];
    }

    if (configuration.identifier == nil)
    {
        completionBlock(configuration.placeholderImage, nil);
        return;
    }

    UIImage *avatarImage = [self avatarForIdentifier: configuration.identifier];
    
    if (avatarImage)
    {
        completionBlock(avatarImage, nil);
        
        if (configuration.ignoreCache)
        {
            [self deleteAvatarForIdentifier:configuration.identifier];
        }
        else
        {
            return;
        }
    }
    else
    {
        completionBlock(configuration.placeholderImage, nil);
    }
    
    ImageCompletionBlock copiedBlock = [completionBlock copy];
    completionBlock(configuration.placeholderImage, nil);
    
    if ([[self.requestedUsernamesAndCompletionBlocks allKeys] containsObject:configuration.identifier] && configuration.ignoreCache == NO)
    {
        [self addCompletionBlock:copiedBlock forKey:configuration.identifier];
        return;
    }
    
    [self addCompletionBlock:copiedBlock forKey:configuration.identifier];
    
    [self.personService retrievePersonWithIdentifier:configuration.identifier completionBlock:^(AlfrescoPerson *person, NSError *identifierError) {
        if (person)
        {
            [self.personService retrieveAvatarForPerson:person completionBlock:^(AlfrescoContentFile *contentFile, NSError *contentError) {
                if (contentFile)
                {
                    NSManagedObjectContext *childManagedObjectContext = [self.coreDataCacheHelper createChildManagedObjectContext];
                    AvatarImageCache *imageCache = [self.coreDataCacheHelper createAvatarObjectInManagedObjectContext:childManagedObjectContext];
                    imageCache.identifier = configuration.identifier;
                    
                    // Crop the avatar
                    UIImage *uncroppedAvatar = [UIImage imageWithContentsOfFile:contentFile.fileUrl.path];
                    UIImage *croppedAvatar = [Utility cropImageIntoSquare:uncroppedAvatar];
                    
                    imageCache.avatarImageData = UIImagePNGRepresentation(croppedAvatar);
                    imageCache.dateAdded = [NSDate date];
                    [self.coreDataCacheHelper saveContextForManagedObjectContext:childManagedObjectContext];
                    
                    // remove the temp file
                    NSError *removalError = nil;
                    [[AlfrescoFileManager sharedManager] removeItemAtPath:contentFile.fileUrl.path error:&removalError];
                    
                    if (removalError)
                    {
                        AlfrescoLogError(@"Error removing file at path %@", contentFile.fileUrl.path);
                    }
                    
                    [self runAllCompletionBlocksForIdentifier:configuration.identifier avatarImage:[imageCache avatarImage] error:contentError];
                }
                else
                {
                    [self runAllCompletionBlocksForIdentifier:configuration.identifier avatarImage:configuration.placeholderImage error:contentError];
                }
            }];
        }
        else
        {
            [self runAllCompletionBlocksForIdentifier:configuration.identifier avatarImage:configuration.placeholderImage error:identifierError];
        }
    }];
}

- (void)deleteAvatarForIdentifier:(NSString *)identifier
{
    AvatarImageCache *avatarToDelete = [self.coreDataCacheHelper retrieveAvatarForIdentifier:identifier inManagedObjectContext:nil];
    [self.coreDataCacheHelper deleteRecordForManagedObject:avatarToDelete inManagedObjectContext:nil];
}

#pragma mark - Private Functions

- (void)addCompletionBlock:(ImageCompletionBlock)completionBlock forKey:(NSString *)personIdentifier
{
    AlfrescoContentFileCompletionBlock retainedBlock = [completionBlock copy];
    if ([[self.requestedUsernamesAndCompletionBlocks allKeys] containsObject:personIdentifier])
    {
        NSMutableArray *blocks = [self.requestedUsernamesAndCompletionBlocks objectForKey:personIdentifier];
        [blocks addObject:retainedBlock];
    }
    else
    {
        NSMutableArray *blocks = [NSMutableArray arrayWithObject:retainedBlock];
        [self.requestedUsernamesAndCompletionBlocks setObject:blocks forKey:personIdentifier];
    }
}

- (void)runAllCompletionBlocksForIdentifier:(NSString *)personIdentifier avatarImage:(UIImage *)avatarImage error:(NSError *)error
{
    NSArray *blocks = [self.requestedUsernamesAndCompletionBlocks objectForKey:personIdentifier];
    [blocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ImageCompletionBlock currentBlock = (ImageCompletionBlock)obj;
        currentBlock(avatarImage, nil);
    }];
    [self removeAllCompletionBlocksForPersonIdentifier:personIdentifier];
}

- (void)removeAllCompletionBlocksForPersonIdentifier:(NSString *)personIdentifier
{
    [self.requestedUsernamesAndCompletionBlocks removeObjectForKey:personIdentifier];
}

- (void)clearOldAvatarRequests
{
    [[self.requestedUsernamesAndCompletionBlocks allKeys] enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        if (![key isEqualToString:self.session.personIdentifier])
        {
            [self.requestedUsernamesAndCompletionBlocks removeObjectForKey:key];
        }
    }];
}

@end

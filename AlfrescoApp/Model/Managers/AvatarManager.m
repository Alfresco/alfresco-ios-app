/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

- (void)retrieveAvatarForPersonIdentifier:(NSString *)identifier session:(id<AlfrescoSession>)session completionBlock:(ImageCompletionBlock)completionBlock
{
    if (![self.session isEqual:session])
    {
        self.session = session;
        self.personService = [[AlfrescoPersonService alloc] initWithSession:session];
    }
    
    if (identifier)
    {
        if (![[self.requestedUsernamesAndCompletionBlocks allKeys] containsObject:identifier])
        {
            [self addCompletionBlock:completionBlock forKey:identifier];
            
            [self.personService retrievePersonWithIdentifier:identifier completionBlock:^(AlfrescoPerson *person, NSError *identifierError) {
                if (person)
                {
                    [self.personService retrieveAvatarForPerson:person completionBlock:^(AlfrescoContentFile *contentFile, NSError *contentError) {
                        if (contentFile)
                        {
                            NSManagedObjectContext *childManagedObjectContext = [self.coreDataCacheHelper createChildManagedObjectContext];
                            AvatarImageCache *imageCache = [self.coreDataCacheHelper createAvatarObjectInManagedObjectContext:childManagedObjectContext];
                            imageCache.identifier = identifier;
                            
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
                            
                            [self runAllCompletionBlocksForIdentifier:identifier avatarImage:[imageCache avatarImage] error:contentError];
                        }
                        else
                        {
                            [self runAllCompletionBlocksForIdentifier:identifier avatarImage:nil error:contentError];
                        }
                    }];
                }
                else
                {
                    [self runAllCompletionBlocksForIdentifier:identifier avatarImage:nil error:identifierError];
                }
            }];
        }
        else
        {
            [self addCompletionBlock:completionBlock forKey:identifier];
        }
    }
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

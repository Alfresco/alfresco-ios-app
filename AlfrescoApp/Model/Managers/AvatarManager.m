//
//  AvatarManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

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

+ (instancetype)sharedManager
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
    
    [self clearAvatarCache];
}

#pragma mark - Public Functions

- (UIImage *)avatarForIdentifier:(NSString *)identifier
{
    AvatarImageCache *retrievedImageCacheObject = [self.coreDataCacheHelper retrieveAvatarForIdentifier:identifier inManagedObjectContext:nil];
    return [retrievedImageCacheObject avatarImage];
}

- (void)retrieveAvatarForPersonIdentifier:(NSString *)identifier session:(id<AlfrescoSession>)session completionBlock:(ImageCompletionBlock)completionBlock
{
    if (!self.session)
    {
        self.session = session;
        self.personService = [[AlfrescoPersonService alloc] initWithSession:session];
    }
    
    UIImage *retrievedImage = [self avatarForIdentifier:identifier];
    
    if (retrievedImage)
    {
        completionBlock(retrievedImage, nil);
    }
    else
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
                            imageCache.avatarImageData = [NSData dataWithContentsOfURL:contentFile.fileUrl];
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

- (void)clearAvatarCache
{
    [self.requestedUsernamesAndCompletionBlocks removeAllObjects];
}

@end

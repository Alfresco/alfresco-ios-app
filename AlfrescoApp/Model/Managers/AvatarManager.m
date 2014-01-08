//
//  AvatarManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "AvatarManager.h"
#import "AlfrescoPersonService.h"

@interface AvatarManager ()

@property (nonatomic, strong) NSMutableDictionary *avatars;
@property (nonatomic, strong) NSMutableDictionary *requestedUsernamesAndCompletionBlocks;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoPersonService *personService;

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

- (AlfrescoContentFile *)avatarForUsername:(NSString *)userIdentifier
{
    return [self.avatars objectForKey:userIdentifier];
}

- (void)retrieveAvatarForPersonIdentifier:(NSString *)identifier session:(id<AlfrescoSession>)session completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock
{
    if (!self.session)
    {
        self.session = session;
        self.personService = [[AlfrescoPersonService alloc] initWithSession:session];
    }
    
    AlfrescoContentFile *avatar = [self.avatars valueForKey:identifier];
    
    if (avatar)
    {
        completionBlock(avatar, nil);
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
                            [self.avatars setObject:contentFile forKey:identifier];
                            [self runAllCompletionBlocksForIdentifier:identifier contentFile:contentFile error:contentError];
                        }
                        else
                        {
                            [self runAllCompletionBlocksForIdentifier:identifier contentFile:nil error:contentError];
                        }
                    }];
                }
                else
                {
                    [self runAllCompletionBlocksForIdentifier:identifier contentFile:nil error:identifierError];
                }
            }];
        }
        else
        {
            [self addCompletionBlock:completionBlock forKey:identifier];
        }
    }
}

- (void)clearAvatarCache
{
    [self.avatars removeAllObjects];
    [self.requestedUsernamesAndCompletionBlocks removeAllObjects];
}

#pragma mark - Private Functions

- (void)addCompletionBlock:(AlfrescoContentFileCompletionBlock)completionBlock forKey:(NSString *)personIdentifier
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

- (void)runAllCompletionBlocksForIdentifier:(NSString *)personIdentifier contentFile:(AlfrescoContentFile *)contentFile error:(NSError *)error
{
    NSArray *blocks = [self.requestedUsernamesAndCompletionBlocks objectForKey:personIdentifier];
    [blocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AlfrescoContentFile *avatarContentFile = [self.avatars objectForKey:personIdentifier];
        AlfrescoContentFileCompletionBlock currentBlock = (AlfrescoContentFileCompletionBlock)obj;
        currentBlock(avatarContentFile, nil);
    }];
    [self removeAllCompletionBlocksForPersonIdentifier:personIdentifier];
}

- (void)removeAllCompletionBlocksForPersonIdentifier:(NSString *)personIdentifier
{
    [self.requestedUsernamesAndCompletionBlocks removeObjectForKey:personIdentifier];
}

@end

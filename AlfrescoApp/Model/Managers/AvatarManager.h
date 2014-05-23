//
//  AvatarManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

@interface AvatarManager : NSObject

+ (AvatarManager *)sharedManager;
- (UIImage *)avatarForIdentifier:(NSString *)identifier;
- (void)retrieveAvatarForPersonIdentifier:(NSString *)identifier session:(id<AlfrescoSession>)session completionBlock:(ImageCompletionBlock)completionBlock;
- (void)deleteAvatarForIdentifier:(NSString *)identifier;

@end

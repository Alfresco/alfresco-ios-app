//
//  AvatarManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AvatarManager : NSObject

+ (instancetype)sharedManager;
- (UIImage *)avatarForIdentifier:(NSString *)identifier;
- (void)retrieveAvatarForPersonIdentifier:(NSString *)identifier session:(id<AlfrescoSession>)session completionBlock:(ImageCompletionBlock)completionBlock;
- (void)deleteAvatarForIdentifier:(NSString *)identifier;

@end

//
//  ActivityHelper.h
//  AlfrescoApp
//
//  Created by Mike Hatfield on 25/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActivityWrapper : NSObject

- (id)initWithActivityEntry:(AlfrescoActivityEntry *)activityEntry;

- (NSString *)nodeIdentifier;

@property (nonatomic, strong, readonly) NSString *avatarUserName;
@property (nonatomic, strong) UIImage *activityImage;
@property (nonatomic, strong, readonly) NSAttributedString *attributedDetailString;
@property (nonatomic, strong, readonly) NSString *detailString;
@property (nonatomic, strong, readonly) NSString *dateString;

@end

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

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSUInteger, MainMenuDisplayType)
{
    MainMenuDisplayTypeMaster,
    MainMenuDisplayTypeDetail,
    MainMenuDisplayTypeModal
};

typedef NS_ENUM (NSUInteger, MainMenuImageMask)
{
    MainMenuImageMaskNone,
    MainMenuImageMaskRounded
};


@interface MainMenuItem : NSObject

@property (nonatomic, strong) NSString *itemIdentifier;
@property (nonatomic, strong) UIImage *itemImage;
@property (nonatomic, strong) NSString *itemTitle;
@property (nonatomic, strong) NSString *itemDescription;
@property (nonatomic, assign) BOOL hidden; // defaults to NO
@property (nonatomic, assign) MainMenuDisplayType displayType;
@property (nonatomic, assign) MainMenuImageMask imageMask;
@property (nonatomic, strong) id associatedObject;
@property (nonatomic, strong) NSString *accessibilityIdentifier;

+ (instancetype)itemWithIdentifier:(NSString *)identifier title:(NSString *)title image:(UIImage *)image description:(NSString *)description displayType:(MainMenuDisplayType)displayType accessibilityIdentifier:(NSString *)accessibilityIdentifier associatedObject:(id)associatedObject;
- (instancetype)initWithIdentifier:(NSString *)identifier title:(NSString *)title image:(UIImage *)image description:(NSString *)description displayType:(MainMenuDisplayType)displayType accessibilityIdentifier:(NSString *)accessibilityIdentifier associatedObject:(id)associatedObject;

@end

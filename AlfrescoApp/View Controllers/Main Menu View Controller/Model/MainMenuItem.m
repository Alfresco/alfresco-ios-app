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

#import "MainMenuItem.h"

@interface MainMenuItem ()

@end

@implementation MainMenuItem

+ (instancetype)itemWithIdentifier:(NSString *)identifier title:(NSString *)title image:(UIImage *)image description:(NSString *)description displayType:(MainMenuDisplayType)displayType accessibilityIdentifier:(NSString *)accessibilityIdentifier associatedObject:(id)associatedObject;
{
    return [[MainMenuItem alloc] initWithIdentifier:identifier title:title image:image description:description displayType:displayType accessibilityIdentifier:accessibilityIdentifier associatedObject:associatedObject];
}

- (instancetype)initWithIdentifier:(NSString *)identifier title:(NSString *)title image:(UIImage *)image description:(NSString *)description displayType:(MainMenuDisplayType)displayType accessibilityIdentifier:(NSString *)accessibilityIdentifier associatedObject:(id)associatedObject
{
    self = [self init];
    if (self)
    {
        self.itemIdentifier = identifier;
        self.itemImage = image;
        self.itemTitle = title;
        self.itemDescription = description;
        self.displayType = displayType;
        self.imageMask = MainMenuImageMaskNone;
        self.associatedObject = associatedObject;
        self.hidden = NO;
        self.accessibilityIdentifier = accessibilityIdentifier;
    }
    return self;
}

@end

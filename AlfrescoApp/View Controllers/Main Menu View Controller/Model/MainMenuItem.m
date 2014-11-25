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
 
#import "MainMenuItem.h"

@interface MainMenuItem ()

@property (nonatomic, assign, readwrite) MainMenuType controllerType;
@property (nonatomic, strong, readwrite) NSString *imageName;
@property (nonatomic, strong, readwrite) NSString *localizedTitleKey;
@property (nonatomic, strong, readwrite) UIViewController *viewController;
@property (nonatomic, assign, readwrite, getter = shouldDisplayInDetailView) BOOL displayInDetail;

@end

@implementation MainMenuItem

- (instancetype)initWithControllerType:(MainMenuType)controllerType imageName:(NSString *)imageName localizedTitleKey:(NSString *)localizedKey viewController:(UIViewController *)viewController displayInDetail:(BOOL)displayInDetail
{
    self = [super init];
    if (self)
    {
        self.controllerType = controllerType;
        self.imageName = imageName;
        self.localizedTitleKey = localizedKey;
        self.viewController = viewController;
        self.displayInDetail = displayInDetail;
    }
    return self;
}

@end

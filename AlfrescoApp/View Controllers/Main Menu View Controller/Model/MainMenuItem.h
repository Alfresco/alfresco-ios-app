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

#import "Constants.h"

@interface MainMenuItem : NSObject

@property (nonatomic, assign, readonly) MainMenuType controllerType;
@property (nonatomic, strong, readonly) NSString *imageName;
@property (nonatomic, strong, readonly) NSString *localizedTitleKey;
@property (nonatomic, strong, readonly) UIViewController *viewController;
@property (nonatomic, assign, readonly, getter = shouldDisplayInDetailView) BOOL displayInDetail;

- (instancetype)initWithControllerType:(MainMenuType)controllerType imageName:(NSString *)imageName localizedTitleKey:(NSString *)localizedKey viewController:(UIViewController *)viewController displayInDetail:(BOOL)displayInDetail;

@end

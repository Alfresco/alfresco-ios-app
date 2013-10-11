//
//  MainMenuItem.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 11/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "MainMenuItem.h"

@interface MainMenuItem ()

@property (nonatomic, assign, readwrite) MainMenuNavigationControllerType controllerType;
@property (nonatomic, strong, readwrite) NSString *imageName;
@property (nonatomic, strong, readwrite) NSString *localizedTitleKey;
@property (nonatomic, strong, readwrite) UIViewController *viewController;
@property (nonatomic, assign, readwrite, getter = shouldDisplayInDetailView) BOOL displayInDetail;

@end

@implementation MainMenuItem

- (instancetype)initWithControllerType:(MainMenuNavigationControllerType)controllerType imageName:(NSString *)imageName localizedTitleKey:(NSString *)localizedKey viewController:(UIViewController *)viewController displayInDetail:(BOOL)displayInDetail
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

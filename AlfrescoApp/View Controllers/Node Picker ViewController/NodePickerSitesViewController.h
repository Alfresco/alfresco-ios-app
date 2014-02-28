//
//  NodePickerSitesControllerViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "SitesListViewController.h"
#import "AlfrescoAppPicker.h"

@interface NodePickerSitesViewController : SitesListViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session nodePickerController:(AlfrescoAppPicker *)nodePicker;

@end

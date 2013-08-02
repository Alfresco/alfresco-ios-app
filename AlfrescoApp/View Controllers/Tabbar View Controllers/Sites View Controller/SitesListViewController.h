//
//  SitesListViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"
#import "SitesCell.h"

typedef NS_ENUM(NSInteger, SiteListType)
{
    SiteListTypeFavouriteSites = 0,
    SiteListTypeMySites,
    SiteListTypeAllSites
};

@interface SitesListViewController : ParentListViewController <UISearchBarDelegate, UISearchDisplayDelegate, SiteCellDelegate>

@end

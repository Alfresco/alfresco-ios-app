//
//  PeoplePickerViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 28/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PeoplePicker.h"

@interface PeoplePickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

- (instancetype)initWithSession:(id<AlfrescoSession>)session peoplePicker:(PeoplePicker *)peoplePicker;

@end

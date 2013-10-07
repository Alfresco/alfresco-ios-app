//
//  SyncObstacleTableViewCell.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 04/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SyncObstacleTableViewCell.h"

@interface SyncObstaclesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, SyncObstacleTableViewCellDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

- (id)initWithErrors:(NSMutableDictionary *)errors;

@end

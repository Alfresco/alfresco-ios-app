//
//  SettingCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 25/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsCellProtocol.h"

@interface SettingCell : UITableViewCell

@property (nonatomic, strong) NSString *preferenceIdentifier;
@property (nonatomic, weak) id<SettingsCellProtocol> delegate;
@property (nonatomic, strong) IBOutlet UILabel *cellTitle;

- (void)updateCellForCellInfo:(NSDictionary *)cellInfo value:(id)cellValue delegate:(id<SettingsCellProtocol>)delegate;

@end

//
//  AttributedLabelTableViewCell.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@interface AttributedLabelCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *attributedLabel;

+ (NSString *)cellIdentifier;

@end

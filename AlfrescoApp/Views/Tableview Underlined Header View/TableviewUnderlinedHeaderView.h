//
//  MetadataHeaderView.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 13/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableviewUnderlinedHeaderView : UIView

@property (nonatomic, weak) IBOutlet UILabel *headerTitleTextLabel;

+ (CGFloat)headerViewHeight;

@end

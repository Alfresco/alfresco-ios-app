//
//  ALFCollectionView.h
//  AlfrescoApp
//
//  Created by Silviu Odobescu on 28/05/15.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ALFCollectionView : UICollectionView

@property (nonatomic, getter=isEditing) BOOL editing;                             // default is NO. setting is not animated.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

@end

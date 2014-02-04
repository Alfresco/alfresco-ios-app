//
//  DocumentPreviewViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, InAppDocumentLocation)
{
    InAppDocumentLocationFilesAndFolders = 0,
    InAppDocumentLocationSync,
    InAppDocumentLocationLocalFiles
};

@interface DocumentPreviewViewController : UIViewController

- (instancetype)initWithAlfrescoDocument:(AlfrescoDocument *)document
                             permissions:(AlfrescoPermissions *)permissions
                         contentFilePath:(NSString *)contentFilePath
                        documentLocation:(InAppDocumentLocation)documentLocation
                                 session:(id<AlfrescoSession>)session;

@end

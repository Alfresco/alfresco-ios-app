//
//  FileLocationSelectionViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 23/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

@class FileLocationSelectionViewController;

@protocol FileLocationSelectionViewControllerDelegate <NSObject>

- (void)fileLocationSelectionViewController:(FileLocationSelectionViewController *)selectionController uploadToFolder:(AlfrescoFolder *)folder session:(id<AlfrescoSession>)session filePath:(NSString *)filePath;
- (void)fileLocationSelectionViewController:(FileLocationSelectionViewController *)selectionController saveFileAtPathToDownloads:(NSString *)filePath;

@end

@interface FileLocationSelectionViewController : UIViewController

@property (nonatomic, weak) id<FileLocationSelectionViewControllerDelegate> delegate;

- (instancetype)initWithFilePath:(NSString *)filePath session:(id<AlfrescoSession>)session delegate:(id<FileLocationSelectionViewControllerDelegate>)delegate;

@end

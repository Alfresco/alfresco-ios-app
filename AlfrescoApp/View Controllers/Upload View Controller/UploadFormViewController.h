//
//  UploadFormViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"
#import "TagPickerViewController.h"
#import <AVFoundation/AVFoundation.h>

@protocol AlfrescoSession;
@class AlfrescoFolder;
@class AlfrescoContentFile;
@class AlfrescoNode;

typedef NS_ENUM(NSUInteger, UploadFormType)
{
    UploadFormTypeImageCreated,
    UploadFormTypeImagePhotoLibrary,
    UploadFormTypeVideoCreated,
    UploadFormTypeVideoPhotoLibrary,
    UploadFormTypeDocument,
    UploadFormTypeAudio,
};

@protocol UploadFormViewControllerDelegate <NSObject>

@optional
- (void)didFinishUploadingNode:(AlfrescoNode *)node;
- (void)didFailUploadingNode:(NSError *)error;
- (void)didCancelUpload;

@end

@interface UploadFormViewController : ParentListViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, TagPickerViewControllerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate>

/**
 * Use this initialiser to upload an image to a given folder
 */
- (id)initWithSession:(id<AlfrescoSession>)session uploadImage:(UIImage *)image fileExtension:(NSString *)extension metadata:(NSDictionary *)metadata inFolder:(AlfrescoFolder *)currentFolder uploadFormType:(UploadFormType)formType delegate:(id<UploadFormViewControllerDelegate>)delegate;

/**
 * Use this initialiser to upload either a document or a video to a given folder
 */
- (id)initWithSession:(id<AlfrescoSession>)session uploadDocumentPath:(NSString *)documentPath inFolder:(AlfrescoFolder *)currentFolder uploadFormType:(UploadFormType)formType delegate:(id<UploadFormViewControllerDelegate>)delegate;

/**
 * Use this initialiser to record and upload an audio file to a given folder
 */
- (id)initWithSession:(id<AlfrescoSession>)session createAndUploadAudioToFolder:(AlfrescoFolder *)currentFolder delegate:(id<UploadFormViewControllerDelegate>)delegate;

@end

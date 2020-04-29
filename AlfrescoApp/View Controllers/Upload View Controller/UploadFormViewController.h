/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
  
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
- (void)didFinishUploadingNode:(AlfrescoNode *)node fromLocation:(NSURL *)locationURL;
- (void)didFailUploadingDocumentWithName:(NSString *)name withError:(NSError *)error;
- (void)didCancelUpload;

@end

@interface UploadFormViewController : ParentListViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, TagPickerViewControllerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

/**
 * Use this initialiser to upload an image to a given folder
 */
- (id)initWithSession:(id<AlfrescoSession>)session uploadImage:(UIImage *)image fileExtension:(NSString *)extension metadata:(NSDictionary *)metadata inFolder:(AlfrescoFolder *)currentFolder uploadFormType:(UploadFormType)formType delegate:(id<UploadFormViewControllerDelegate>)delegate;

/**
 * Use this initialiser to upload an AlfrescoContentFile
 */
- (id)initWithSession:(id<AlfrescoSession>)session uploadContentFile:(AlfrescoContentFile *)contentFile inFolder:(AlfrescoFolder *)currentFolder uploadFormType:(UploadFormType)formType delegate:(id<UploadFormViewControllerDelegate>)delegate;

/**
 * Use this initialiser to upload either a document or a video to a given folder
 */
- (id)initWithSession:(id<AlfrescoSession>)session uploadDocumentPath:(NSString *)documentPath inFolder:(AlfrescoFolder *)currentFolder uploadFormType:(UploadFormType)formType delegate:(id<UploadFormViewControllerDelegate>)delegate;

/**
 * Use this initialiser to record and upload an audio file to a given folder
 */
- (id)initWithSession:(id<AlfrescoSession>)session createAndUploadAudioToFolder:(AlfrescoFolder *)currentFolder delegate:(id<UploadFormViewControllerDelegate>)delegate;

@end

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
  
#import "SystemNotice.h"

@class AlfrescoNode;
@class UserAccount;


/**
 * TaskPriority lightweight class
 */
@interface TaskPriority : NSObject
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSString *summary;
@end


/**
 * System Notices
 */
SystemNotice *displayErrorMessage(NSString *message);
SystemNotice *displayErrorMessageWithTitle(NSString *message, NSString *title);
SystemNotice *displayWarningMessage(NSString *message);
SystemNotice *displayWarningMessageWithTitle(NSString *message, NSString *title);
SystemNotice *displayInformationMessage(NSString *message);
SystemNotice *displayInformationMessageWithTitle(NSString *message, NSString *title);
UIView *activeView(void);

UIImage *smallImageForType(NSString *type);
UIImage *largeImageForType(NSString *type);

/*
 * resize image to a different size
 */
UIImage *resizeImage(UIImage *image, CGSize size);

NSString *relativeTimeFromDate(NSDate *objDate);
NSString *relativeDateFromDate(NSDate *objDate);
NSString *stringForLongFileSize(unsigned long long size);

NSString *stringByRemovingHTMLTagsFromString(NSString *htmlString);

NSString *uniqueFileNameForNode(AlfrescoNode *node);
NSString *fileNameAppendedWithDate(NSString *name);
NSString *filenameAppendedWithDateModified(NSString *filenameOrPath, AlfrescoNode *node);

NSData *jsonDataFromDictionary(NSDictionary *dictionary);

NSDictionary *dictionaryOfVariableBindingsWithArray(NSArray *views);

//void clearOutdatedCacheFiles();

//void uncaughtExceptionHandler(NSException *exception);

@interface Utility : NSObject

+ (BOOL)isValidEmail:(NSString *)emailAddress;
+ (BOOL)isValidFolderName:(NSString *)folderName;
+ (BOOL)isVideo:(NSString *)filePath;
+ (BOOL)isAudio:(NSString *)filePath;
+ (BOOL)isAudioOrVideo:(NSString *)filePath;
+ (void)writeInputStream:(NSInputStream *)inputStream toOutputStream:(NSOutputStream *)outputStream completionBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock;
+ (NSString *)randomAlphaNumericStringOfLength:(NSUInteger)length;
+ (NSString *)mimeTypeForFileExtension:(NSString *)extension;
+ (NSString *)fileExtensionFromMimeType:(NSString *)mimeType;
+ (NSString *)serverURLStringFromAccount:(UserAccount *)account;
+ (void)zoomAppLevelOutWithCompletionBlock:(void (^)(void))completionBlock;
+ (void)resetAppZoomLevelWithCompletionBlock:(void (^)(void))completionBlock;
+ (TaskPriority *)taskPriorityForPriority:(NSNumber *)priority;
+ (NSString *)displayNameForProcessDefinition:(NSString *)task;
+ (UIImage *)cropImageIntoSquare:(UIImage *)originalImage;
+ (void)createBorderedButton:(UIButton *)button label:(NSString *)label color:(UIColor *)color;
+ (NSArray *)localisationsThatRequireTwoRowsInActionView;
+ (NSString *)helpURLLocaleIdentifierForAppLocale;
+ (NSString *)helpURLLocaleIdentifierForLocale:(NSString *)locale;
- (NSString *)accountIdentifierForAccount:(UserAccount *)userAccount;
+ (void)showLocalizedAlertWithTitle:(NSString *)title message:(NSString *)message;
+ (NSData *)dataFromImage:(UIImage *)image metadata:(NSDictionary *)metadata mimetype:(NSString *)mimetype;
+ (NSDictionary *)metadataByAddingGPSToMetadata:(NSDictionary *)metadata;
+ (NSDictionary *)metadataByAddingOrientation:(NSInteger)orientation toMetadata:(NSDictionary *)metadata;
+ (NSDateFormatter *)dateFormatter;
@end

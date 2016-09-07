/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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

#import "PermissionChecker.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "LocationManager.h"

@implementation PermissionChecker

#pragma mark - Public Methods

+ (void)requestPermissionForResourceType:(ResourceType)resourceType completionBlock:(void (^)(BOOL granted))completionBlock
{
    switch (resourceType)
    {
        case ResourceTypeMicrophone:
            [PermissionChecker requestPermissionForMicrophoneWithCompletionBlock:completionBlock];
            break;
            
        case ResourceTypeLocation:
            [PermissionChecker requestPermissionForLocationWithCompletionBlock:completionBlock];
            break;
            
        case ResourceTypeCamera:
            [PermissionChecker requestPermissionForCameraWithCompletionBlock:completionBlock];
            break;
            
        case ResourceTypeLibrary:
            [PermissionChecker requestPermissionForLibraryWithCompletionBlock:completionBlock];
            break;
            
        default:
            break;
    }
}

#pragma mark - Private Methods

+ (void)requestPermissionForCameraWithCompletionBlock:(void (^)(BOOL granted))completionBlock
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    switch (status)
    {
        case AVAuthorizationStatusAuthorized:
        {
            completionBlock(YES);
        }
            break;
            
        case AVAuthorizationStatusDenied:
        {
            [Utility showLocalizedAlertWithTitle:@"permissions.camera.denied.title" message:@"permissions.camera.denied.message"];
            completionBlock(NO);
        }
            break;
            
        case AVAuthorizationStatusRestricted:
        {
            [Utility showLocalizedAlertWithTitle:@"permissions.camera.restricted.title" message:@"permissions.camera.restricted.message"];
            completionBlock(NO);
        }
            break;
            
        case AVAuthorizationStatusNotDetermined:
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted){
                completionBlock(granted);
            }];
        }
            break;
            
        default:
            break;
    }
}

+ (void)requestPermissionForLibraryWithCompletionBlock:(void (^)(BOOL))completionBlock
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    switch (status)
    {
        case PHAuthorizationStatusAuthorized:
        {
            completionBlock(YES);
        }
            break;
            
        case PHAuthorizationStatusDenied:
        {
            [Utility showLocalizedAlertWithTitle:@"permissions.library.denied.title" message:@"permissions.library.denied.message"];
            completionBlock(NO);
        }
            break;
            
        case PHAuthorizationStatusRestricted:
        {
            [Utility showLocalizedAlertWithTitle:@"permissions.library.restricted.title" message:@"permissions.library.restricted.message"];
            completionBlock(NO);
        }
            break;
            
        case PHAuthorizationStatusNotDetermined:
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
                if (status == PHAuthorizationStatusAuthorized)
                {
                    // Access has been granted.
                    completionBlock(YES);
                }
                else
                {
                    // Access has been denied.
                    completionBlock(NO);
                }
            }];
        }
            break;
            
        default:
            break;
    }
}

+ (void)requestPermissionForMicrophoneWithCompletionBlock:(void (^)(BOOL))completionBlock
{
    AVAudioSessionRecordPermission recordPermission = [[AVAudioSession sharedInstance] recordPermission];
    
    switch (recordPermission)
    {
        case AVAudioSessionRecordPermissionDenied:
        {
            [Utility showLocalizedAlertWithTitle:@"permissions.microphone.denied.title" message:@"permissions.microphone.denied.message"];
            completionBlock(NO);
        }
            break;
            
        case AVAudioSessionRecordPermissionGranted:
        {
            completionBlock(YES);
        }
            break;
            
        case AVAudioSessionRecordPermissionUndetermined:
        {
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted){
                completionBlock(granted);
            }];
        }
            break;
            
        default:
            break;
    }
}

+ (void)requestPermissionForLocationWithCompletionBlock:(void (^)(BOOL))completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[LocationManager sharedManager] startLocationUpdates];
    });
}

@end
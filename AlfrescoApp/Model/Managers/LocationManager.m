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
 
#import "LocationManager.h"

@interface LocationManager ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *latestLocation;
@property (nonatomic, readwrite, assign, getter = isTrackingLocation) BOOL trackingLocation;

@end

@implementation LocationManager

+ (LocationManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static LocationManager *sharedLocationManager = nil;
    dispatch_once(&onceToken, ^{
        sharedLocationManager = [[self alloc] init];
    });
    return sharedLocationManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    return self;
}

- (CLLocationCoordinate2D)currentLocationCoordinates
{
    return self.latestLocation.coordinate;
}

- (BOOL)usersLocationAuthorisation
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        return YES;
    }
    return NO;
}

- (void)startLocationUpdates
{
    if ([CLLocationManager locationServicesEnabled] == NO)
    {
        [Utility showLocalizedAlertWithTitle:@"permissions.location.disabled.title" message:@"permissions.location.disabled.message"];
        return;
    }
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch (status)
    {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            [self.locationManager startUpdatingLocation];
            self.trackingLocation = YES;
        }
            break;
            
        case kCLAuthorizationStatusDenied:
        {
            [Utility showLocalizedAlertWithTitle:@"permissions.location.denied.title" message:@"permissions.location.denied.message"];
        }
            break;
            
        case kCLAuthorizationStatusNotDetermined:
        {
            [self.locationManager requestWhenInUseAuthorization];
        }
            break;
            
        case kCLAuthorizationStatusRestricted:
        {
            [Utility showLocalizedAlertWithTitle:@"permissions.location.restricted.title" message:@"permissions.location.restricted.message"];
        }
            break;
            
        default:
            break;
    }
}

- (void)stopLocationUpdates
{
    [self.locationManager stopUpdatingLocation];
    self.trackingLocation = NO;
}

#pragma mark - CLLocationManagerDelegate Functions

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *updatedLocation = [locations lastObject];
    self.latestLocation = updatedLocation;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    AlfrescoLogError(@"Error occured in LocationManager. Error: %@", error.localizedDescription);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        [self.locationManager startUpdatingLocation];
        self.trackingLocation = YES;
    }
    else
    {
        [self.locationManager stopUpdatingLocation];
        self.trackingLocation = NO;
    }
}

@end

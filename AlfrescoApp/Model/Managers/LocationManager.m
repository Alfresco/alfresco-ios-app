//
//  LocationManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "LocationManager.h"

@interface LocationManager ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *latestLocation;
@property (nonatomic, readwrite, assign, getter = isTrackingLocation) BOOL trackingLocation;

@end

@implementation LocationManager

+ (id)sharedManager
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
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
    {
        return YES;
    }
    return NO;
}

- (void)startLocationUpdates
{
    if ([CLLocationManager locationServicesEnabled])
    {
        [self.locationManager startUpdatingLocation];
        self.trackingLocation = YES;
    }
}

- (void)stopLocationUpdates
{
    [self.locationManager stopUpdatingLocation];
    self.trackingLocation = NO;
}

#pragma mark - CLLocationManagerDelegate Functions

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    self.latestLocation = newLocation;
}

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
    if (status == kCLAuthorizationStatusAuthorized)
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

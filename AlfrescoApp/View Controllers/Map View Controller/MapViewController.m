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

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "MapViewController.h"
#import "AlfrescoDocument+MapAnnotation.h"

@interface MapViewController ()
@property (nonatomic, strong) AlfrescoDocument *document;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UILabel *noMapLabel;
@end

@implementation MapViewController

- (id)initWithDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        _document = document;
        _session = session;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setAccessibilityIdentifiers];

    MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    mapView.userTrackingMode = MKUserTrackingModeNone;
    mapView.mapType = MKMapTypeHybrid;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(0, 0), 1000, 1000);
    [mapView setRegion:region];
    [self.view addSubview:mapView];
    self.mapView = mapView;

    UILabel *noMapLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
    noMapLabel.font = [UIFont systemFontOfSize:kEmptyListLabelFontSize];
    noMapLabel.numberOfLines = 0;
    noMapLabel.textAlignment = NSTextAlignmentCenter;
    noMapLabel.textColor = [UIColor noItemsTextColor];
    noMapLabel.hidden = YES;
    noMapLabel.text = NSLocalizedString(@"map.no.location.data", @"No Location Data");
    noMapLabel.insetTop = -(self.view.frame.size.height / 3.0);
    noMapLabel.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    [self.view addSubview:noMapLabel];
    self.noMapLabel = noMapLabel;
    
    [self updateMapView];
}

- (void)setAccessibilityIdentifiers
{
    self.view.accessibilityIdentifier = kMapVCViewIdentifier;
}

- (void)updateMapView
{
    if (self.mapView.annotations.count > 0)
    {
        [self.mapView removeAnnotations:self.mapView.annotations];
    }
    
    BOOL locationAvailable = [self.document hasAspectWithName:kAlfrescoModelAspectGeographic];

    if (self.delegate && [self.delegate respondsToSelector:@selector(mapViewController:didUpdateLocationAvailability:)])
    {
        [self.delegate mapViewController:self didUpdateLocationAvailability:locationAvailable];
    }

    if (locationAvailable)
    {
        self.mapView.hidden = NO;
        self.noMapLabel.hidden = YES;
        
        [self.mapView addAnnotation:self.document];
        if (CLLocationCoordinate2DIsValid(self.document.coordinate))
        {
            [self.mapView setCenterCoordinate:self.document.coordinate animated:NO];
        }
    }
    else
    {
        self.noMapLabel.hidden = NO;
        self.mapView.hidden = YES;
    }
}

#pragma mark - NodeUpdatable Protocol

- (void)updateToAlfrescoDocument:(AlfrescoDocument *)node permissions:(AlfrescoPermissions *)permissions contentFilePath:(NSString *)contentFilePath documentLocation:(InAppDocumentLocation)documentLocation session:(id<AlfrescoSession>)session
{
    _document = node;
    _session = session;

    [self updateMapView];
}

@end

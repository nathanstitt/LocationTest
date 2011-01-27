//
//  LocationTestViewController.m
//  LocationTest
//
//  Created by Tom Horn on 11/08/10.
//  Copyright Cognethos Pty Ltd 2010. All rights reserved.
//

#import "LocationTestViewController.h"
#import "LogViewController.h"
#import "LocationTestAppDelegate.h"
#import <MapKit/MapKit.h>
@implementation LocationDelegate

- (id) initWithLabel:(UILabel*)label
{
	resultsLabel = label;
	return [super init];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{	
	resultsLabel.text = [NSString stringWithFormat:@"(%@) %@ Failed to get location %@", ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) ? @"bg" : @"fg" , resultsLabel.tag == 0 ? @"gps:" : @"sig", [error localizedDescription]];

	LocationTestAppDelegate * appDelegate = (LocationTestAppDelegate *)[UIApplication sharedApplication].delegate;
	[appDelegate log:resultsLabel.text];
}

-(NSString*)locationString:(CLLocation *)newLocation {
	NSDateFormatter * formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setTimeStyle:NSDateFormatterMediumStyle];
	return [NSString stringWithFormat:@"(%@) %@ Location %.06f %.06f %@", ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) ? @"bg" : @"fg", resultsLabel.tag == 0 ? @"gps:" : @"sig" , newLocation.coordinate.latitude, newLocation.coordinate.longitude, [formatter stringFromDate:newLocation.timestamp]];
}
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
		
	resultsLabel.text = [ self locationString:newLocation ];
	
	LocationTestAppDelegate * appDelegate = (LocationTestAppDelegate *)[UIApplication sharedApplication].delegate;
	[appDelegate log:resultsLabel.text];
}

- (void)locationManager:(CLLocationManager *)m didEnterRegion:(CLRegion *)region{
	LocationTestAppDelegate * appDelegate = (LocationTestAppDelegate *)[UIApplication sharedApplication].delegate;
	[ appDelegate log: [NSString stringWithFormat:@"Enter %@",[ self locationString:m.location ] ] ];
}

- (void)locationManager:(CLLocationManager *)m didExitRegion:(CLRegion *)region{
	LocationTestAppDelegate * appDelegate = (LocationTestAppDelegate *)[UIApplication sharedApplication].delegate;
	[ appDelegate log: [NSString stringWithFormat:@"Exit  %@", [ self locationString:m.location ] ] ];
}

@end


@implementation LocationTestViewController

@synthesize m_gpsResultsLabel;
@synthesize m_significantResultsLabel;
@synthesize m_significantSwitch;
@synthesize m_gpsSwitch;
@synthesize m_mapSwitch;
@synthesize m_map;
@synthesize significantManager=m_significantManager;

- (void) log:(NSString*)msg andLabel:(UILabel*)label;
{
	LocationTestAppDelegate * appDelegate = (LocationTestAppDelegate *)[UIApplication sharedApplication].delegate;
	[appDelegate log:msg];
	if(label)
		label.text = msg;
}

- (void)viewDidLoad {
		
	m_gpsDelegate = [[LocationDelegate alloc] initWithLabel:m_gpsResultsLabel];
	m_significantDelegate = [[LocationDelegate alloc] initWithLabel:m_significantResultsLabel];	
	m_map.delegate = self;
    [super viewDidLoad];
}

- (void) significantOn
{
	[self log:@"Sig tracking on..." andLabel:m_significantResultsLabel];
	
	[m_significantManager release];
	m_significantManager = [[CLLocationManager alloc] init];
	m_significantManager.delegate = m_significantDelegate;

	[m_significantManager startMonitoringSignificantLocationChanges];
}

- (void) significantOff
{
	[self log:@"Sig tracking off..." andLabel:m_significantResultsLabel];
	[m_significantManager stopMonitoringSignificantLocationChanges];
}

- (void) gpsOn
{
	[self log:@"GPS tracking on..." andLabel:m_gpsResultsLabel];
	
	[m_gpsManager release];
	m_gpsManager = [[CLLocationManager alloc] init];
	m_gpsManager.delegate = m_gpsDelegate;

	[m_gpsManager startUpdatingLocation];
}

- (void) gpsOff
{
	[self log:@"GPS tracking off..." andLabel:m_gpsResultsLabel];
	[m_gpsManager stopUpdatingLocation];
}

-(IBAction) actionGps:(id)sender
{
	if (m_gpsSwitch.on)
		[self gpsOn];
	else
		[self gpsOff];
}

-(IBAction) actionSignificant:(id)sender
{
	if (m_significantSwitch.on)
		[self significantOn];
	else
		[self significantOff];
}

-(void)moveTo:(CLLocationCoordinate2D)coord {
	MKCoordinateRegion region;
	region.center = coord;
	region.span.longitudeDelta = 0.08;
	region.span.latitudeDelta  = 0.08;
	m_map.region = region;
}

-(IBAction) actionMap:(id)sender
{
	[self log:[NSString stringWithFormat:@"map showing location %@", m_mapSwitch.on ? @"on" : @"off"] andLabel:nil];
	m_map.showsUserLocation = m_mapSwitch.on;
	if ( m_mapSwitch.on ){
		[ self moveTo: m_map.userLocation.location.coordinate ];
	}
}


-(IBAction) activateRegion:(id)sender{
	[self log:[NSString stringWithFormat:@"Activate Region - am monitoring %d regions", [ m_significantManager monitoredRegions ].count ] andLabel:nil];
	if (! m_significantManager ){
		[self log:[NSString stringWithFormat:@"Signifigant isn't on, unable to mark region" ] andLabel:nil];
	}
	CLLocationCoordinate2D coord = m_map.userLocation.location.coordinate;
	[ self moveTo: coord ];
	// Create the region and start monitoring it.
	CLRegion* region = [[CLRegion alloc] initCircularRegionWithCenter: coord
                        radius:1000.0f identifier: @"SingleRegionOnly"];
	
	[ m_significantManager startMonitoringForRegion:region desiredAccuracy:10.0f];
 		
	for ( MKCircle *overlay in m_map.overlays ){
		[ m_map removeOverlay: overlay ];
	}
	
	MKCircle *circle = [MKCircle circleWithCenterCoordinate: coord radius:1000.0f];
	[ m_map addOverlay: circle ];
	[ circle release ];
	
	
	[self log:[NSString stringWithFormat:@"Created Region, now montitoring %d regions", [ m_significantManager monitoredRegions ].count ] andLabel:nil];
	
}

-(IBAction) actionLog:(id)sender
{
	LogViewController* pNewController=[[[LogViewController alloc] initWithNibName:@"LogViewController" bundle:nil] autorelease];
	[self presentModalViewController:pNewController animated:YES];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[m_mapSwitch release];
	[m_gpsResultsLabel release];
	[m_significantResultsLabel release];
	[m_significantSwitch release];
	[m_gpsSwitch release];
	[m_map release];
	[m_gpsManager release];
	[m_significantManager release];
	[m_gpsDelegate release];
	[m_significantDelegate release];
    [super dealloc];
}


#pragma MKMapViewDelegate methods

-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay{
	MKCircleView* circleView = [[MKCircleView alloc] initWithOverlay:overlay];
	circleView.strokeColor = [UIColor darkGrayColor];
	circleView.lineWidth = 1.0;
	circleView.fillColor = [UIColor lightGrayColor];
	circleView.alpha= 0.6f;
	return [ circleView autorelease ];
}

@end

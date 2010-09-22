//
//  MementoViewController.m
//  Memento
//
//  Created by Andre Foeken on 5/3/09.
//  Copyright Nedap 2009. All rights reserved.
//

#import "MementoViewController.h"
#import "TouchXML.h"

@implementation MementoViewController

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	responseData = [[NSMutableData alloc] init];
	applications = [[NSArray alloc] init];
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 25.0)];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
}

#define kAccelerationThreshold          2.2

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration 
{   
	if( ![UIApplication sharedApplication].networkActivityIndicatorVisible ) {		
		if (fabsf(acceleration.x) > kAccelerationThreshold || fabsf(acceleration.y) > kAccelerationThreshold || fabsf(acceleration.z) > kAccelerationThreshold) {
			[self getApplicationHealthData];
		}
	}
}

- (void)getApplicationHealthData {	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if( [defaults stringForKey:@"license_key"] && ![[defaults stringForKey:@"license_key"] isEqualToString:@""] ) {
		
		((UIImageView*)[[self view] viewWithTag:2]).image = [UIImage imageNamed:@"background.png"];
		
		NSURL *dataURL = [NSURL URLWithString:@"http://rpm.newrelic.com/accounts.xml?include=application_health"];
		NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:dataURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];	
		[theRequest setValue:[defaults stringForKey:@"license_key"] forHTTPHeaderField:@"x-license-key"];
		[[[NSURLConnection alloc] initWithRequest:theRequest delegate:self] autorelease];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	} else {
		((UIImageView*)[[self view] viewWithTag:2]).image = [UIImage imageNamed:@"background_without_key.png"];
	}
}
	
#pragma mark Connection methods
	
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {	
	[responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;		
	[self showConnectionError];
}

- (void)showConnectionError {
	UIAlertView *errorAlert = [[UIAlertView alloc] 
							   initWithTitle: @"New Relic RPM"
							   message: @"Please check your license key and API access settings!"
							   delegate:nil 
							   cancelButtonTitle:@"OK" 
							   otherButtonTitles:nil]; 
	
	[errorAlert show];
	[errorAlert release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	NSString *responseXML = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];

	if( [responseXML rangeOfString:@"Access denied"].location != NSNotFound || 
	    [responseXML rangeOfString:@"Unable to authenticate license key"].location != NSNotFound ||
 	    [responseXML rangeOfString:@"This account does not allow api access"].location != NSNotFound ) {
		[self showConnectionError];
	} else {			
		CXMLDocument *response = [[CXMLDocument alloc] initWithXMLString:responseXML options:0 error:NULL];	
		
		[applications release];
		applications = [[response nodesForXPath:@"//accounts//account//applications//application" error:NULL] retain];
			
		UITableView *statusTableView = (UITableView*)[self.view viewWithTag:1];
		[statusTableView reloadData];	
	}
}
	
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [applications count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 77.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {	
	static NSString *CellIdentifier = @"DefaultCell"; 
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier]; 
	if (cell == nil) { 
		[[NSBundle mainBundle] loadNibNamed:@"DefaultCell" owner:self options:nil]; 
		cell = defaultCell;			
		
		//TODO: when iPhone 3.0 is out, replace image with this code
		//cell.imageView.image = [UIImage imageNamed:@"table_view_background.png"];				
	}
		
	CXMLElement *applicationElement = (CXMLElement*)[applications objectAtIndex:indexPath.row];
	CXMLElement *applicationNameElement = (CXMLElement*)[[applicationElement nodesForXPath:@"name" error:NULL] objectAtIndex:0];	
	
	// 1. App. Name
	// 2. Apdex
	// 3. CPU
	// 4. DB
	// 5. Throughput
	// 6. Response
	// 7. Errors (opt)
	// 8. Busy (opt)
		
	UILabel *applicationNameLabel = (UILabel*)[cell viewWithTag:1];	
	applicationNameLabel.text = applicationNameElement.stringValue;
	
	CXMLElement *apdexElement = (CXMLElement*)[[applicationElement nodesForXPath:@"threshold-values/threshold_value[@name='Apdex']" error:NULL] objectAtIndex:0];	
	((UIImageView*)[cell viewWithTag:2]).image = [self imageForThreshold:[apdexElement attributeForName:@"threshold_value"].stringValue];

	CXMLElement *cpuElement = (CXMLElement*)[[applicationElement nodesForXPath:@"threshold-values/threshold_value[@name='CPU']" error:NULL] objectAtIndex:0];	
	((UIImageView*)[cell viewWithTag:3]).image = [self imageForThreshold:[cpuElement attributeForName:@"threshold_value"].stringValue];

	CXMLElement *dbElement = (CXMLElement*)[[applicationElement nodesForXPath:@"threshold-values/threshold_value[@name='DB']" error:NULL] objectAtIndex:0];	
	((UIImageView*)[cell viewWithTag:4]).image = [self imageForThreshold:[dbElement attributeForName:@"threshold_value"].stringValue];
	
	CXMLElement *throughputElement = (CXMLElement*)[[applicationElement nodesForXPath:@"threshold-values/threshold_value[@name='Throughput']" error:NULL] objectAtIndex:0];	
	((UIImageView*)[cell viewWithTag:5]).image = [self imageForThreshold:[throughputElement attributeForName:@"threshold_value"].stringValue];
	
	CXMLElement *responseElement = (CXMLElement*)[[applicationElement nodesForXPath:@"threshold-values/threshold_value[@name='Response Time']" error:NULL] objectAtIndex:0];	
	((UIImageView*)[cell viewWithTag:6]).image = [self imageForThreshold:[responseElement attributeForName:@"threshold_value"].stringValue];
	
	NSArray *errorsNodes = [applicationElement nodesForXPath:@"threshold-values/threshold_value[@name='Errors']" error:NULL];
	NSArray *busyNodes   = [applicationElement nodesForXPath:@"threshold-values/threshold_value[@name='Application Busy']" error:NULL];
	
	if( errorsNodes.count > 0 ) {
		CXMLElement *errorsElement = (CXMLElement*)[errorsNodes objectAtIndex:0];	
		((UIImageView*)[cell viewWithTag:7]).image = [self imageForThreshold:[errorsElement attributeForName:@"threshold_value"].stringValue];
	}
			
	if( busyNodes.count > 0 ) {
		CXMLElement *busyElement = (CXMLElement*)[busyNodes objectAtIndex:0];
		((UIImageView*)[cell viewWithTag:8]).image = [self imageForThreshold:[busyElement attributeForName:@"threshold_value"].stringValue];
	}
	
	return cell; 	
}

- (UIImage*) imageForThreshold:(NSString*)threshold {
	switch ([threshold intValue]) {
		case 0:
			return [UIImage imageNamed:@"grey.png"];		
		case 1:
			return [UIImage imageNamed:@"green.png"];		
		case 2:
			return [UIImage imageNamed:@"orange.png"];		
		case 3:
			return [UIImage imageNamed:@"red.png"];		
		default:
			return [UIImage imageNamed:@"green.png"];
	}
}

- (void)dealloc {
    [super dealloc];
}

@end

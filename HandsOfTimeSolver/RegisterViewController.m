//
//  RegisterViewController.m
//  HandsOfTimeSolver
//
//  Created by Corey Roberts on 4/5/12.
//  Copyright (c) 2012 University of Texas at Austin. All rights reserved.
//

#import "RegisterViewController.h"
#import "RegexKitLite.h"
#import "AppDelegate.h"
#import "GANTracker.h"

@interface RegisterViewController ()

@end

@implementation RegisterViewController

@synthesize username, backgroundButton, registerButton, received_data, indicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)createBackground {
    //Create the gradient and add it to our view's root layer
    UIColor *colorOne = [UIColor colorWithRed:0.0 green:0.125 blue:0.18 alpha:1.0];
    UIColor *colorTwo = [UIColor colorWithRed:0.0 green:0.00 blue:0.05 alpha:1.0];
    CAGradientLayer *gradientLayer = [[[CAGradientLayer alloc] init] autorelease];
    gradientLayer.frame = CGRectMake(0.0, 0.0, 320.0, 480.0);
    [gradientLayer setColors:[NSArray arrayWithObjects:(id)colorOne.CGColor, (id)colorTwo.CGColor, nil]];
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [[GANTracker sharedTracker] trackPageview:@"Registration (RegisterViewController)" withError:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createBackground];
    self.indicator.alpha = 0.0f;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)backgroundButtonPressed:(id)sender {
    [username resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self registerButtonPressed:nil];
    return YES;
}

- (void)hideIndicator {
    if(self.indicator.alpha > 0.0f){
        float delay = 0.5f;
        [UIView beginAnimations:@"hideIndicator" context:NULL];
        [UIView setAnimationDelay:delay];
        [UIView setAnimationDuration:delay];
        self.indicator.alpha = 0.0f;
        [UIView commitAnimations];
    }
}

- (void)displayIndicator {
    float delay = 0.5f;
    [UIView beginAnimations:@"displayIndicator" context:NULL];
    [UIView setAnimationDuration:delay];
    self.indicator.alpha = 1.0f;
    [UIView commitAnimations];
}

- (IBAction)registerButtonPressed:(id)sender {
    if([username.text length] == 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                        message:@"Please enter a username."  
                                                       delegate:nil 
                                              cancelButtonTitle:@"Okay." 
                                              otherButtonTitles:nil, nil];
        [alert show];
        [alert release]; 
    }
    //check if username has any bad symbols
    else if([username.text isMatchedByRegex:@"[^a-zA-Z0-9]"]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                        message:@"Your username contains invalid characters. Please only use alphanumeric characters."  
                                                       delegate:nil 
                                              cancelButtonTitle:@"Okay." 
                                              otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    }
    else {
        [self sendUsername];
    }
}

- (void)sendUsername {
    [self performSelectorOnMainThread:@selector(displayIndicator) withObject:nil waitUntilDone:YES];
    NSString *API_Call = [NSString stringWithFormat:@"http://ffxiii-2.texasdrums.com/api/v1/add_user.php?username=%@", username.text];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:API_Call] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    NSURLConnection *urlconnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    if(urlconnection) {
        received_data = [[NSMutableData data] retain];
    }
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
    
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    [received_data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to received_data.
    [received_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [connection release];
    [received_data release];
    
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" 
                                                    message:[error localizedDescription] 
                                                   delegate:self 
                                          cancelButtonTitle:@":( Okay" 
                                          otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *data = [[[NSString alloc] initWithData:received_data encoding:NSUTF8StringEncoding] autorelease];
    
    if([data isEqualToString:@"200 OK"]){
        NSLog(@"Username accepted.");
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"registered"];
        [defaults setObject:self.username.text forKey:@"username"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" 
                                                        message:@"Your username has been registered. Thanks!"
                                                       delegate:self 
                                              cancelButtonTitle:@"Okay." 
                                              otherButtonTitles:nil, nil];
        
        [alert show];
        [alert release];
    }
    else if([data isEqualToString:@"302 Username Taken"]){
        NSString *message = [NSString stringWithFormat:@"The username '%@' is already taken. Please choose another username.", self.username.text];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" 
                                                        message:message
                                                       delegate:nil 
                                              cancelButtonTitle:@"Okay." 
                                              otherButtonTitles:nil, nil];
        
        [alert show];
        [alert release];
    }
    
    [self hideIndicator];
    
    NSLog(@"Succeeded! Received %d bytes of data", [received_data length]);
    
    // release the connection, and the data object
    [connection release];
    [received_data release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate popModalView];
}

@end

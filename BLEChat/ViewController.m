//
//  ViewController.m
//  BLEChat
//
//  Created by Cheong on 15/8/12.
//  Modified by Eric Larson, 2014
//  Copyright (c) 2012 RedBear Lab., All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *shieldNameLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

@property (weak, nonatomic) IBOutlet UILabel *ButtonLabel;
@property (weak, nonatomic) IBOutlet UISlider *ledBrightness;
@property (weak, nonatomic) IBOutlet UISwitch *ledToggle;
@property (weak, nonatomic) IBOutlet UILabel *ledBrightnessLabel;

@end

@implementation ViewController

-(BLE*)bleShield
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate.bleShield;
}

// CHANGE 3: Add support for lazy instantiation (like we did in the table view controller)

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.ledBrightness.enabled = NO;
    [self.ledBrightness setContinuous:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBLEDidConnect:) name:kBleConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBLEDidDisconnect:) name:kBleDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBLEDidUpdateRSSI:) name:kBleRSSINotification object:nil];
    
    // this example function "onBLEDidReceiveData:" is done for you, see below
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (onBLEDidReceiveData:) name:kBleReceivedDataNotification object:nil];
    
}

//setup auto rotation in code
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - RSSI timer
NSTimer *rssiTimer;
-(void) readRSSITimer:(NSTimer *)timer
{
    [self.bleShield readRSSI]; // be sure that the RSSI is up to date
}

#pragma mark - BLEdelegate protocol methods
-(void) bleDidUpdateRSSI:(NSNumber *)rssi
{
    self.labelRSSI.text = rssi.stringValue; // when RSSI read is complete, display it
}



// NEW FUNCTION EXAMPLE: parse the received data from NSNotification
-(void) onBLEDidReceiveData:(NSNotification *)notification
{
    NSData* d = [[notification userInfo] objectForKey:@"data"];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
   
    dispatch_async(dispatch_get_main_queue(), ^(){
        NSLog(@"%@", s);
    });
    
    NSString *opCode = [s substringToIndex:1];
    
    if([opCode isEqualToString:@"1"]){
        [self flex: [s substringFromIndex: 1]];
    }
}


-(void) onBLEDidConnect:(NSNotification *)notification
{
    NSString* d = [[notification userInfo] objectForKey:@"deviceName"];
    self.shieldNameLabel.text = d;
}

-(void) onBLEDidDisconnect:(NSNotification *)notification
{
    [[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)brightnessChanged:(id)sender {
    NSString* s = [NSString stringWithFormat:@"0%.0f\n", self.ledBrightness.value];
    
    [self BLEShieldSend: s];
    
    dispatch_async(dispatch_get_main_queue(), ^{

        self.ledBrightnessLabel.text = [NSString stringWithFormat:@"Brightness: %.0f", self.ledBrightness.value];
    });
}
- (IBAction)ledToggle:(id)sender {
    //Opcode for LED == 0
    NSString* s;
    if([self.ledToggle isOn]) {
        s = @"0" @"on";
        self.ledBrightness.enabled = YES;
    }
    else {
        s = @"0" @"off";
        self.ledBrightness.value = 180;
        self.ledBrightness.enabled = NO;
    }
    [self BLEShieldSend:s];
}


#pragma mark - UI operations storyboard
- (void)BLEShieldSend:(NSString*) sendValue
{
    
    //Note: this function only needs a name change, the BLE writing does not change
    NSString *s;
    NSData *d;
    

    s = [NSString stringWithFormat:@"%@", sendValue ];
    d = [s dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.bleShield write:d];
}

-(void)flex:(NSString*) flexValue
{
    if([flexValue isEqualToString:@"0"]){
        NSLog(@"Flat");
        self.ButtonLabel.text = @"Flat";    //TODO: use main queue
    }
    else if([flexValue isEqualToString:@"1"]){
        NSLog(@"Up");
        self.ButtonLabel.text = @"Up";
        self.progressBar.progress = self.progressBar.progress+.1;
        
    }
    else if([flexValue isEqualToString:@"2"]){
        NSLog(@"Down");
        self.ButtonLabel.text = @"Down";
        self.progressBar.progress = self.progressBar.progress-.1;
    }
}


@end

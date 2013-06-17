//
//  ForgotPasswordViewController.m
//  NCAssistance
//
//  Created by Yuyi Zhang on 6/16/13.
//  Copyright (c) 2013 Camel. All rights reserved.
//

#import "ForgotPasswordViewController.h"
#import "Password.h"
#import "Constants.h"

@interface ForgotPasswordViewController ()

@property (nonatomic, retain) Password * thePassword;
@property (nonatomic,assign) NSInteger failedLogins;
@property (nonatomic,retain) NSDate *lastFailedDate;

@end

@implementation ForgotPasswordViewController

@synthesize failedLogins;
@synthesize lastFailedDate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.thePassword) {
        self.thePassword = [self.delegate retriveRecord];
    }
    self.question.text = self.thePassword.website;
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fileDir = [documentsDirectory stringByAppendingPathComponent:strAttemptsFileName];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:fileDir]) {
        NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfFile:fileDir] mutableCopy];
        self.failedLogins = [[dict objectForKey:strSecurityAttemptCtr] intValue];
        self.lastFailedDate = [dict objectForKey:strSeciurityLstFailedDt];
        
        if (self.failedLogins > 10) {
            // file has sth wrong. Probably being hacked...
            self.failedLogins = 10;
        }
    }
    else {
        self.failedLogins = 10;
        self.lastFailedDate = [NSDate date];
    }
    
    if (!self.lastFailedDate) {
        self.lastFailedDate = [NSDate date];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self saveAttempts];
    self.lastFailedDate = nil;
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)unlock:(id)sender {
    if (self.failedLogins > 0 && self.failedLogins <= 10) {
        if ([self.answerIn.text isEqualToString:self.thePassword.notes]) {
            [self setFailedLogins:10];
            [self dismissViewControllerAnimated:YES completion:nil];
            [NSTimer scheduledTimerWithTimeInterval:0.5 target:self.delegate selector:@selector(dismissLockView) userInfo:nil repeats:NO];
            return;
        }
        else {
            self.failedLogins--;
            self.lastFailedDate = [NSDate date];
            self.descTxt.text = [@"Wrong anwser. " stringByAppendingString:[[[NSNumber numberWithInteger: self.failedLogins] stringValue] stringByAppendingString:@" Attempts Left."]];
        }
    }
    else {
        static NSDateFormatter *dateFormatter = nil;
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        }
    
        // calculate how many hours past since lastFailedDate
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [cal components:( NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:self.lastFailedDate toDate:[NSDate date] options:0];
        int iHrPast = 24 - [components hour];

        if (iHrPast <= 0) {
            if ([self.answerIn.text isEqualToString:self.thePassword.notes]) {
                [self setFailedLogins:10];
                [self dismissViewControllerAnimated:YES completion:nil];
                [self saveAttempts];
                return;
            }
            else {     // another failed attempt
                iHrPast = 24;
                self.lastFailedDate = [NSDate date];
            }
        }
    
        self.descTxt.text = [@"Wrong answer. Wait " stringByAppendingString:[[[NSNumber numberWithInteger:iHrPast] stringValue] stringByAppendingString:@" Hours to try again."]];
    }

    [self saveAttempts];
}

-(void)saveAttempts
{
    // save failedLogins to disk
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fileDir = [documentsDirectory stringByAppendingPathComponent:strAttemptsFileName];
    NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfFile:fileDir] mutableCopy];
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
        [dict setValue:[NSNumber numberWithInt: 10] forKey:strLoginAttemptCtr];
    }
    
    int lockCtr = [[dict objectForKey:strLoginAttemptCtr] intValue];
    NSDate *lockDt = [dict objectForKey:strLoginLstFailedDt];
    if (!lockDt) {
        lockDt = [NSDate date];
    }
    
    [dict setValue:[NSNumber numberWithInt: lockCtr] forKey:strLoginAttemptCtr];
    [dict setValue:lockDt forKey:strLoginLstFailedDt];
    [dict setValue:[NSNumber numberWithInt: self.failedLogins] forKey:strSecurityAttemptCtr];
    [dict setValue:self.lastFailedDate forKey:strSeciurityLstFailedDt];
    
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:strAttemptsFileName];
    if (![dict writeToFile:filePath atomically:YES]) {
        NSLog(@"Saving login attempts failed!");
    }
}

#pragma mark - textfield delegate
-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.answerIn) {
        [textField resignFirstResponder];
    }
    return YES;
}

@end

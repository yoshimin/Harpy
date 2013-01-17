//
//  Harpy.m
//  Harpy
//
//  Created by Arthur Ariel Sabintsev on 11/14/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "Harpy.h"

#define kHarpyCurrentVersion [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey]
#define kSecondsInOneDay 86400

@interface Harpy ()

+ (void)showAlertWithAppStoreVersion:(NSString*)appStoreVersion;

@end

@implementation Harpy

// Public Methods
+ (void)checkVersion
{
    NSTimeInterval timeToWaitBeforeAlertingUser = kDaysToWaitBeforeAlertingUser * kSecondsInOneDay;
    BOOL shouldCheckVersion = [self buildDateWasLongerAgoThanTimeInterval:timeToWaitBeforeAlertingUser];
    
    if (shouldCheckVersion == NO) return;

    // Asynchronously query iTunes AppStore for publically available version
    NSString *storeString = [NSString stringWithFormat:@"http://itunes.apple.com/lookup?id=%@", appID];
    NSURL *storeURL = [NSURL URLWithString:storeString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:storeURL];
    [request setHTTPMethod:@"GET"];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
       
        if ( [data length] > 0 && !error ) { // Success
            
            NSDictionary *appData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                
                // All versions that have been uploaded to the AppStore
                NSArray *versionsInAppStore = [[appData valueForKey:@"results"] valueForKey:@"version"];
                
                if ( ![versionsInAppStore count] ) { // No versions of app in AppStore
                    
                    return;
                    
                } else {

                    NSString *currentAppStoreVersion = [versionsInAppStore objectAtIndex:0];

                    if ( [kHarpyCurrentVersion isEqualToString:currentAppStoreVersion] ) {
            
                        // Current installed version is the newest public version
                
                    } else {
                    
                        [Harpy showAlertWithAppStoreVersion:currentAppStoreVersion];
                    
                    }
                }
              
            });
        }
        
    }];
}

// Private Methods
+ (BOOL)buildDateWasLongerAgoThanTimeInterval:(NSTimeInterval)interval {
    
    // Get the build date (__DATE__) into an NSDate object
    NSString *compileDateString = [NSString stringWithUTF8String:__DATE__];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *buildLocale = [[NSLocale alloc] initWithLocaleIdentifier:kCurrentLocale];

    dateFormatter.dateFormat = @"MMM d yyyy";
    dateFormatter.locale = buildLocale;

    [dateFormatter setLocale:buildLocale];
    
    NSDate *buildDate = [dateFormatter dateFromString:compileDateString];
    
    // Get the current day at midnight into an NSDate object
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSUInteger preservedComponents = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit);
    today = [calendar dateFromComponents:[calendar components:preservedComponents fromDate:today]];

    // Compare them
    NSTimeInterval timeSinceBuildDate = [today timeIntervalSinceDate:buildDate];
    
    return (timeSinceBuildDate >= interval);
}

+ (void)showAlertWithAppStoreVersion:(NSString *)currentAppStoreVersion
{
 
    // App name
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    
    if ( forceUpdate ) { // Force user to update app
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Update Available"
                                                            message:[NSString stringWithFormat:@"A new version of %@ is available. Please update to version %@ now.", appName, currentAppStoreVersion]
                                                           delegate:self
                                                  cancelButtonTitle:@"Update"
                                                  otherButtonTitles:nil, nil];
        
        [alertView show];
        
    } else { // Allow user option to update next time user launches your app

        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Update Available"
                                                            message:[NSString stringWithFormat:@"A new version of %@ is available. Please update to version %@.", appName, currentAppStoreVersion]
                                                           delegate:self
                                                  cancelButtonTitle:@"Not now"
                                                  otherButtonTitles:@"Update", nil];
        
        [alertView show];
        
    }

}

#pragma mark - UIAlertViewDelegate Methods
+ (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if ( forceUpdate ) {

        NSString *iTunesString = [NSString stringWithFormat:@"https://itunes.apple.com/app/id%@", appID];
        NSURL *iTunesURL = [NSURL URLWithString:iTunesString];
        [[UIApplication sharedApplication] openURL:iTunesURL];
        
    } else {

        switch (buttonIndex) {
                
            case 0:{ // Cancel / Not now
        
                // Do nothing
                
            } break;
                
            case 1:{ // Update
                
                NSString *iTunesString = [NSString stringWithFormat:@"https://itunes.apple.com/app/id%@", appID];
                NSURL *iTunesURL = [NSURL URLWithString:iTunesString];
                [[UIApplication sharedApplication] openURL:iTunesURL];
                
            } break;
                
            default:
                break;
        }
        
    }

    
}

@end
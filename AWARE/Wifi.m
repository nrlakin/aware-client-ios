//
//  Wifi.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Wifi.h"



@implementation Wifi{
//    NSTimer * uploadTimer;
    NSTimer * sensingTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    if (self) {
    }
    return self;
}


- (void) createTable{
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "bssid text default '',"
    "ssid text default '',"
    "security text default '',"
    "frequency integer default 0,"
    "rssi integer default 0,"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    // Send a create table query
    NSLog(@"[%@] Create Table", [self getSensorName]);
    [self createTable];
    
    // Get a sensing frequency
    double frequency = [self getSensorSetting:settings withKey:@"frequency_wifi"];
    if(frequency != -1){
        NSLog(@"Wi-Fi sensing requency is %f ", frequency);
    }else{
        frequency = 60.0f;
    }
    
    // Set a buffer size for reducing file access
//    [self setBufferSize:10];
    
    // Set and start a data uploader with an interval
//    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                                   target:self
//                                                 selector:@selector(syncAwareDB)
//                                                 userInfo:nil
//                                                  repeats:YES];
    
    // Set and start a data upload interval
    NSLog(@"[%@] Start Wifi Sensor", [self getSensorName]);
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:frequency
                                                    target:self
                                                  selector:@selector(getWifiInfo)
                                                  userInfo:nil
                                                   repeats:YES];
    
    return YES;
}


- (BOOL)stopSensor{
    // Stop a sensing timer
    if (sensingTimer != nil) {
        [sensingTimer invalidate];
        sensingTimer = nil;
    }
    // Stop a sync timer
//    if (uploadTimer != nil) {
//        [uploadTimer invalidate];
//        uploadTimer = nil;
//    }
    return YES;
}

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////


- (void) getWifiInfo {
    // Get wifi information
    //http://www.heapoverflow.me/question-how-to-get-wifi-ssid-in-ios9-after-captivenetwork-is-depracted-and-calls-for-wif-31555640

    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
//        NSLog(@"info:%@",info);
        NSString *bssid = @"";
        NSString *ssid = @"";
        
        if (info[@"BSSID"]) {
            bssid = info[@"BSSID"];
        }
        if(info[@"SSID"]){
            ssid = info[@"SSID"];
        }
        
        NSMutableString *finalBSSID = [[NSMutableString alloc] init];
        NSArray *arrayOfBssid = [bssid componentsSeparatedByString:@":"];
        for(int i=0; i<arrayOfBssid.count; i++){
            NSString *element = [arrayOfBssid objectAtIndex:i];
            if(element.length == 1){
                [finalBSSID appendString:[NSString stringWithFormat:@"0%@:",element]];
            }else if(element.length == 2){
                [finalBSSID appendString:[NSString stringWithFormat:@"%@:",element]];
            }else{
                //            NSLog(@"error");
            }
        }
        if (finalBSSID.length > 0) {
            //        NSLog(@"%@",finalBSSID);
            [finalBSSID deleteCharactersInRange:NSMakeRange([finalBSSID length]-1, 1)];
        } else{
            //        NSLog(@"error");
        }
        
        // Save sensor data to the local database.
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:finalBSSID forKey:@"bssid"]; //text
        [dic setObject:ssid forKey:@"ssid"]; //text
        [dic setObject:@"" forKey:@"security"]; //text
        [dic setObject:@0 forKey:@"frequency"];//int
        [dic setObject:@0 forKey:@"rssi"]; //int
        [dic setObject:@"" forKey:@"label"]; //text
        [self setLatestValue:[NSString stringWithFormat:@"%@ (%@)",ssid, finalBSSID]];
        [self saveData:dic toLocalFile:SENSOR_WIFI];
    }
    
    //    NSArray * networkInterfaces = [NEHotspotHelper supportedNetworkInterfaces];
    //    NSLog(@"Networks %@",networkInterfaces);
    //    for(NEHotspotNetwork *hotspotNetwork in [NEHotspotHelper supportedNetworkInterfaces]) {
    //        NSString *ssid = hotspotNetwork.SSID;
    //        NSString *bssid = hotspotNetwork.BSSID;
    //        BOOL secure = hotspotNetwork.secure;
    //        BOOL autoJoined = hotspotNetwork.autoJoined;
    //        double signalStrength = hotspotNetwork.signalStrength;
    //    }
    
    //    CFArrayRef myArray = CNCopySupportedInterfaces();
    //    CFDictionaryRef captiveNetWork = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
    //    NSLog(@"Connected at : %@", captiveNetWork);
    //    NSDictionary *myDictionnary = (__bridge NSDictionary *)captiveNetWork;
    //    NSString *bssid = [myDictionnary objectForKey:@"BSSID"];
    //    NSLog(@"BSSID : %@", bssid);
}




@end

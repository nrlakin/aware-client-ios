//
//  WeatherData.m
//  VQR
//
//  Created by Yuuki Nishiyama on 2014/12/02.
//  Copyright (c) 2014年 tetujin. All rights reserved.
//

#import "OpenWeather.h"
#import "AWAREKeys.h"
#import "AppDelegate.h"
#import "EntityOpenWeather.h"

@implementation OpenWeather{
    IBOutlet CLLocationManager *locationManager;
//    NSTimer* syncTimer;
    NSTimer* sensingTimer;
    NSDictionary* jsonWeatherData;
    NSDate* thisDate;
    double thisLat;
    double thisLon;
    NSString* identificationForOpenWeather;
    NSString * userApiKey;
}
/** api */
NSString* OPEN_WEATHER_API_URL = @"http://api.openweathermap.org/data/2.5/weather?lat=%d&lon=%d&APPID=%@";
NSString* OPEN_WEATHER_API_DEFAULT_KEY = @"54e5dee2e6a2479e0cc963cf20f233cc";
/** sys */
NSString* KEY_SYS         = @"sys";
NSString* ELE_COUNTORY    = @"country";
NSString* ELE_SUNSET      = @"sunset";
NSString* ELE_SUNRISE      = @"sunrise";

/** weather */
NSString* KEY_WEATHER     = @"weather";
NSString* ELE_MAIN        = @"main";
NSString* ELE_DESCRIPTION = @"description";
NSString* ELE_ICON        = @"icon";

/** main */
NSString* KEY_MAIN        = @"main";
NSString* ELE_TEMP        = @"temp";
NSString* ELE_TEMP_MAX    = @"temp_max";
NSString* ELE_TEMP_MIN    = @"temp_min";
NSString* ELE_HUMIDITY    = @"humidity";
NSString* ELE_PRESSURE    = @"pressure";
/** wind */
NSString* KEY_WIND        = @"wind";
NSString* ELE_SPEED       = @"speed";
NSString* ELE_DEG         = @"deg";
/** rain */
NSString* KEY_RAIN        = @"rain";
NSString* KEY_SNOW        = @"snow";
NSString* ELE_3H          = @"3h";
/** clouds */
NSString* KEY_CLOUDS      = @"clouds";
NSString* ELE_ALL         = @"all";
/** city */
NSString* KEY_NAME        = @"name";

NSString* ZERO            = @"0";
    
int ONE_HOUR = 60*60;


- (instancetype) initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_OPEN_WEATHER
                        dbEntityName:NSStringFromClass([EntityOpenWeather class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        locationManager = nil;
        identificationForOpenWeather = @"http_for_open_weather_";
        [self updateWeatherData:[NSDate new] Lat:0 Lon:0];
        userApiKey = nil;
    }
    return self;
}


- (void) createTable{
    NSLog(@"Start Open Weather Map");
    NSString *query = [[NSString alloc] init];
    query =
    @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "city text default '',"
    "temperature real default 0,"
    "temperature_max real default 0,"
    "temperature_min real default 0,"
    "unit text default '',"
    "humidity real default 0,"
    "pressure real default 0,"
    "wind_speed real default 0,"
    "wind_degrees real default 0,"
    "cloudiness real default 0,"
    "weather_icon_id int default 0,"
    "weather_description text default '',"
    "rain real default 0,"
    "snow real default 0,"
    "sunrise real default 0,"
    "sunset real default 0,"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    double frequencyMin = [self getSensorSetting:settings withKey:@"plugin_openweather_frequency"];
    double frequencySec = 60.0f * frequencyMin;
    if (frequencyMin == -1) {
        frequencySec = 60.0f*15.0f;
    }
    
//    NSString * apiKey = nil;
    if (settings != nil) {
        for (NSDictionary * setting in settings) {
            if ([[setting objectForKey:@"setting"] isEqualToString:@"api_key_plugin_openweather"]) {
                userApiKey = [setting objectForKey:@"value"];
            }
        }
    }
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    AWARECore * core = delegate.sharedAWARECore;
    locationManager = core.sharedLocationManager;
    
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:frequencySec
                                                    target:self
                                                  selector:@selector(getNewWeatherData)
                                                  userInfo:nil
                                                   repeats:YES];
    [self getNewWeatherData];
    return YES;
}

- (BOOL)stopSensor{
    // stop a sensing timer
    [sensingTimer invalidate];
    sensingTimer = nil;
    
    return YES;
}

- (BOOL)syncAwareDBInForeground{
    return [super syncAwareDBInForeground];
}

- (BOOL) isUploading{
    // NSLog(@"%d %@", [super isUploading], [self getEntityName]);
    return [super isUploading];
}

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////



- (void) getNewWeatherData {
    if (locationManager != nil) {
        CLLocation* location = [locationManager location];
        NSDate *now = [NSDate new];
        [self updateWeatherData:now
                            Lat:location.coordinate.latitude
                            Lon:location.coordinate.longitude];
    }
}

- (void)updateWeatherData:(NSDate *)date Lat:(double)lat Lon:(double)lon
{
    thisDate = date;
    thisLat = lat;
    thisLon = lon;
    if( lat !=0  &&  lon != 0){
        [self getWeatherJSONStr:lat lon:lon];
    }
}

- (void) getWeatherJSONStr:(double)lat
                             lon:(double)lon{
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    NSString *postLength = nil;
    
    // Set settion configu and HTTP/POST body.
    NSURLSessionConfiguration *sessionConfig = nil;
    
    identificationForOpenWeather = [NSString stringWithFormat:@"%@%f", identificationForOpenWeather, [[NSDate new] timeIntervalSince1970]];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identificationForOpenWeather];
    sessionConfig.timeoutIntervalForRequest = 180.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60;
    sessionConfig.allowsCellularAccess = YES;
    sessionConfig.discretionary = YES;
    
    NSString *url = @"";
    if(userApiKey == nil){
        url = [NSString stringWithFormat:OPEN_WEATHER_API_URL, (int)lat, (int)lon, OPEN_WEATHER_API_DEFAULT_KEY];
    }else{
        url = [NSString stringWithFormat:OPEN_WEATHER_API_URL, (int)lat, (int)lon, userApiKey];
    }

    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    // set HTTP/POST body information
    if([self isDebug]){
        NSLog(@"--- [%@] This is background task ----", [self getSensorName] );
    }
    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];

}



- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    if (responseCode == 200) {
        if([self isDebug]){
            NSLog(@"[%@] Got Weather Information from API!", [self getSensorName]);
        }
    }

    [super URLSession:session
             dataTask:dataTask
   didReceiveResponse:response
    completionHandler:completionHandler];
    
//    [session finishTasksAndInvalidate];
//    [session invalidateAndCancel];
//    completionHandler(NSURLSessionResponseAllow);
}


-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    if(data != nil){
        NSError *e = nil;
        jsonWeatherData = [NSJSONSerialization JSONObjectWithData:data
                                                          options:NSJSONReadingAllowFragments
                                                            error:&e];
        
        if ( jsonWeatherData == nil) {
            if ([self isDebug]) {
                NSLog( @"%@", e.debugDescription );
                [self sendLocalNotificationForMessage:e.debugDescription soundFlag:NO];
            }
            return;
        };
        
        if ([self isDebug]) {
            [self sendLocalNotificationForMessage:@"Get Weather Information" soundFlag:NO];
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            EntityOpenWeather * weatherData = (EntityOpenWeather *)[NSEntityDescription insertNewObjectForEntityForName:[self getEntityName]
                                                                                                   inManagedObjectContext:delegate.managedObjectContext];
            
            weatherData.device_id = [self getDeviceId];
            weatherData.timestamp = [AWAREUtils getUnixTimestamp:[NSDate new]];
            weatherData.city = [self getName];
            weatherData.temperature = [self getTemp];
            weatherData.temperature_max = [self getTempMax];
            weatherData.temperature_min = [self getTempMin];
            weatherData.unit = @"";
            weatherData.humidity = [self getHumidity];
            weatherData.pressure = [self getPressure];
            weatherData.wind_speed = [self getWindSpeed];
            weatherData.wind_degrees = [self getWindDeg];
            weatherData.cloudiness = [self getClouds];
            weatherData.weather_icon_id = [self getWeatherIcon];
            weatherData.weather_description = [self getWeatherDescription];
            weatherData.rain = [self getRain];
            weatherData.snow = [self getSnow];
            weatherData.sunrise = [self getSunRise];
            weatherData.sunset = [self getSunSet];
            
            [self saveDataToDB];
        });

//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[self getName] forKey:@"city"];
//        [dic setObject:[self getTemp] forKey:@"temperature"];
//        [dic setObject:[self getTempMax] forKey:@"temperature_max"];
//        [dic setObject:[self getTempMax] forKey:@"temperature_min"];
//        [dic setObject:@"" forKey:@"unit"];
//        [dic setObject:[self getHumidity] forKey:@"humidity"];
//        [dic setObject:[self getPressure] forKey:@"pressure"];
//        [dic setObject:[self getWindSpeed] forKey:@"wind_speed"];
//        [dic setObject:[self getWindDeg] forKey:@"wind_degrees"];
//        [dic setObject:[self getClouds] forKey:@"cloudiness"];
//        [dic setObject:[self getWeatherIcon] forKey:@"weather_icon_id"];
//        [dic setObject:[self getWeatherDescription] forKey:@"weather_description"];
//        [dic setObject:[self getRain] forKey:@"rain"];
//        [dic setObject:[self getSnow] forKey:@"snow"];
//        [dic setObject:[self getSunRise] forKey:@"sunrise"];
//        [dic setObject:[self getSunSet] forKey:@"sunset"];
    }

//    [session finishTasksAndInvalidate];
//    [session invalidateAndCancel];
    
    [super URLSession:session dataTask:dataTask didReceiveData:data];
}

//
//- (void)URLSession:(NSURLSession *)session
//              task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
//    [session finishTasksAndInvalidate];
//    [session invalidateAndCancel];
//    
//    
//}
//
//- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
//    if (error != nil) {
//        if([self isDebug]){
//            NSLog(@"[%@] the session did become invaild with error: %@", [self getSensorName], error.debugDescription);
//        }
//    }
//    [session invalidateAndCancel];
//    [session finishTasksAndInvalidate];
//}



- (NSString *) getCountry
{
    NSString* value = [[jsonWeatherData valueForKey:KEY_SYS] valueForKey:ELE_COUNTORY];
    if(value != nil){
        return value;
    }else{
        return @"0";
    }
}

- (NSString *) getWeather
{
    NSString *value = [[[jsonWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_MAIN];
    if (value != nil) {
        return value;
    }else{
        return @"0";
    }
}


- (NSNumber *) getWeatherIcon
{
    NSNumber * value  = @0;
    @try {
        if(value != nil){
            value =  @([[[[jsonWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_ICON] integerValue]);
        }
    } @catch (NSException *exception) {
        value = @0;
    }
    return value;
}

- (NSString *) getWeatherDescription
{
    NSString * value= [[[jsonWeatherData valueForKey:KEY_WEATHER] objectAtIndex:0] valueForKey:ELE_DESCRIPTION];
    if(value != nil){
        return  value;
    }else{
        return @"0";
    }
}

- (NSNumber *) getTemp
{
   // NSLog(@"--> %@", [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP]]);
    double temp = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_TEMP] doubleValue];
    return [NSNumber numberWithDouble:temp];
}

- (NSNumber *) getTempMax
{
    double maxTemp = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_TEMP_MAX] doubleValue];
    return [NSNumber numberWithDouble:maxTemp];
//    return [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP_MAX]];
}

- (NSNumber *) getTempMin
{
    double minTemp = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_TEMP_MIN] doubleValue];
    return [NSNumber numberWithDouble:minTemp];
//    return [self convertKelToCel:[[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_TEMP_MIN]];
}

- (NSNumber *) getHumidity
{
    //NSLog(@"--> %@",  [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_HUMIDITY]);
    double humidity = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_HUMIDITY] doubleValue];
    return [NSNumber numberWithDouble:humidity];
//    return [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_HUMIDITY];
}

- (NSNumber *) getPressure
{
    double pressure = [[[jsonWeatherData valueForKey:KEY_MAIN] objectForKey:ELE_PRESSURE] doubleValue];
    return [NSNumber numberWithDouble:pressure];
//    return [[jsonWeatherData valueForKey:KEY_MAIN] valueForKey:ELE_PRESSURE];
}

- (NSNumber *) getWindSpeed
{
    double windSpeed = [[[jsonWeatherData valueForKey:KEY_WIND] objectForKey:ELE_SPEED] doubleValue];
    return [NSNumber numberWithDouble:windSpeed];
//    return [[jsonWeatherData valueForKey:KEY_WIND] valueForKey:ELE_SPEED];
}

- (NSNumber *) getWindDeg
{
    double windDeg = [[[jsonWeatherData valueForKey:KEY_WIND] objectForKey:ELE_DEG] doubleValue];
    return [NSNumber numberWithDouble:windDeg];
//    return [[jsonWeatherData valueForKey:KEY_WIND] valueForKey:ELE_DEG];
}

- (NSNumber *) getRain
{
    double rain =  [[[jsonWeatherData valueForKey:KEY_RAIN] objectForKey:ELE_3H] doubleValue];
    return [NSNumber numberWithDouble:rain];
//    return [[jsonWeatherData valueForKey:KEY_RAIN] valueForKey:ELE_3H];
}

- (NSNumber *) getSnow
{
    double snow =  [[[jsonWeatherData valueForKey:KEY_SNOW] objectForKey:ELE_3H] doubleValue];
    return [NSNumber numberWithDouble:snow];
//    return [[jsonWeatherData valueForKey:KEY_RAIN] valueForKey:ELE_3H];
}

- (NSNumber *) getClouds
{
    double cloudiness = [[[jsonWeatherData valueForKey:KEY_CLOUDS] objectForKey:ELE_ALL] doubleValue];
    return [NSNumber numberWithDouble:cloudiness];
//    return [[jsonWeatherData valueForKey:KEY_CLOUDS] valueForKey:ELE_ALL];
}


- (NSNumber *) getSunRise
{
    double value = [[[jsonWeatherData valueForKey:KEY_SYS] valueForKey:ELE_SUNRISE] doubleValue];
    return [NSNumber numberWithDouble:value];
}

- (NSNumber *) getSunSet
{
    double value = [[[jsonWeatherData valueForKey:KEY_SYS] valueForKey:ELE_SUNSET] doubleValue];
    return [NSNumber numberWithDouble:value];
}


- (NSString *) getName
{
    NSString * cityName = [jsonWeatherData valueForKey:KEY_NAME];
    if (cityName == nil) {
        cityName = @"";
    }
    return cityName;
}

- (NSString *) convertKelToCel:(NSString *) kelStr
{
    //return kelStr;
    if(kelStr != nil){
        float kel = kelStr.floatValue;
        return [NSString stringWithFormat:@"%f",(kel-273.15)];
    }else{
        return nil;
    }
}

- (bool) isNotNil
{
    if(jsonWeatherData==nil){
        return false;
    }else{
        return true;
    }
}

- (bool) isNil
{
    if(jsonWeatherData==nil){
        return true;
    }else{
        return false;
    }
}

- (bool) isOld:(int)gap
{
    NSDate *now = [NSDate date];
    NSTimeInterval delta = [now timeIntervalSinceDate:thisDate];
    if(delta > gap){
        return true;
    }else{
        return false;
    }
}

- (NSString *)description
{
    return [jsonWeatherData description];
}

@end

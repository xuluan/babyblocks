#import <Foundation/Foundation.h>
#import "CJSONDeserializer.h"
#import "CJSONSerializer.h"
/* This returns the full absolute path to a specified file in the bundle */
NSString* getActualPath( NSString* file )
{
	NSArray* path = [file componentsSeparatedByString: @"."];
	NSString* actualPath = [[NSBundle mainBundle] pathForResource: [path objectAtIndex: 0] ofType: [path objectAtIndex: 1]];
		
	return actualPath;
}

BOOL initial_settings()
{
    BOOL success;
    NSFileManager* fileManager = [NSFileManager defaultManager]; 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"settings.json"];
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success) return success;
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = getActualPath(@"settings.json");

    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:nil];
    
    return success;
}

NSDictionary* loadSettings()
{
    NSLog(@"LOAD start\n");
    BOOL success = initial_settings();
    if(!success) {
        NSLog(@"initial_settings fail\n");
        return nil;
    }

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"settings.json"];


    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    NSDictionary* dict =  [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:nil];
    
    int size = [[dict objectForKey:@"current_size"] intValue];
    NSLog(@"load size = %d\n",size);
    return dict;

}

void saveSettings(NSDictionary *dictionary) {
    
    NSError *error = NULL;
    NSData *jsonData = [[CJSONSerializer serializer] serializeObject:dictionary error:&error];
    if(error){
        NSLog(@"json save error %@\n", error);
    }

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"settings.json"];
    
    //NSString *str = [[NSString alloc] initWithContentsOfFile:dir encoding:NSUTF8StringEncoding error:nil];
    //NSLog(@"str %@\n", str);

    NSString *jsonString = [[NSString alloc] initWithData:jsonData  encoding:NSUTF8StringEncoding];
    
    //NSString *jsonString = [[NSString alloc] initWithString:@"test"];


    [jsonString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    //str = [[NSString alloc] initWithContentsOfFile:dir encoding:NSUTF8StringEncoding error:nil];
    //NSLog(@"json %@ write %@, read %@\n", dir, jsonString, str);


}

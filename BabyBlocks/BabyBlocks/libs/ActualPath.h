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

NSDictionary* loadSettings()
{
    NSLog(@"LOAD start\n");

    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:getActualPath(@"settings.json") encoding:NSUTF8StringEncoding error:nil];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    NSDictionary* dict =  [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:nil];
    
    int size = [[dict objectForKey:@"current_size"] intValue];
    NSLog(@"load size = %d\n",size);
    return dict;

}

void saveSettings(NSDictionary *dictionary) {
    NSLog(@"save start\n");

	//NSData *jsonData = [[CJSONDeserializer serializer] serializeObject:dictionary error:nil];
    NSData *jsonData = [[CJSONSerializer serializer] serializeObject:dictionary error:nil];
 
    NSString *jsonString = [[NSString alloc] initWithData:jsonData  encoding:NSUTF32BigEndianStringEncoding];

    [jsonString writeToFile:getActualPath(@"settings.json") atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"save end\n");

}

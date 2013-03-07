#import <Foundation/Foundation.h>

/* This returns the full absolute path to a specified file in the bundle */
NSString* getActualPath( NSString* file )
{
	NSArray* path = [file componentsSeparatedByString: @"."];
	NSString* actualPath = [[NSBundle mainBundle] pathForResource: [path objectAtIndex: 0] ofType: [path objectAtIndex: 1]];
		
	return actualPath;
}


(void) loadSettings(NSDictionary *dictionary) {
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:getActualPath(@"settings.json") encoding:NSUTF8StringEncoding error:nil];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    dictionary = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:nil];
}

(void) saveSettings(NSDictionary *dictionary) {
	NSData *jsonData = [[CJSONSerializer serializer] serializeObject:dictionary error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData  encoding:NSUTF8StringEncoding error:nil];
    [jsonString writeToFile:getActualPath(@"settings.json") atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

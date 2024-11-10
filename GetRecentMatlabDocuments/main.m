//
//  main.m
//  GetRecentMatlabDocuments
//
//  Created by Andrea Alberti on 18.02.18.
//  Copyright © 2018 Andrea Alberti. All rights reserved.
//

#import <Foundation/Foundation.h>

NSArray* get_recent_documents(void) __attribute__((ns_returns_retained))
{
    NSString* const MatlabPath = [@"~/Library/Application Support/MathWorks/MATLAB" stringByExpandingTildeInPath];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *dirEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:MatlabPath] includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                       options:NSDirectoryEnumerationSkipsSubdirectoryDescendants  errorHandler:nil];
    NSMutableArray *theArray=[NSMutableArray array];
    NSString *fileName;
    NSNumber *isDirectory;
    
    NSScanner *scanner = [NSScanner alloc];
    [scanner setCharactersToBeSkipped:nil];
    
    int year = 0;
    int yearFound = 0;
    NSString* MatlabVersion;
    NSString* foundHalfYear;
    
    for (NSURL *theURL in dirEnumerator) {
        
        // Retrieve the file name. From NSURLNameKey, cached during the enumeration.
        
        [theURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
        
        // Retrieve whether a directory. From NSURLIsDirectoryKey, also
        // cached during the enumeration.
        
        [theURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        
        if([isDirectory boolValue] == YES)
        {
            scanner = [scanner initWithString:fileName];
            if([scanner scanString:@"R" intoString:nil])
            {
                if([scanner scanInt:&yearFound])
                {
                    if([scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"ab"] intoString:&foundHalfYear])
                    {
                        if([scanner isAtEnd] && [scanner scanLocation]==6)
                        {
                            yearFound = 2*yearFound + [foundHalfYear characterAtIndex:0]-'a';
                            if(yearFound>year)
                            {
                                year = yearFound;
                                MatlabVersion = [[NSString alloc] initWithString:fileName];
                            }
                        }
                    }
                }
            }
            
            [theArray addObject: fileName];
        }
    }
    
    NSMutableArray* RecentDocuments = [[NSMutableArray alloc] initWithCapacity:8];
    
    NSString* init_file = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/matlab.prf", MatlabPath, MatlabVersion] encoding:NSUTF8StringEncoding error:nil];
    
    scanner = [[NSScanner alloc] initWithString:init_file];
    [scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString* foundPath;
    int foundInt;
    NSString* targetString = @"EditorMRU";
    
    while([scanner scanUpToString:targetString intoString:nil])
    {
        if([scanner isAtEnd]==NO)
        {
            [scanner setScanLocation:([scanner scanLocation]+[targetString length])];
            
            if([scanner scanInt:&foundInt])
            {
                if([scanner scanString:@"=" intoString:nil])
                {
                    if([scanner scanString:@"S" intoString:nil])
                    {
                        if([scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&foundPath])
                        {
                            if( access([foundPath fileSystemRepresentation], F_OK ) != -1 )
                            {
                                [RecentDocuments addObject:@[@(foundInt),foundPath]];
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    NSArray* RecentDocumentsSorted = [[NSArray alloc] initWithArray:
                                      [RecentDocuments sortedArrayUsingComparator:^NSComparisonResult(NSArray* a, NSArray* b) {
        return a[0]>b[0];
    }]];
    
    return RecentDocumentsSorted;
}

const char* create_LB_menu_entries(void)
{
    NSArray* RecentDocuments = get_recent_documents();
    
    // NSFileManager *fm = [NSFileManager defaultManager];
    if ([RecentDocuments count] > 0)
    {
        
        NSArray* LBkeys = @[@"title", @"subtitle", @"path"];
        
        NSMutableArray* LBitems = [[NSMutableArray alloc] init];
        
        NSString* title;
        NSString* subtitle;
        //NSString* icon;
        
        for(NSArray* filepath in RecentDocuments)
        {
            title = [(NSString*)[filepath objectAtIndex:1] lastPathComponent];
            subtitle = [(NSString*)[filepath objectAtIndex:1] stringByDeletingLastPathComponent];
            //icon = [NSString stringWithFormat:@"com.mathworks.matlab:%@",[[(NSString*)[filepath objectAtIndex:1] pathExtension] lowercaseString]];
            
            [LBitems addObject:[[NSDictionary alloc] initWithObjects:
                                @[title,
                                  subtitle,
                                  [filepath objectAtIndex:1],
//                                  icon
                                  //, [NSString stringWithFormat:@"%@:%@",APP_NAME,[icon lowercaseString]]
                                  ] forKeys:LBkeys]];
            
        }
        
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:LBitems
                                                           options:NSJSONWritingPrettyPrinted error:nil];
        
        return [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] UTF8String];
    }
    else
    {
        return "";
    }
}

int main(int argc, const char * argv[]) {
    // @autoreleasepool {
    
    @try {
        //create_LB_menu_entries();
        fprintf(stdout, "%s", create_LB_menu_entries());
        
        return 0;
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception);
        
        return -1;
    }
    
    // }
    return 0;
}


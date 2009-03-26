#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#import <Foundation/Foundation.h>

/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports
  
   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
   that your importer can handle
  
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForFile function
  
   Implement the GetMetadataForFile function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update the schema.xml file
  
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
    
    Boolean result = NO;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableDictionary *attDict = (NSMutableDictionary *)attributes;
    NSMutableArray *authors = [NSMutableArray array];
    NSMutableArray *contactKeywords = [NSMutableArray array];
    NSError *err=nil;
    NSXMLDocument *metadata = [[[NSXMLDocument alloc] initWithData:[NSData dataWithContentsOfFile:[(NSString *)pathToFile stringByAppendingPathComponent:@"metadata.xml"]] options:nil error:&err] autorelease];
    if (!err) {
        NSEnumerator *contributors = [[metadata nodesForXPath:@"/seemetadata/contributors/contributor" error:&err] objectEnumerator];
        NSXMLElement *contributor = nil;
        while ((contributor=[contributors nextObject])) {
            NSString *name = [[contributor attributeForName:@"name"] stringValue];
            if (name && [name length]>0) {
                [authors addObject:name];
                NSMutableArray *contactAttributes = [NSMutableArray array];
                NSString *email = [[contributor attributeForName:@"email"] stringValue];
                if (email && [email length]>0) {
                    [contactAttributes addObject:email];
                }
                NSString *aim = [[contributor attributeForName:@"aim"] stringValue];
                if (aim && [aim length]>0) {
                    [contactAttributes addObject:[NSString stringWithFormat:@"AIM: %@",aim]];
                }
                if ([contactAttributes count]) {
                    [contactKeywords addObject:[NSString stringWithFormat:@"%@ (%@)",name,[contactAttributes componentsJoinedByString:@", "]]];
                } else {
                    [contactKeywords addObject:name];
                }
            }
        }
        [attDict setObject:authors forKey:(NSString *)kMDItemAuthors];
        [attDict setObject:contactKeywords forKey:(NSString *)kMDItemContactKeywords];
        NSString *ianaCharsteName = [[[metadata nodesForXPath:@"/seemetadata/charset" error:&err] lastObject] stringValue];
        NSString *contentString = [NSString stringWithContentsOfFile:[(NSString *)pathToFile stringByAppendingPathComponent:@"plain.txt"] encoding:CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)ianaCharsteName)) error:&err];
        if (contentString) {
            [attDict setObject:contentString forKey:(NSString *)kMDItemTextContent];
        }
        NSString *mode = [[[metadata nodesForXPath:@"/seemetadata/mode" error:&err] lastObject] stringValue];
        if (mode && [mode length]>0) {
            [attDict setObject:mode forKey:@"de_codingmonkeys_subethaedit_mode"];
        }
        result = YES;
    }
    [pool release];
    return result;
}

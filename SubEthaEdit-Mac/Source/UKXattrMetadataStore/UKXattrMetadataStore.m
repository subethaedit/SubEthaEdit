//  UKXattrMetadataStore.m
//  BubbleBrowser
//	LICENSE: MIT License
//
//  Created by Uli Kusterer on 12.03.06.
//  Copyright 2006 Uli Kusterer. All rights reserved.
//

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import "UKXattrMetadataStore.h"
#import <sys/xattr.h>

@implementation UKXattrMetadataStore

// -----------------------------------------------------------------------------
//	allKeysAtPath:traverseLink:
//		Return an NSArray of NSStrings containing all xattr names
//currently set
//		for the file at the specified path.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+ (NSArray*)allKeysAtPath:(NSString*)path traverseLink:(BOOL)travLnk {
  NSMutableArray* allKeys = [NSMutableArray array];
  size_t dataSize = listxattr([path fileSystemRepresentation], NULL, ULONG_MAX,
                              (travLnk ? 0 : XATTR_NOFOLLOW));
  if (dataSize == ULONG_MAX) return allKeys;  // Empty list.
  NSMutableData* listBuffer = [NSMutableData dataWithLength:dataSize];
  dataSize =
      listxattr([path fileSystemRepresentation], [listBuffer mutableBytes],
                [listBuffer length], (travLnk ? 0 : XATTR_NOFOLLOW));
  char* nameStart = [listBuffer mutableBytes];
  int x;
  for (x = 0; x < dataSize; x++) {
    if (((char*)[listBuffer mutableBytes])[x] == 0)  // End of string.
    {
      NSString* str = [NSString stringWithUTF8String:nameStart];
      nameStart = [listBuffer mutableBytes] + x + 1;
      [allKeys addObject:str];
    }
  }

  return allKeys;
}

// -----------------------------------------------------------------------------
//	setData:forKey:atPath:traverseLink:
//		Set the xattr with name key to a block of raw binary data.
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+ (void)setData:(NSData*)data
          forKey:(NSString*)key
          atPath:(NSString*)path
    traverseLink:(BOOL)travLnk {
  setxattr([path fileSystemRepresentation], [key UTF8String], [data bytes],
           [data length], 0, (travLnk ? 0 : XATTR_NOFOLLOW));
}

+ (void)removeDataForKey:(NSString*)key
                  atPath:(NSString*)path
            traverseLink:(BOOL)travLnk {
  // int result =
  removexattr([path fileSystemRepresentation], [key UTF8String],
              (travLnk ? 0 : XATTR_NOFOLLOW));
  //	NSLog(@"%s %d %@ %@", __FUNCTION__, result, key, path);
}

// -----------------------------------------------------------------------------
//	setObject:forKey:atPath:traverseLink:
//		Set the xattr with name key to an XML property list representation
//of
//		the specified object (or object graph).
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+ (void)setObject:(id)obj
           forKey:(NSString*)key
           atPath:(NSString*)path
     traverseLink:(BOOL)travLnk {
    // Serialize our objects into a property list XML string:
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:obj format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    if (error) {
        [NSException raise:@"UKXattrMetastoreCantSerialize" format:@"%@", error];
    } else {
        [[self class] setData:plistData
                       forKey:key
                       atPath:path
                 traverseLink:travLnk];
    }
}

// -----------------------------------------------------------------------------
//	setString:forKey:atPath:traverseLink:
//		Set the xattr with name key to an XML property list representation
//of
//		the specified object (or object graph).
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+ (void)setString:(NSString*)str
           forKey:(NSString*)key
           atPath:(NSString*)path
     traverseLink:(BOOL)travLnk {
  NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];

  if (!data)
    [NSException raise:NSCharacterConversionException
                format:@"Couldn't convert string to UTF8 for xattr storage."];

  [[self class] setData:data forKey:key atPath:path traverseLink:travLnk];
}

// -----------------------------------------------------------------------------
//	dataForKey:atPath:traverseLink:
//		Retrieve the xattr with name key as a raw block of data.
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+ (NSMutableData*)dataForKey:(NSString*)key
                      atPath:(NSString*)path
                traverseLink:(BOOL)travLnk {
  size_t dataSize =
      getxattr([path fileSystemRepresentation], [key UTF8String], NULL,
               ULONG_MAX, 0, (travLnk ? 0 : XATTR_NOFOLLOW));
  if (dataSize == ULONG_MAX) return nil;
  NSMutableData* data = [NSMutableData dataWithLength:dataSize];
  getxattr([path fileSystemRepresentation], [key UTF8String],
           [data mutableBytes], [data length], 0,
           (travLnk ? 0 : XATTR_NOFOLLOW));

  return data;
}

// -----------------------------------------------------------------------------
//	objectForKey:atPath:traverseLink:
//		Retrieve the xattr with name key, which is an XML property list
//		and unserialize it back into an object or object graph.
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+ (id)objectForKey:(NSString*)key
            atPath:(NSString*)path
      traverseLink:(BOOL)travLnk {
    NSError *error = nil;
    NSMutableData *data =[[self class] dataForKey:key atPath:path traverseLink:travLnk];
    NSPropertyListFormat outFormat = NSPropertyListXMLFormat_v1_0;
    id obj = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&outFormat error:&error];
    if (error) {
        [NSException raise:@"UKXattrMetastoreCantUnserialize" format:@"%@", error];
    }
    return obj;
}

// -----------------------------------------------------------------------------
//	stringForKey:atPath:traverseLink:
//		Retrieve the xattr with name key, which is an XML property list
//		and unserialize it back into an object or object graph.
//		path is the file whose xattr you want to set.
//		If travLnk == YES, it follows symlinks.
// -----------------------------------------------------------------------------

+ (id)stringForKey:(NSString*)key
            atPath:(NSString*)path
      traverseLink:(BOOL)travLnk {
  NSMutableData* data =
      [[self class] dataForKey:key atPath:path traverseLink:travLnk];
  if (!data) return nil;
  return [[[NSString alloc] initWithData:data
                                encoding:NSUTF8StringEncoding] autorelease];
}

@end

#endif /*MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4*/

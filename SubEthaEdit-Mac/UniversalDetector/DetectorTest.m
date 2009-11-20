#import <Cocoa/Cocoa.h>
#import <UniversalDetector/UniversalDetector.h>

int main(int argc,char **argv)
{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];

	UniversalDetector *detector=[UniversalDetector detector];

	for(int i=1;i<argc;i++)
	{
		NSData *data=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[i]]];
		[detector analyzeData:data];
	}

	printf("%s %d %f\n",[[detector MIMECharset] UTF8String],[detector encoding],[detector confidence]);

	[pool release];
	return 0;
}
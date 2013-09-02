// A tiny program that converts PDF documents to high resolution PNG images.
//
// gcc --std=c99 -Wall -g -o pdf2png pdf2png.m -framework Cocoa
//
// Written by Evan Jones <ejones@uwaterloo.ca> Februrary, 2004
// http://www.eng.uwaterloo.ca/~ejones/
//
// Released under the "do whatever you want" public domain licence.

#include <Cocoa/Cocoa.h>

int main( int argc, char* argv[] )
{
	int desiredResolution = 200; // in DPI

	BOOL morePages = YES;
	int page = 1;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Package all arguments as NSStrings in an NSArray
	NSMutableArray* args = [NSMutableArray arrayWithCapacity: argc - 1];
	for ( int i = 1; i < argc; ++ i )
	{
		// 2006/08/28 21:18  use stringWithUTF8String
		// [args addObject: [NSString stringWithCString: argv[i]] ];
		[args addObject: [NSString stringWithUTF8String: argv[i]] ];
	}
	
	// If we have a "--dpi" along with a corresponding argument ...
	NSUInteger index = NSNotFound;
	if ( (index = [args indexOfObject: @"--dpi"]) != NSNotFound && index + 1 < [args count] )
	{
		// Parse it as an integer
		desiredResolution = [[args objectAtIndex: index + 1] intValue];
		[args removeObjectAtIndex: index + 1];
		[args removeObjectAtIndex: index];
	}
	
	// If we have a "--page" along with a corresponding argument ...
	if ( (index = [args indexOfObject: @"--page"]) != NSNotFound && index + 1 < [args count] )
	{
		// Parse it as an integer
		page = [[args objectAtIndex: index + 1] intValue];
		morePages = NO;
		[args removeObjectAtIndex: index + 1];
		[args removeObjectAtIndex: index];
	}
	
	if ( [args count] != 1 || [args indexOfObject: @"--help"] != NSNotFound || desiredResolution <= 0 || page <= 0 )
	{
		fprintf( stderr, "pdf2png [options] file\n" );
		fprintf( stderr, "\t--dpi dpi\tSpecifies the resolution at which to export the pages\n" );
		fprintf( stderr, "\t--page page\tSingle page to export\n" );
		fprintf( stderr, "\t--help\tPrint this help message\n" );
		return 1;
	}

	

	
	NSString* sourcePath = [args objectAtIndex: 0];
	NSImage* source = [ [NSImage alloc] initWithContentsOfFile: sourcePath ];
	[source setScalesWhenResized: YES];
	
	// Tip from http://www.omnigroup.com/mailman/archive/macosx-dev/2002-February/023366.html
	// Allows setCurrentPage to do anything
	[source setDataRetained: YES];
	
	if ( source == nil )
	{
		fprintf( stderr, "Source image '%s' could not be loaded\n", argv[1] );
		return 2;
	}
	
	// The output file name
	NSString* outputFileFormat = @"%@-p%01d";
	
	// Find the PDF representation
	NSPDFImageRep* pdfSource = NULL;
	NSArray* reps = [source representations];
	for ( int i = 0; i < [reps count] && pdfSource == NULL; ++ i )
	{
		if ( [[reps objectAtIndex: i] isKindOfClass: [NSPDFImageRep class]] )
		{
			pdfSource = [reps objectAtIndex: i];
			[pdfSource setCurrentPage: page-1];
			
			// Set the output format to have the correct number of leading zeros
			unsigned int numDigits = [(NSString*) [NSString stringWithFormat: @"%d", [pdfSource pageCount]] length];
			outputFileFormat = [NSString stringWithFormat: @"%%@-p%%0%dd", numDigits];
		}
	}
	
	NSSize sourceSize = [source size];
	
	// When loading a PDF document, it reports size in typographic dots. There are 72 dots per inch.
	// See http://www.macosxguru.net/article.php?story=20031209091834195
	// When converting, we need to scale the PDF by this factor
	double sourceResolution = 72.0;
	int pixels = [ [source bestRepresentationForDevice: nil] pixelsWide];
	if ( pixels != 0 ) sourceResolution = ((double)pixels / sourceSize.width) * 72.0;
	double scaleFactor = desiredResolution / sourceResolution; 
	
	NSSize size = NSMakeSize( sourceSize.width * scaleFactor, sourceSize.height * scaleFactor );
	

	[NSApplication sharedApplication];
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];

	[source setSize: size];
	NSRect destinationRect = NSMakeRect( 0, 0, size.width, size.height );
	
	NSImage* image = [[NSImage alloc] initWithSize:size];
	[image lockFocus];
	[[NSColor whiteColor] set]; // We fill the rect with white, with full opacity, later on
	
	do
	{
		// Set up a temporary release pool so memory will get cleaned up properly
		NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
		
		NSRectFillUsingOperation( destinationRect, NSCompositeClear );
		[source drawInRect: destinationRect
			fromRect: destinationRect
			operation: NSCompositeCopy fraction: 1.0];
		
		NSBitmapImageRep* bitmap = [ [NSBitmapImageRep alloc]
			initWithFocusedViewRect: destinationRect ];
		
		NSData* data = [bitmap representationUsingType:NSPNGFileType properties:nil];
		[bitmap release];
		
		[[NSFileManager defaultManager]
			createFileAtPath: [ [NSString stringWithFormat: outputFileFormat, [sourcePath stringByDeletingPathExtension], page] stringByAppendingPathExtension: @"png"]
			contents: data
			attributes: nil ];
		
		if ( morePages == YES )
		{
			// Go get the next page
			if ( pdfSource != NULL && page < [pdfSource pageCount] )
			{
				[pdfSource setCurrentPage: page];
				[source recache];
				page ++;
			}
			else
			{
				morePages = NO;
			}
		}
		
		[loopPool release];
	}
	while ( morePages == YES );
	
	[image unlockFocus];
	[image release];
	[pool release];
}
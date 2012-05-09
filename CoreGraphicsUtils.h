#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

// Context utilities

CGContextRef createRGBABitmapContext(int pixelsWide, int pixelsHigh);
void destroyBitmapContext(CGContextRef context);
void flipContext(CGContextRef context, CGRect bounds);

// Path utilities

void addRoundedRect(CGContextRef context, CGRect rrect, CGFloat radius);

// Image I/O utilities

CGImageRef loadPDF(NSURL *fileURL, CGRect bounds);                // Loads first page only
CGImageRef loadBitmapImage(NSURL *fileURL);                       // PNG or JPEG
CGImageRef loadImageFromPath(NSString *imagePath, CGRect bounds); // PDF, PNG, or JPEG
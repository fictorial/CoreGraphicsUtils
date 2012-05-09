#import "CoreGraphicsUtils.h"

#pragma mark - context utilities

CGContextRef createRGBABitmapContext(int pixelsWide, int pixelsHigh) {
    int bitmapBytesPerRow = (pixelsWide * 4);
    int bitmapByteCount = (bitmapBytesPerRow * pixelsHigh);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    void *bitmapData = calloc(1, bitmapByteCount);
    if (!bitmapData) {
        return NULL;
    }
    
    // TODO not sure if I have to manually premultiply my colors??
    
    CGContextRef context = CGBitmapContextCreate(bitmapData, pixelsWide, pixelsHigh, 8,
                                                 bitmapBytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    
    if (!context) {
        free(bitmapData);
        return NULL;
    }
    
    CGColorSpaceRelease(colorSpace);
    return context;
}

void destroyBitmapContext(CGContextRef context) {
    void *bitmapData = CGBitmapContextGetData(context);
    CGContextRelease(context);
    free(bitmapData);
}

// TODO needed?
void flipContext(CGContextRef context, CGRect bounds) {
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
}

#pragma mark - path utilities

// This is from Apple's 'Quartz Demo'

void addRoundedRect(CGContextRef context, CGRect rrect, CGFloat radius) {
    // In order to draw a rounded rectangle, we will take advantage of the fact that
    // CGContextAddArcToPoint will draw straight lines past the start and end of the arc
    // in order to create the path from the current position and the destination position.
    
    // In order to create the 4 arcs correctly, we need to know the min, mid and max positions
    // on the x and y lengths of the given rectangle.
    CGFloat minx = CGRectGetMinX(rrect), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect);
    CGFloat miny = CGRectGetMinY(rrect), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect);
    
    // Next, we will go around the rectangle in the order given by the figure below.
    //       minx    midx    maxx
    // miny    2       3       4
    // midy   1 9              5
    // maxy    8       7       6
    // Which gives us a coincident start and end point, which is incidental to this technique, but still doesn't
    // form a closed path, so we still need to close the path to connect the ends correctly.
    // Thus we start by moving to point 1, then adding arcs through each pair of points that follows.
    // You could use a similar tecgnique to create any shape with rounded corners.
    
    // Start at 1
    CGContextMoveToPoint(context, minx, midy);
    // Add an arc through 2 to 3
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    // Add an arc through 4 to 5
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    // Add an arc through 6 to 7
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    // Add an arc through 8 to 9
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    // Close the path
    CGContextClosePath(context);
}

#pragma mark - image loading routines

CGImageRef loadPDF(NSURL *fileURL, CGRect bounds) {
    // Draw the PDF to a context and get an image from the context for further drawing.
    
    CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithURL((CFURLRef)fileURL);
    CGPDFPageRef firstPage = CGPDFDocumentGetPage(pdfDocument, 1);
    
    CGContextRef pdfImageContext = createRGBABitmapContext(bounds.size.width,
                                                           bounds.size.height);
    
    // "The part about the mediaRect is necessary because PDF pages are typically larger
    // than what you really see on screen. There are usually some printing, color and crop
    // marks outside of the content area"
    // http://www.cocoanetics.com/2010/06/rendering-pdf-is-easier-than-you-thought
    
    CGRect mediaRect = CGPDFPageGetBoxRect(firstPage, kCGPDFCropBox);
    CGContextScaleCTM(pdfImageContext,
                      bounds.size.width / mediaRect.size.width,
                      bounds.size.height / mediaRect.size.height);
    
    CGContextDrawPDFPage(pdfImageContext, firstPage);
    CGImageRef imageRef = CGBitmapContextCreateImage(pdfImageContext);
    
    CGPDFDocumentRelease(pdfDocument);
    destroyBitmapContext(pdfImageContext);
    
    return imageRef;
}

CGImageRef loadBitmapImage(NSURL *fileURL) {
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)fileData);
    
    NSString *fileName = [[fileURL absoluteString] lastPathComponent];
    NSString *fileExtension = [[fileName pathExtension] uppercaseString];

    if ([fileExtension isEqualToString:@"PNG"]) {
        return CGImageCreateWithPNGDataProvider(dataProvider, NULL, true, kCGRenderingIntentDefault);
    }
    
    if ([fileExtension isEqualToString:@"JPG"] ||
        [fileExtension isEqualToString:@"JPEG"]) {
        
        return CGImageCreateWithJPEGDataProvider(dataProvider, NULL, true, kCGRenderingIntentDefault);
    }
    
    return NULL;
}

CGImageRef loadImageFromPath(NSString *imagePath, CGRect bounds) {
    NSLog(@"load image from %@", imagePath);
    
    NSString *fileName = [imagePath lastPathComponent];
    NSString *fileExtension = [[imagePath pathExtension] uppercaseString];
    
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    NSURL *fileURL = [NSURL fileURLWithPath:resourcePath];
    
    CGImageRef imageRef = NULL;
    
    if ([fileExtension isEqualToString:@"PDF"]) {       
        imageRef = loadPDF(fileURL, bounds);
    } else {
        imageRef = loadBitmapImage(fileURL);
    }
    
    if (!imageRef) {
        NSLog(@"I do not know how to load this image: %@", imagePath);
        assert(0);
    }
    
    return imageRef;
}

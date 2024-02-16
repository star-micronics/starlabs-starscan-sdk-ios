#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
@import UIKit;
#else
@import AppKit;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BarcodeUtil: NSObject
+ (UIImage *)imageForDataMatrixCode:(NSString *)code;
+ (UIImage *)imageForCode128:(NSString *)code;
+ (UIImage *)imageForBarcode:(NSString *)code symbology:(int)symbology;
+ (UIImage *)imageFromRGB:(unsigned char *)buffer width:(int)width height:(int)height;

@end

NS_ASSUME_NONNULL_END

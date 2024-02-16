#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BleUpdate: NSObject

+ (void)SetMaxFrameSize:(NSInteger)size;
+ (NSInteger)ImportFile:(NSString *)path totalUpgradeType:(NSInteger*)totalUpgradeType totalDataPack:(NSInteger*)totalDataPack;
+ (NSString *)GetDevNameFromImportFile;
+ (NSData *)GetPackCmd:(NSInteger)nUpgradeType packIdx:(NSInteger)nPackIdx;
+ (NSData *)GetPackData:(NSInteger)nUpgradeType packIdx:(NSInteger)nPackIdx;
+ (NSInteger)GetParam:(NSInteger)nUpgradeType pImportFileStatus:(NSInteger*)pImportFileStatus pFrameSize:(NSInteger*)pFrameSize pCmdPackCnt:(NSInteger*)pCmdPackCnt pDataPackCnt:(NSInteger*)pDataPackCnt;

@end

NS_ASSUME_NONNULL_END

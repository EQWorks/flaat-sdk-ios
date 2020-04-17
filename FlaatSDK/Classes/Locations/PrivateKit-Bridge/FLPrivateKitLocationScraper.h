#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// This is an interface to scrape locations using ReactNative's Async Storage
@interface FLPrivateKitLocationScraper : NSObject

+ (NSDictionary *)fetchAllLoggedLocations;

@end

NS_ASSUME_NONNULL_END

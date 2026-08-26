// #define FM_OFFLINE_BUILD 1
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import <mach-o/loader.h>
#import <dlfcn.h>
#import <objc/message.h>
#import <sys/utsname.h>
#import <errno.h>
#import <fcntl.h>
#import <stdbool.h>
#import <stdarg.h>
#import <stdlib.h>
#import <string.h>
#import <unistd.h>
#import "ProtectedConfig.h"

#ifndef LC_DYLD_EXPORTS_TRIE
#define LC_DYLD_EXPORTS_TRIE (0x33 | LC_REQ_DYLD)
#endif

static NSString *const FFBookmarkKey = @"FMSelectedFolderBookmark";
static NSString *const FFBackupSuffix = @".fmbackup";
static NSString *const FFActiveProfileKey = @"FMActiveProfile";
static NSString *const FFKeychainService = @"com.acidevloper.ffcache.protected";
static NSString *const FFDeviceAccount = @"fm-installation-id";
static NSString *const FFLegacyLicenseAccount = @"fm-owner-license";
static NSString *const FFAccessTokenAccount = @"fm-session-access-token";
static NSString *const FFRefreshTokenAccount = @"fm-session-refresh-token";
static NSString *const FFAutoClipboardLicenseDigestKey = @"FMAutoClipboardLicenseDigest";
static NSString *const FFOwnerTelegram = @"KODIBATIB6";
static NSString *const FFOfficialChannelURL = @"https://t.me/k0dibabi";
static NSString *const FFOwnerTelegramSHA256 = @"9123084c6a0ae927347adcbdc7b731835ad308375aa88293c3fb8ebf5cac97ab";
static NSString *const FFOfficialChannelSHA256 = @"2622738d521811261c67d4107b8120034dda10903b74ea2918ea92347107c99b";

static NSString *FFSHA256String(NSString *value) {
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) [result appendFormat:@"%02x", digest[i]];
    return result;
}

static BOOL FFBrandIdentityIsValid(void) {
    return [FFSHA256String(FFOwnerTelegram) isEqualToString:FFOwnerTelegramSHA256] &&
           [FFSHA256String(FFOfficialChannelURL) isEqualToString:FFOfficialChannelSHA256];
}
// Network configuration is intentionally absent in this local build.
static NSString *FFAPIBaseURL(void) {
    return @"http://192.168.1.105:5000";
}
static NSString *const FFBundleIDFreeFireTH = @"com.dts.freefireth";
static NSString *const FFBundleIDFreeFireMAX = @"com.dts.freefiremax";
static NSString *const FFHologramShaderFilename = @"shaders.HPt9DZviTSXL9hpGW9QNOMigNLA~3D";
static NSString *const FFThreeDShaderFilename = @"optionalavatarres_commonab_shader";
static NSString *const FFHologramStateKey = @"FMHologramPersistentState";

static NSURL *FFFindGameAssetBundles(NSURL *root, NSError **error);

typedef void (*MCMFilzaStartFunction)(void);
typedef void (*MCMFilzaSetUnrestrictedFilesystemFunction)(BOOL);
typedef NSString *(*MCMFilzaDataContainerPathFunction)(NSString *, NSString **);
typedef NSString *(*MCMFilzaVirtualRootFunction)(void);

#ifdef FM_OFFLINE_BUILD
typedef void *(*FF3105QueryCreateFunction)(void);
typedef void (*FF3105QuerySetClassFunction)(void *, uint64_t);
typedef void (*FF3105QuerySetIdentifiersFunction)(void *, void *);
typedef void (*FF3105QuerySetFlagsFunction)(void *, uint64_t);
typedef void (*FF3105QuerySetPartFunction)(void *, uint64_t);
typedef void *(*FF3105QueryGetResultFunction)(void *);
typedef void *(*FF3105QueryGetErrorFunction)(void *);
typedef void (*FF3105QueryFreeFunction)(void *);
typedef const char *(*FF3105ObjectGetPathFunction)(void *);
typedef void *(*FF3105ObjectCopyFunction)(void *);
typedef char *(*FF3105CopySandboxTokenFunction)(void *);
typedef BOOL (*FF3105ActivateSandboxExtensionFunction)(void *, uint32_t);
typedef void (*FF3105ObjectFreeFunction)(void *);
typedef int (*FF3105ErrorPOSIXFunction)(void *);
typedef const char *(*FF3105ErrorMessageFunction)(void *);
typedef void *(*FF3105XPCStringCreateFunction)(const char *);

typedef struct {
    void *handle;
    FF3105QueryCreateFunction queryCreate;
    FF3105QuerySetClassFunction querySetClass;
    FF3105QuerySetIdentifiersFunction querySetIdentifiers;
    FF3105QuerySetIdentifiersFunction querySetGroupIdentifiers;
    FF3105QuerySetFlagsFunction querySetFlags;
    FF3105QuerySetPartFunction querySetPart;
    FF3105QueryGetResultFunction queryGetSingleResult;
    FF3105QueryGetErrorFunction queryGetLastError;
    FF3105QueryFreeFunction queryFree;
    FF3105ObjectGetPathFunction objectGetPath;
    FF3105ObjectCopyFunction objectCopy;
    FF3105CopySandboxTokenFunction copySandboxToken;
    FF3105ActivateSandboxExtensionFunction activateSandboxExtension;
    FF3105ObjectFreeFunction objectFree;
    FF3105ErrorPOSIXFunction errorPOSIX;
    FF3105ErrorMessageFunction errorMessage;
    FF3105XPCStringCreateFunction xpcStringCreate;
} FF3105MCMAPI;

static FF3105MCMAPI FF3105API;
static NSString *FF3105MCMContainerPath(NSString *identifier, NSString **detail);
#endif

static void *FFProtectedCoreHandle = NULL;
static MCMFilzaStartFunction FFMCMStart = NULL;
static MCMFilzaSetUnrestrictedFilesystemFunction FFMCMSetUnrestrictedFilesystem = NULL;
static MCMFilzaDataContainerPathFunction FFMCMDataContainerPath = NULL;
static MCMFilzaVirtualRootFunction FFMCMVirtualRoot = NULL;

static NSString *ZXDigest(NSData *data);
static BOOL ZXIsSHA256(NSString *value);
static NSDictionary<NSString *, NSString *> *FFGameDefinition(NSString *bundleIdentifier);

// The bot generates ROBOT-XXXXX-XXXXX-XXXXX-XXXXX keys.  A user may copy the
// whole bot message rather than just the code, so extract one bounded key from
// the text.  The raw clipboard contents are never persisted.
static NSString *FFLicenseKeyFromText(NSString *value) {
    if (![value isKindOfClass:NSString.class]) return nil;
    NSString *candidate = [[value stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if (!candidate.length) return nil;
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:
        @"(?:^|[^A-Z0-9-])((?:FFM|[A-Z0-9]{4,12})(?:-[A-Z0-9]{4,8}){3,5})(?=$|[^A-Z0-9-])"
        options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:candidate options:0
        range:NSMakeRange(0, candidate.length)];
    if (matches.count != 1) return nil;
    NSRange keyRange = [matches.firstObject rangeAtIndex:1];
    return keyRange.location == NSNotFound ? nil : [candidate substringWithRange:keyRange];
}

static NSString *FFClipboardLicenseKey(void) {
    return FFLicenseKeyFromText(UIPasteboard.generalPasteboard.string);
}

static NSString *FFActiveProfileDefaultsKey(NSString *gameIdentifier) {
    if (!FFGameDefinition(gameIdentifier)) return nil;
    return [NSString stringWithFormat:@"%@.%@", FFActiveProfileKey, gameIdentifier];
}

static UIColor *FFVIPGold(void) {
    return [UIColor colorWithRed:0.95 green:0.08 blue:0.12 alpha:1.00];
}

static UIColor *FFVIPBackground(void) {
    return [UIColor colorWithRed:0.055 green:0.012 blue:0.018 alpha:1.00];
}

static UIColor *FFVIPPanel(void) {
    return [UIColor colorWithRed:0.12 green:0.025 blue:0.035 alpha:0.96];
}

static UIColor *FFStatusCyan(void) {
    return [UIColor colorWithRed:1.00 green:0.24 blue:0.28 alpha:1.00];
}

static UIColor *FFPrimaryText(void) {
    return [UIColor colorWithRed:0.96 green:0.98 blue:1.00 alpha:1.00];
}

static UIColor *FFSecondaryText(void) {
    return [UIColor colorWithRed:0.62 green:0.68 blue:0.78 alpha:1.00];
}

static UIColor *FFLilac(void) {
    return [UIColor colorWithRed:0.62 green:0.04 blue:0.08 alpha:1.00];
}

// Visual-only feedback for the existing controls.  These methods never
// replace a button's TouchUpInside selector or change its enabled state.
@interface UIButton (FFCacheManagerVisualFeedback)
- (void)fm_beginVisualFeedback;
- (void)fm_endVisualFeedback;
@end

@implementation UIButton (FFCacheManagerVisualFeedback)
- (void)fm_beginVisualFeedback {
    if (!self.enabled) return;
    [UIView animateWithDuration:0.10
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                     animations:^{ self.transform = CGAffineTransformMakeScale(0.975, 0.975); }
                     completion:nil];
}

- (void)fm_endVisualFeedback {
    [UIView animateWithDuration:0.18
                          delay:0
         usingSpringWithDamping:0.72
          initialSpringVelocity:0.4
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                     animations:^{ self.transform = CGAffineTransformIdentity; }
                     completion:nil];
}
@end

static void FFPrepareExistingButtonForVisualFeedback(UIButton *button) {
    [button addTarget:button action:@selector(fm_beginVisualFeedback)
      forControlEvents:UIControlEventTouchDown];
    [button addTarget:button action:@selector(fm_endVisualFeedback)
      forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside |
                       UIControlEventTouchCancel | UIControlEventTouchDragExit];
}

static NSArray<NSDictionary<NSString *, NSString *> *> *FFSupportedGames(void) {
    static NSArray<NSDictionary<NSString *, NSString *> *> *games;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        games = @[
            @{
                @"id": @"FREE_FIRE_TH",
                @"displayName": @"FREE FIRE TH",
                @"subtitle": @"TH / NORMAL",
                @"bundleIdentifier": FFBundleIDFreeFireTH,
            },
            @{
                @"id": @"FREE_FIRE_MAX",
                @"displayName": @"FREE FIRE MAX",
                @"subtitle": @"MAX",
                @"bundleIdentifier": FFBundleIDFreeFireMAX,
            },
        ];
    });
    return games;
}

static NSDictionary<NSString *, NSString *> *FFGameDefinition(NSString *bundleIdentifier) {
    for (NSDictionary<NSString *, NSString *> *game in FFSupportedGames()) {
        if ([game[@"bundleIdentifier"] isEqualToString:bundleIdentifier]) return game;
    }
    return nil;
}

static NSSet<NSString *> *FFLocalFeaturesForGame(NSString *bundleIdentifier) {
    if ([bundleIdentifier isEqualToString:FFBundleIDFreeFireTH]) {
        // BODY intentionally shares the approved MAX cache payload for TH.
        return [NSSet setWithArray:@[@"BODY", @"NECK"]];
    }
    if ([bundleIdentifier isEqualToString:FFBundleIDFreeFireMAX]) {
        return [NSSet setWithArray:@[@"BODY", @"NECK"]];
    }
    return [NSSet set];
}

#ifdef FM_OFFLINE_BUILD
static NSSet<NSString *> *FFBundledOfflineFeatures(void) {
    // Offline builds always expose the three embedded profiles. Resource
    // existence is validated only when the selected profile is actually read.
    // This prevents signing/repacking tools from making the UI show
    // "NOT IN PLAN" merely because they changed the resource lookup layout.
    static NSSet<NSString *> *features;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        features = [NSSet setWithArray:@[@"BODY", @"NECK"]];
    });
    return features;
}

static NSString *FFOfflineProfilePath(NSString *feature) {
    if (!feature.length) return nil;
    NSBundle *bundle = NSBundle.mainBundle;
    NSFileManager *fm = NSFileManager.defaultManager;
    NSArray<NSString *> *candidates = @[
        [bundle pathForResource:feature ofType:@"ffcache" inDirectory:@"OfflineCache"] ?: @"",
        [bundle pathForResource:feature ofType:@"ffcache"] ?: @"",
        [[bundle resourcePath] stringByAppendingPathComponent:
            [NSString stringWithFormat:@"OfflineCache/%@.ffcache", feature]],
        [[bundle bundlePath] stringByAppendingPathComponent:
            [NSString stringWithFormat:@"OfflineCache/%@.ffcache", feature]],
        [[bundle bundlePath] stringByAppendingPathComponent:
            [NSString stringWithFormat:@"%@.ffcache", feature]],
    ];
    for (NSString *candidate in candidates) {
        if (candidate.length && [fm fileExistsAtPath:candidate]) return candidate;
    }
    return nil;
}
#endif

static NSString *ZXWireFeature(NSString *label) {
    static NSDictionary<NSString *, NSString *> *mapping;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        mapping = @{
            @"BODY": @"P1", @"NECK": @"P3"
        };
    });
    return mapping[label.uppercaseString];
}

static NSString *ZXLabelFeature(NSString *wire) {
    static NSDictionary<NSString *, NSString *> *mapping;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        mapping = @{
            @"P1": @"BODY", @"P3": @"NECK"
        };
    });
    return mapping[wire.uppercaseString];
}

static NSString *FFFeatureDisplayName(NSString *feature) {
    if ([feature isEqualToString:@"HOLOGRAM_GUN"]) return @"HOLOGRAM GUN";
    if ([feature isEqualToString:@"THREE_D"]) return @"3D";
    return feature ?: @"FEATURE";
}

static NSString *ZXPlistDigest(NSDictionary *plist, NSArray<NSString *> *keys) {
    if (![plist isKindOfClass:NSDictionary.class]) return nil;
    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithCapacity:keys.count];
    for (NSString *key in keys) {
        id value = plist[key];
        if (![value isKindOfClass:NSString.class] && ![value isKindOfClass:NSNumber.class]) value = @"";
        [parts addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }
    return ZXDigest([[parts componentsJoinedByString:@"|"] dataUsingEncoding:NSUTF8StringEncoding]);
}

static NSError *FFError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:@"com.acidevloper.ffcache"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

#ifdef FM_OFFLINE_BUILD
static BOOL FF3105MCMInitialize(void) {
    static BOOL available = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        FF3105API.handle = dlopen("/usr/lib/system/libsystem_containermanager.dylib",
                                 RTLD_NOW | RTLD_LOCAL);
        void *lookup = FF3105API.handle ?: RTLD_DEFAULT;
#define FF3105_RESOLVE(field, symbol) FF3105API.field = (typeof(FF3105API.field))dlsym(lookup, symbol)
        FF3105_RESOLVE(queryCreate, "container_query_create");
        FF3105_RESOLVE(querySetClass, "container_query_set_class");
        FF3105_RESOLVE(querySetIdentifiers, "container_query_set_identifiers");
        FF3105_RESOLVE(querySetGroupIdentifiers, "container_query_set_group_identifiers");
        FF3105_RESOLVE(querySetFlags, "container_query_operation_set_flags");
        FF3105_RESOLVE(querySetPart, "container_query_operation_set_part");
        FF3105_RESOLVE(queryGetSingleResult, "container_query_get_single_result");
        FF3105_RESOLVE(queryGetLastError, "container_query_get_last_error");
        FF3105_RESOLVE(queryFree, "container_query_free");
        FF3105_RESOLVE(objectGetPath, "container_object_get_path");
        FF3105_RESOLVE(objectCopy, "container_object_copy");
        FF3105_RESOLVE(copySandboxToken, "container_copy_sandbox_token");
        FF3105_RESOLVE(activateSandboxExtension, "container_object_sandbox_extension_activate");
        FF3105_RESOLVE(objectFree, "container_object_free");
        FF3105_RESOLVE(errorPOSIX, "container_error_get_posix_errno");
        FF3105_RESOLVE(errorMessage, "container_error_get_message");
        FF3105API.xpcStringCreate = (FF3105XPCStringCreateFunction)dlsym(RTLD_DEFAULT, "xpc_string_create");
#undef FF3105_RESOLVE
        available = FF3105API.queryCreate && FF3105API.querySetClass &&
            FF3105API.querySetIdentifiers && FF3105API.querySetFlags &&
            FF3105API.queryGetSingleResult && FF3105API.queryFree &&
            FF3105API.objectGetPath && FF3105API.objectCopy &&
            FF3105API.copySandboxToken && FF3105API.activateSandboxExtension &&
            FF3105API.objectFree && FF3105API.xpcStringCreate;
    });
    return available;
}

static BOOL FF3105SafeIdentifier(NSString *identifier) {
    if (![identifier isKindOfClass:NSString.class] || identifier.length == 0 || identifier.length > 255) return NO;
    static NSCharacterSet *invalid;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *allowed = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_";
        invalid = [[NSCharacterSet characterSetWithCharactersInString:allowed] invertedSet];
    });
    return [identifier rangeOfCharacterFromSet:invalid].location == NSNotFound &&
        ![identifier isEqualToString:@"."] && ![identifier isEqualToString:@".."];
}

static NSString *FF3105LookupFailure(void *query, NSString *fallback) {
    void *containerError = FF3105API.queryGetLastError ? FF3105API.queryGetLastError(query) : NULL;
    int posix = containerError && FF3105API.errorPOSIX ? FF3105API.errorPOSIX(containerError) : 0;
    const char *message = containerError && FF3105API.errorMessage
        ? FF3105API.errorMessage(containerError) : NULL;
    if (message && message[0]) {
        return [NSString stringWithFormat:@"%@ posix=%d message=%s", fallback, posix, message];
    }
    return fallback;
}

@interface FF3105MCMRetainedLease : NSObject {
@public
    void *_query;
    void *_activation;
}
@property(nonatomic, copy) NSString *rootPath;
@property(nonatomic) BOOL activated;
+ (instancetype)leaseForClass:(uint64_t)containerClass
                   identifier:(NSString *)identifier
                        group:(BOOL)group
                       detail:(NSString **)detail;
- (BOOL)activate:(NSString **)detail;
@end

@implementation FF3105MCMRetainedLease
+ (instancetype)leaseForClass:(uint64_t)containerClass
                   identifier:(NSString *)identifier
                        group:(BOOL)group
                       detail:(NSString **)detail {
    if (!FF3105MCMInitialize() || !FF3105SafeIdentifier(identifier)) {
        if (detail) *detail = @"MCM unavailable or identifier contains unsupported characters";
        return nil;
    }
    void *query = FF3105API.queryCreate();
    if (!query) {
        if (detail) *detail = @"query create failed";
        return nil;
    }
    FF3105API.querySetClass(query, containerClass);
    void *xpcIdentifier = FF3105API.xpcStringCreate(identifier.UTF8String);
    if (group && FF3105API.querySetGroupIdentifiers) {
        FF3105API.querySetGroupIdentifiers(query, xpcIdentifier);
    } else {
        FF3105API.querySetIdentifiers(query, xpcIdentifier);
    }
    FF3105API.querySetFlags(query, UINT64_C(0x900000000));
    if (FF3105API.querySetPart) FF3105API.querySetPart(query, 0);

    void *result = FF3105API.queryGetSingleResult(query);
    const char *pathBytes = result ? FF3105API.objectGetPath(result) : NULL;
    NSString *root = pathBytes ? [NSString stringWithUTF8String:pathBytes] : nil;
    if (root.length && ([root isEqualToString:@"/var"] || [root hasPrefix:@"/var/"])) {
        root = [@"/private" stringByAppendingString:root];
    }
    if (!root.length || !root.isAbsolutePath) {
        if (detail) *detail = result
            ? @"MCM returned no absolute container path"
            : FF3105LookupFailure(query, @"MCM lookup failed");
        FF3105API.queryFree(query);
        return nil;
    }
    FF3105MCMRetainedLease *lease = [FF3105MCMRetainedLease new];
    lease->_query = query;
    lease.rootPath = root;
    return lease;
}

- (BOOL)activate:(NSString **)detail {
    if (self.activated) return YES;
    if (!_query) {
        if (detail) *detail = @"lease invalidated";
        return NO;
    }
    void *result = FF3105API.queryGetSingleResult(_query);
    if (result) _activation = FF3105API.objectCopy(result);
    char *token = _activation ? FF3105API.copySandboxToken(_activation) : NULL;
    BOOL hasToken = token && token[0];
    if (token) free(token);
    if (!hasToken) {
        if (detail) *detail = @"MCM object contained no sandbox token";
        return NO;
    }
    self.activated = FF3105API.activateSandboxExtension(_activation, 0);
    if (!self.activated && detail) *detail = @"sandbox extension activation failed";
    return self.activated;
}

- (void)dealloc {
    if (_activation && FF3105API.objectFree) FF3105API.objectFree(_activation);
    if (_query && FF3105API.queryFree) FF3105API.queryFree(_query);
}
@end

static NSString *FF3105MCMContainerPath(NSString *identifier, NSString **detail) {
    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.mobile.MobileHouseArrest"]) {
        if (detail) *detail = @"host bundle identifier is not com.apple.mobile.MobileHouseArrest";
        return nil;
    }
    static NSMutableDictionary<NSString *, FF3105MCMRetainedLease *> *leases;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ leases = [NSMutableDictionary dictionary]; });
    NSString *key = [NSString stringWithFormat:@"2:0:%@", identifier ?: @""];
    @synchronized (leases) {
        FF3105MCMRetainedLease *lease = leases[key];
        if (lease.rootPath.length) return lease.rootPath;
        lease = [FF3105MCMRetainedLease leaseForClass:2
                                           identifier:identifier
                                                group:NO
                                               detail:detail];
        if (!lease || ![lease activate:detail]) return nil;
        int descriptor = open(lease.rootPath.fileSystemRepresentation,
            O_RDONLY | O_DIRECTORY | O_CLOEXEC | O_NOFOLLOW);
        if (descriptor < 0) {
            if (detail) *detail = [NSString stringWithFormat:@"container root open failed errno=%d", errno];
            return nil;
        }
        close(descriptor);
        leases[key] = lease;
        return lease.rootPath;
    }
}
#endif

#ifdef FM_RELEASE_BUILD
#define FFDiagnosticLog(...) ((void)0)
#else
static void FFDiagnosticLog(NSString *component, NSString *format, ...) NS_FORMAT_FUNCTION(2,3);
#endif
static NSError *FFNamedError(NSInteger code, NSString *name, NSString *detail) {
    NSString *message = detail.length ? [NSString stringWithFormat:@"%@: %@", name, detail] : name;
    FFDiagnosticLog(@"ApplyManager", @"%@", message);
    return FFError(code, message);
}

#ifndef FM_RELEASE_BUILD
static void FFDiagnosticLog(NSString *component, NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    NSLog(@"[%@] %@", component ?: @"Compatibility", message ?: @"");
}
#endif

static NSError *FFPOSIXAccessError(NSInteger code, NSString *operation, NSURL *url, int savedErrno) {
    const char *description = strerror(savedErrno);
    NSString *detail = description ? [NSString stringWithUTF8String:description] : @"unknown POSIX error";
    return FFError(code, [NSString stringWithFormat:@"%@ failed for %@ (errno=%d: %@).",
        operation ?: @"Filesystem access", url.path ?: @"selected path", savedErrno, detail]);
}

static NSString *FFKeychainRead(NSString *account) {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: FFKeychainService,
        (__bridge id)kSecAttrAccount: account,
        (__bridge id)kSecReturnData: @YES,
        (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitOne
    };
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess || !result) return nil;
    NSData *data = CFBridgingRelease(result);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

static BOOL FFKeychainWrite(NSString *account, NSString *value) {
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *identity = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: FFKeychainService,
        (__bridge id)kSecAttrAccount: account
    };
    SecItemDelete((__bridge CFDictionaryRef)identity);
    NSMutableDictionary *item = [identity mutableCopy];
    item[(__bridge id)kSecValueData] = data;
    item[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    return SecItemAdd((__bridge CFDictionaryRef)item, NULL) == errSecSuccess;
}

static void FFKeychainDelete(NSString *account) {
    NSDictionary *identity = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: FFKeychainService,
        (__bridge id)kSecAttrAccount: account
    };
    SecItemDelete((__bridge CFDictionaryRef)identity);
}

static void FFClearSession(void) {
    FFKeychainDelete(FFAccessTokenAccount);
    FFKeychainDelete(FFRefreshTokenAccount);
}

static NSString *ZXInstallID(void) {
    NSString *identifier = FFKeychainRead(FFDeviceAccount);
    if (identifier.length >= 16) return identifier;
    identifier = NSUUID.UUID.UUIDString;
    return FFKeychainWrite(FFDeviceAccount, identifier) ? identifier : nil;
}

static uint32_t FFReadBE32(const uint8_t *bytes) {
    return ((uint32_t)bytes[0] << 24) | ((uint32_t)bytes[1] << 16) |
           ((uint32_t)bytes[2] << 8) | (uint32_t)bytes[3];
}

static uint64_t FFReadBE64(const uint8_t *bytes) {
    return ((uint64_t)FFReadBE32(bytes) << 32) | FFReadBE32(bytes + 4);
}

static BOOL FFRangeFits(uint64_t offset, uint64_t size, uint64_t limit) {
    return offset <= limit && size <= limit - offset;
}

static BOOL ZXVerifySlice(NSData *file, uint64_t sliceOffset, uint64_t sliceSize,
                          NSString **textHash, NSString **exportHash, NSString **sectionHash) {
    if (!FFRangeFits(sliceOffset, sliceSize, file.length) || sliceSize < sizeof(struct mach_header_64)) return NO;
    const uint8_t *slice = (const uint8_t *)file.bytes + sliceOffset;
    struct mach_header_64 header;
    memcpy(&header, slice, sizeof(header));
    if (header.magic != MH_MAGIC_64 || !FFRangeFits(sizeof(header), header.sizeofcmds, sliceSize)) return NO;

    uint64_t textOffset = 0, textSize = 0, exportsOffset = 0, exportsSize = 0;
    uint64_t fallbackExportsOffset = 0, fallbackExportsSize = 0;
    NSMutableData *sectionBytesForHash = sectionHash ? [NSMutableData data] : nil;
    uint64_t cursor = sizeof(header);
    for (uint32_t index = 0; index < header.ncmds; index++) {
        if (!FFRangeFits(cursor, sizeof(struct load_command), sliceSize)) return NO;
        struct load_command command;
        memcpy(&command, slice + cursor, sizeof(command));
        if (command.cmdsize < sizeof(command) || !FFRangeFits(cursor, command.cmdsize, sliceSize)) return NO;

        if (command.cmd == LC_SEGMENT_64 && command.cmdsize >= sizeof(struct segment_command_64)) {
            struct segment_command_64 segment;
            memcpy(&segment, slice + cursor, sizeof(segment));
            uint64_t sectionsSize = (uint64_t)segment.nsects * sizeof(struct section_64);
            if (!FFRangeFits(sizeof(segment), sectionsSize, command.cmdsize)) return NO;
            const uint8_t *sectionBytes = slice + cursor + sizeof(segment);
            for (uint32_t sectionIndex = 0; sectionIndex < segment.nsects; sectionIndex++) {
                struct section_64 section;
                memcpy(&section, sectionBytes + sectionIndex * sizeof(section), sizeof(section));
                if (strncmp(section.segname, "__TEXT", 16) == 0 &&
                    strncmp(section.sectname, "__text", 16) == 0) {
                    textOffset = section.offset;
                    textSize = section.size;
                }
                if (sectionHash && section.offset && section.size &&
                    FFRangeFits(section.offset, section.size, sliceSize)) {
                    [sectionBytesForHash appendBytes:slice + section.offset length:(NSUInteger)section.size];
                }
            }
        } else if (command.cmd == LC_DYLD_EXPORTS_TRIE && command.cmdsize >= sizeof(struct linkedit_data_command)) {
            struct linkedit_data_command exports;
            memcpy(&exports, slice + cursor, sizeof(exports));
            exportsOffset = exports.dataoff;
            exportsSize = exports.datasize;
        } else if (command.cmd == LC_DYLD_INFO_ONLY && command.cmdsize >= sizeof(struct dyld_info_command)) {
            struct dyld_info_command info;
            memcpy(&info, slice + cursor, sizeof(info));
            fallbackExportsOffset = info.export_off;
            fallbackExportsSize = info.export_size;
        }
        cursor += command.cmdsize;
    }

    if (!exportsSize) {
        exportsOffset = fallbackExportsOffset;
        exportsSize = fallbackExportsSize;
    }
    if (!textSize || !exportsSize || !FFRangeFits(textOffset, textSize, sliceSize) ||
        !FFRangeFits(exportsOffset, exportsSize, sliceSize)) return NO;

    *textHash = ZXDigest([file subdataWithRange:NSMakeRange((NSUInteger)(sliceOffset + textOffset), (NSUInteger)textSize)]);
    *exportHash = ZXDigest([file subdataWithRange:NSMakeRange((NSUInteger)(sliceOffset + exportsOffset), (NSUInteger)exportsSize)]);
    if (sectionHash) {
        if (!sectionBytesForHash.length) return NO;
        *sectionHash = ZXDigest(sectionBytesForHash);
    }
    return YES;
}

static BOOL FFApplicationSectionHashes(NSData *file, NSString **textHash, NSString **cstringHash) {
    if (file.length < sizeof(struct mach_header_64)) return NO;
    const uint8_t *bytes = file.bytes;
    struct mach_header_64 header;
    memcpy(&header, bytes, sizeof(header));
    if (header.magic != MH_MAGIC_64 || !FFRangeFits(sizeof(header), header.sizeofcmds, file.length)) return NO;
    uint64_t textOffset = 0, textSize = 0, cstringOffset = 0, cstringSize = 0;
    uint64_t cursor = sizeof(header);
    for (uint32_t index = 0; index < header.ncmds; index++) {
        if (!FFRangeFits(cursor, sizeof(struct load_command), file.length)) return NO;
        struct load_command command;
        memcpy(&command, bytes + cursor, sizeof(command));
        if (command.cmdsize < sizeof(command) || !FFRangeFits(cursor, command.cmdsize, file.length)) return NO;
        if (command.cmd == LC_SEGMENT_64 && command.cmdsize >= sizeof(struct segment_command_64)) {
            struct segment_command_64 segment;
            memcpy(&segment, bytes + cursor, sizeof(segment));
            uint64_t sectionsSize = (uint64_t)segment.nsects * sizeof(struct section_64);
            if (!FFRangeFits(sizeof(segment), sectionsSize, command.cmdsize)) return NO;
            const uint8_t *sections = bytes + cursor + sizeof(segment);
            for (uint32_t sectionIndex = 0; sectionIndex < segment.nsects; sectionIndex++) {
                struct section_64 section;
                memcpy(&section, sections + sectionIndex * sizeof(section), sizeof(section));
                if (strncmp(section.segname, "__TEXT", 16) != 0) continue;
                if (strncmp(section.sectname, "__text", 16) == 0) {
                    textOffset = section.offset;
                    textSize = section.size;
                }
                if (strncmp(section.sectname, "__cstring", 16) == 0) {
                    cstringOffset = section.offset;
                    cstringSize = section.size;
                }
            }
        }
        cursor += command.cmdsize;
    }
    // Final distribution signers may legitimately rewrite non-code metadata
    // sections inside __TEXT.  Pin the executable instructions and constant
    // strings directly; neither is part of the code-signature blob and both
    // must remain byte-for-byte stable after a clean signing operation.
    if (!textSize || !cstringSize ||
        !FFRangeFits(textOffset, textSize, file.length) ||
        !FFRangeFits(cstringOffset, cstringSize, file.length)) return NO;
    *textHash = ZXDigest([file subdataWithRange:NSMakeRange((NSUInteger)textOffset, (NSUInteger)textSize)]);
    *cstringHash = ZXDigest([file subdataWithRange:NSMakeRange((NSUInteger)cstringOffset, (NSUInteger)cstringSize)]);
    return YES;
}

static BOOL FFVerifyCoreBinaryAtPath(NSString *path) {
    NSData *file = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
    if (file.length < 8) return NO;
    const uint8_t *bytes = file.bytes;
    uint32_t magic = FFReadBE32(bytes);
    BOOL fat64 = magic == 0xcafebabf;
    if (magic != 0xcafebabe && !fat64) return NO;
    uint32_t count = FFReadBE32(bytes + 4);
    uint64_t entrySize = fat64 ? 32 : 20;
    if (count != 2 || !FFRangeFits(8, (uint64_t)count * entrySize, file.length)) return NO;

    BOOL foundA = NO, foundB = NO;
    for (uint32_t index = 0; index < count; index++) {
        const uint8_t *entry = bytes + 8 + (uint64_t)index * entrySize;
        uint64_t sliceOffset = fat64 ? FFReadBE64(entry + 8) : FFReadBE32(entry + 8);
        uint64_t sliceSize = fat64 ? FFReadBE64(entry + 16) : FFReadBE32(entry + 12);
        NSString *textHash = nil, *exportHash = nil, *sectionHash = nil;
        if (!ZXVerifySlice(file, sliceOffset, sliceSize, &textHash, &exportHash, &sectionHash)) return NO;
        BOOL matchesA = [textHash isEqualToString:FMCORE_TEXT_SHA256_A] &&
                         [exportHash isEqualToString:FMCORE_EXPORT_SHA256_A] &&
                         [sectionHash isEqualToString:FMCORE_SECTION_SHA256_A];
        BOOL matchesB = [textHash isEqualToString:FMCORE_TEXT_SHA256_B] &&
                         [exportHash isEqualToString:FMCORE_EXPORT_SHA256_B] &&
                         [sectionHash isEqualToString:FMCORE_SECTION_SHA256_B];
        if ((!matchesA && !matchesB) || (matchesA && foundA) || (matchesB && foundB)) return NO;
        foundA |= matchesA;
        foundB |= matchesB;
    }
    return foundA && foundB;
}

static NSDictionary *FFIntegrityReport(void) {
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *corePath = [bundle.privateFrameworksPath stringByAppendingPathComponent:@"CoreTelemetry.framework/CoreTelemetry"];
    if (!FFVerifyCoreBinaryAtPath(corePath)) return nil;
    NSData *coreFile = [NSData dataWithContentsOfFile:corePath options:NSDataReadingMappedIfSafe error:nil];
    if (coreFile.length < 8) return nil;
    const uint8_t *coreBytes = coreFile.bytes;
    uint32_t fatMagic = FFReadBE32(coreBytes);
    BOOL fat64 = fatMagic == 0xcafebabf;
    if ((fatMagic != 0xcafebabe && !fat64) || FFReadBE32(coreBytes + 4) != 2) return nil;
    uint64_t entrySize = fat64 ? 32 : 20;
    NSMutableArray<NSDictionary *> *slices = [NSMutableArray arrayWithCapacity:2];
    for (uint32_t index = 0; index < 2; index++) {
        const uint8_t *entry = coreBytes + 8 + (uint64_t)index * entrySize;
        uint64_t offset = fat64 ? FFReadBE64(entry + 8) : FFReadBE32(entry + 8);
        uint64_t size = fat64 ? FFReadBE64(entry + 16) : FFReadBE32(entry + 12);
        NSString *textHash = nil, *exportHash = nil;
        if (!ZXVerifySlice(coreFile, offset, size, &textHash, &exportHash, nil)) return nil;
        [slices addObject:@{ @"text": textHash, @"exports": exportHash }];
    }

    NSData *appFile = [NSData dataWithContentsOfFile:bundle.executablePath options:NSDataReadingMappedIfSafe error:nil];
    NSString *appText = nil, *appCString = nil;
    if (!appFile.length || !FFApplicationSectionHashes(appFile, &appText, &appCString)) return nil;
    NSString *frameworkInfoPath = [bundle.privateFrameworksPath stringByAppendingPathComponent:@"CoreTelemetry.framework/Info.plist"];
    NSDictionary *info = bundle.infoDictionary;
    NSDictionary *frameworkInfo = [NSDictionary dictionaryWithContentsOfFile:frameworkInfoPath];
    NSString *displayName = info[@"CFBundleDisplayName"] ?: info[@"CFBundleName"];
    NSString *infoHash = ZXPlistDigest(info, @[
        @"CFBundleDisplayName", @"CFBundleExecutable", @"CFBundleIdentifier", @"CFBundleName",
        @"CFBundlePackageType", @"CFBundleShortVersionString", @"CFBundleVersion", @"MinimumOSVersion"
    ]);
    NSString *frameworkInfoHash = ZXPlistDigest(frameworkInfo, @[
        @"CFBundleExecutable", @"CFBundleIdentifier", @"CFBundleName", @"CFBundlePackageType",
        @"CFBundleShortVersionString", @"CFBundleVersion", @"MinimumOSVersion"
    ]);
    if (!infoHash.length || !frameworkInfoHash.length || !bundle.bundleIdentifier.length || !displayName.length) return nil;
    return @{
        @"app_text_sha256": appText,
        @"app_cstring_sha256": appCString,
        @"core_a_text_sha256": slices[0][@"text"],
        @"core_a_export_sha256": slices[0][@"exports"],
        @"core_b_text_sha256": slices[1][@"text"],
        @"core_b_export_sha256": slices[1][@"exports"],
        @"info_plist_sha256": infoHash,
        @"framework_plist_sha256": frameworkInfoHash,
        @"bundle_identifier": bundle.bundleIdentifier,
        @"display_name": displayName,
        @"app_version": info[@"CFBundleShortVersionString"] ?: @"",
        @"build_version": info[@"CFBundleVersion"] ?: @""
    };
}

static BOOL FFLoadSandboxBridge(NSError **error) {
    if (FFProtectedCoreHandle && FFMCMStart && FFMCMDataContainerPath) return YES;
    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.mobile.MobileHouseArrest"]) {
        if (error) *error = FFError(2, @"This build's required runtime identity is unavailable.");
        return NO;
    }
    NSString *frameworkPath = [NSBundle.mainBundle.privateFrameworksPath stringByAppendingPathComponent:@"CoreTelemetry.framework"];
    NSString *executablePath = [frameworkPath stringByAppendingPathComponent:@"CoreTelemetry"];
    if (!FFVerifyCoreBinaryAtPath(executablePath)) {
        if (error) *error = FFError(3, @"Protected core integrity verification failed.");
        return NO;
    }
    FFProtectedCoreHandle = dlopen(executablePath.fileSystemRepresentation, RTLD_NOW | RTLD_GLOBAL);
    if (!FFProtectedCoreHandle) {
        const char *detail = dlerror();
        if (error) *error = FFError(4, [NSString stringWithFormat:@"Protected core failed to load: %s", detail ?: "unknown"]);
        return NO;
    }
    FFMCMStart = (MCMFilzaStartFunction)dlsym(FFProtectedCoreHandle, "FKX0A7Q2M9Z");
    FFMCMDataContainerPath = (MCMFilzaDataContainerPathFunction)dlsym(FFProtectedCoreHandle, "FKX1R4V8N6P");
    FFMCMSetUnrestrictedFilesystem = (MCMFilzaSetUnrestrictedFilesystemFunction)dlsym(FFProtectedCoreHandle, "FKX2C5J9T3W");
    // FilzaSlop 1.0.3 keeps this read-only helper exported. It exposes only
    // the bridge's own virtual root, which lets us use its iOS 18 fallback
    // links without constructing arbitrary filesystem paths.
    FFMCMVirtualRoot = (MCMFilzaVirtualRootFunction)dlsym(FFProtectedCoreHandle, "FKX3D8H4K7R");
    if (!FFMCMStart || !FFMCMDataContainerPath || !FFMCMSetUnrestrictedFilesystem) {
        if (error) *error = FFError(5, @"Protected core APIs are incomplete.");
        return NO;
    }
    // MCMFilzaStart builds its Device Storage links only once. Set this before
    // starting the bridge so iOS 18 can enumerate the class-2 App Data links
    // instead of pruning them during its first start.
    FFMCMSetUnrestrictedFilesystem(YES);
    FFMCMStart();
    return YES;
}

static NSArray<NSString *> *FFGameContainerCandidates(NSString *selectedGameIdentifier,
                                                       NSString **lookupDetail) {
    NSMutableOrderedSet<NSString *> *paths = [NSMutableOrderedSet orderedSet];
#ifdef FM_OFFLINE_BUILD
    NSString *exact3105Detail = nil;
    NSString *exact3105 = FF3105MCMContainerPath(selectedGameIdentifier, &exact3105Detail);
    if (exact3105.length) [paths addObject:exact3105];
    if (lookupDetail && exact3105Detail.length) *lookupDetail = exact3105Detail;
#endif

    NSError *bridgeError = nil;
    if (FFLoadSandboxBridge(&bridgeError)) {
        NSString *direct = FFMCMDataContainerPath(selectedGameIdentifier, lookupDetail);
        if (direct.length) [paths addObject:direct];
    } else if (lookupDetail && !(*lookupDetail).length) {
        *lookupDetail = bridgeError.localizedDescription;
    }

    // A direct MCM lookup can return no path even when this existing bridge
    // exposes its own virtual root. Probe the exported capability instead of
    // routing by an OS-version number; every candidate is verified later by
    // AccessVerifier before it can become CONNECTED/READY.
    if (FFMCMVirtualRoot) {
        NSString *root = FFMCMVirtualRoot();
        if (root.length && root.isAbsolutePath) {
            // FilzaSlop 1.0.3 creates this class-2 directory when started with
            // unrestricted enumeration. Keep the legacy name as a read-only
            // fallback for devices that already have a pre-migration root.
            for (NSString *directoryName in @[@"[MHA-C2] App Data", @"App Data"]) {
                NSString *appData = [root stringByAppendingPathComponent:directoryName];
                NSString *linked = [appData stringByAppendingPathComponent:selectedGameIdentifier];
                if (linked.length) [paths addObject:linked];
            }
        }
    }
    return paths.array;
}

static NSURL *FFDirectGameContainer(NSString *selectedGameIdentifier,
                                    NSString **gameIdentifier, NSString **gameName,
                                    NSURL **assetBundles, NSError **error) {
    NSDictionary<NSString *, NSString *> *game = FFGameDefinition(selectedGameIdentifier);
    if (!game) {
        if (error) *error = FFError(5, @"Select a supported game first.");
        return nil;
    }
    NSString *lookupDetail = nil;
    NSURL *foundContainer = nil;
    NSError *assetBundleError = nil;
    NSFileManager *manager = NSFileManager.defaultManager;
    for (NSString *containerPath in FFGameContainerCandidates(selectedGameIdentifier, &lookupDetail)) {
        NSURL *container = [NSURL fileURLWithPath:containerPath isDirectory:YES];
        BOOL isDirectory = NO;
        if (![manager fileExistsAtPath:container.path isDirectory:&isDirectory] || !isDirectory) continue;
        if (!foundContainer) foundContainer = container;
        NSError *candidateError = nil;
        NSURL *directory = FFFindGameAssetBundles(container, &candidateError);
        if (directory) {
            if (gameIdentifier) *gameIdentifier = selectedGameIdentifier;
            if (gameName) *gameName = game[@"displayName"];
            if (assetBundles) *assetBundles = directory;
            return container;
        }
        if (!assetBundleError) assetBundleError = candidateError;
    }
    if (foundContainer) {
        // A valid class-2 container proves that the game is installed. The
        // cache may not exist until the game has completed its first launch,
        // so do not report a false "GAME NOT INSTALLED" result on iOS 18.
        if (gameIdentifier) *gameIdentifier = selectedGameIdentifier;
        if (gameName) *gameName = game[@"displayName"];
        if (assetBundles) *assetBundles = nil;
        if (error) *error = assetBundleError ?: FFError(10, @"Game cache is not ready yet.");
        return foundContainer;
    }
    NSString *message = [NSString stringWithFormat:@"%@ is not installed or its container is not available yet.", game[@"displayName"]];
    if (lookupDetail.length) message = [message stringByAppendingFormat:@"\n%@", lookupDetail];
    if (error) *error = FFError(5, message);
    return nil;
}

static NSURL *FFDirectGameAssetBundles(NSString *selectedGameIdentifier,
                                       NSString **gameIdentifier, NSString **gameName, NSError **error) {
    NSURL *directory = nil;
    FFDirectGameContainer(selectedGameIdentifier, gameIdentifier, gameName, &directory, error);
    return directory;
}

static BOOL FFLaunchGame(NSString *gameIdentifier, NSError **error) {
    if (!FFGameDefinition(gameIdentifier)) {
        if (error) *error = FFError(54, @"Select a supported game first.");
        return NO;
    }
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    SEL defaultSelector = NSSelectorFromString(@"defaultWorkspace");
    SEL openSelector = NSSelectorFromString(@"openApplicationWithBundleID:");
    if (!workspaceClass || ![workspaceClass respondsToSelector:defaultSelector]) {
        if (error) *error = FFError(54, @"Game launcher is unavailable on this installation.");
        return NO;
    }
    id (*sendWorkspace)(id, SEL) = (void *)objc_msgSend;
    BOOL (*sendOpen)(id, SEL, id) = (void *)objc_msgSend;
    id workspace = sendWorkspace((id)workspaceClass, defaultSelector);
    if (!workspace || ![workspace respondsToSelector:openSelector] ||
        !sendOpen(workspace, openSelector, gameIdentifier)) {
        if (error) *error = FFError(54, @"GAME NOT INSTALLED");
        return NO;
    }
    return YES;
}

static BOOL FFDataLooksLikeUnityBundle(NSData *data) {
    if (data.length < 8) return NO;
    const unsigned char expected[] = {'U','n','i','t','y','F','S',0};
    return memcmp(data.bytes, expected, sizeof(expected)) == 0;
}

static NSString *ZXDigest(NSData *data) {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) [hex appendFormat:@"%02x", digest[index]];
    return hex;
}

static NSString *FFHardwareModel(void) {
    struct utsname systemInfo;
    if (uname(&systemInfo) != 0) return @"unknown";
    return [NSString stringWithUTF8String:systemInfo.machine] ?: @"unknown";
}

static NSString *FFAPIErrorMessage(NSDictionary *json, NSString *fallback) {
    id value = [json isKindOfClass:NSDictionary.class] ? json[@"error"] : nil;
    if ([value isKindOfClass:NSString.class] && [value length]) return value;
    if ([value isKindOfClass:NSDictionary.class]) {
        NSString *message = value[@"message"];
        if ([message isKindOfClass:NSString.class] && message.length) return message;
    }
    return fallback;
}

// ---------------------------------------------------------------------------
// Response signing verification (RSA-2048 PSS-SHA256).
//
// The server wraps critical responses as
//   { "data": {...}, "sig_alg": "RSA-PSS-SHA256",
//     "sig_ts": <epoch>, "sig_nonce": <hex>, "sig": <base64> }
// Signing input is exactly "<sig_ts>|<sig_nonce>|<canonical_json(data)>".
//
// Release builds define FM_REQUIRE_SIGNED_RESPONSES and fail closed when a
// successful JSON response is unsigned, stale, malformed, or invalid.
// ---------------------------------------------------------------------------
static NSString *const FFResponseSigningPublicKeyPEM =
    @"-----BEGIN PUBLIC KEY-----\n"
    @"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv6fKqN4As200Hw23IjN4\n"
    @"IU6+YmnTKgLhxnFDvHcT8yNZEfr6U/p/PHjakdRt388aT/KIrvtPs59sB6yRnt5t\n"
    @"28CXj+FzMGAelu10fWkagiImln4sM/VAAxV+l8KOePMsv77SL0uUbhwM8kLyweEY\n"
    @"JhCVXTS13YUdJWgVAy3B9DX46cc58cdVvMNixpO0h2VkK9HKQTr1RzXM8sQMKWMZ\n"
    @"AFBkt1AzBZZSeHkQbuPu+2vPV7TUBWsgKUhZfrwHFbF3XAzzokAhlje9q2QbarQK\n"
    @"aqKcNCiRG8njxDNUq3BzFk0qIn3vCSDJSWyoQQDYI8SnUbBxBxqYwY0taA1ZmBlK\n"
    @"xwIDAQAB\n"
    @"-----END PUBLIC KEY-----";

static SecKeyRef FFLoadSigningPublicKey(void) {
    static SecKeyRef cached = NULL;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *pem = FFResponseSigningPublicKeyPEM;
        NSMutableString *body = [pem mutableCopy];
        [body replaceOccurrencesOfString:@"-----BEGIN PUBLIC KEY-----" withString:@""
                                 options:0 range:NSMakeRange(0, body.length)];
        [body replaceOccurrencesOfString:@"-----END PUBLIC KEY-----" withString:@""
                                 options:0 range:NSMakeRange(0, body.length)];
        [body replaceOccurrencesOfString:@"\n" withString:@""
                                 options:0 range:NSMakeRange(0, body.length)];
        [body replaceOccurrencesOfString:@"\r" withString:@""
                                 options:0 range:NSMakeRange(0, body.length)];
        [body replaceOccurrencesOfString:@" " withString:@""
                                 options:0 range:NSMakeRange(0, body.length)];
        NSData *spki = [[NSData alloc] initWithBase64EncodedString:body options:0];
        if (spki.length <= 24) return;
        // Strip the fixed 24-byte SubjectPublicKeyInfo header for RSA-2048 so
        // SecKeyCreateWithData sees a raw PKCS#1 RSAPublicKey.
        NSData *pkcs1 = [spki subdataWithRange:NSMakeRange(24, spki.length - 24)];
        NSDictionary *attrs = @{
            (__bridge id)kSecAttrKeyType:  (__bridge id)kSecAttrKeyTypeRSA,
            (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPublic,
            (__bridge id)kSecAttrKeySizeInBits: @2048,
        };
        CFErrorRef err = NULL;
        cached = SecKeyCreateWithData((__bridge CFDataRef)pkcs1, (__bridge CFDictionaryRef)attrs, &err);
        if (err) CFRelease(err);
    });
    return cached;
}

static NSDictionary *FFVerifySignedResponse(NSDictionary *envelope, NSError **error) {
    NSString *sigAlg = envelope[@"sig_alg"];
    if (![sigAlg isEqualToString:@"RSA-PSS-SHA256"]) {
        if (error) *error = FFError(60, @"Server signature algorithm is unsupported.");
        return nil;
    }
    NSDictionary *data = envelope[@"data"];
    NSNumber *tsNum   = envelope[@"sig_ts"];
    NSString *nonce   = envelope[@"sig_nonce"];
    NSString *sigB64  = envelope[@"sig"];
    if (![data isKindOfClass:NSDictionary.class] || ![tsNum isKindOfClass:NSNumber.class] ||
        ![nonce isKindOfClass:NSString.class]    || ![sigB64 isKindOfClass:NSString.class]) {
        if (error) *error = FFError(61, @"Server signature envelope is malformed.");
        return nil;
    }
    NSTimeInterval ts  = tsNum.doubleValue;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (fabs(now - ts) > 300.0) {
        if (error) *error = FFError(62, @"Server response is outside the allowed clock window.");
        return nil;
    }
    NSData *canonical = [NSJSONSerialization dataWithJSONObject:data
        options:NSJSONWritingSortedKeys error:nil];
    if (!canonical) {
        if (error) *error = FFError(63, @"Could not canonicalize the server response.");
        return nil;
    }
    NSString *canonicalString = [[NSString alloc] initWithData:canonical encoding:NSUTF8StringEncoding];
    NSString *signingInput = [NSString stringWithFormat:@"%lld|%@|%@",
        (long long)ts, nonce, canonicalString];
    NSData *inputBytes = [signingInput dataUsingEncoding:NSUTF8StringEncoding];
    NSData *sigBytes = [[NSData alloc] initWithBase64EncodedString:sigB64 options:0];
    if (!sigBytes.length || !inputBytes.length) {
        if (error) *error = FFError(64, @"Server signature payload is malformed.");
        return nil;
    }
    SecKeyRef key = FFLoadSigningPublicKey();
    if (!key) {
        if (error) *error = FFError(65, @"Server signing key is unavailable to the app.");
        return nil;
    }
    CFErrorRef verifyErr = NULL;
    Boolean ok = SecKeyVerifySignature(key, kSecKeyAlgorithmRSASignatureMessagePSSSHA256,
                                       (__bridge CFDataRef)inputBytes,
                                       (__bridge CFDataRef)sigBytes, &verifyErr);
    if (verifyErr) CFRelease(verifyErr);
    if (!ok) {
        if (error) *error = FFError(66, @"Server signature verification failed.");
        return nil;
    }
    return data;
}

static void FFJSONRequest(NSString *method, NSString *path, NSDictionary *body, NSString *accessToken,
                          void (^completion)(NSDictionary *json, NSError *error)) {
    NSString *installationID = ZXInstallID();
    if (!installationID.length) {
        completion(nil, FFError(30, @"Installation identity is unavailable."));
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
        [NSURL URLWithString:[FFAPIBaseURL() stringByAppendingString:path]]
        cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    request.HTTPMethod = method;
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:installationID forHTTPHeaderField:@"X-Installation-ID"];
    if (accessToken.length) {
        [request setValue:[@"Bearer " stringByAppendingString:accessToken] forHTTPHeaderField:@"Authorization"];
    }
    if (body) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
        if (!request.HTTPBody) {
            completion(nil, FFError(31, @"Could not create the secure request."));
            return;
        }
    }
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
            if (networkError) {
                completion(nil, FFError(32, @"Activation server is unavailable. Check the internet connection."));
                return;
            }
            NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
            NSDictionary *json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            if (http.statusCode < 200 || http.statusCode >= 300) {
                completion(nil, FFError(33, FFAPIErrorMessage(json, @"Server authorization failed.")));
                return;
            }
            if ([json isKindOfClass:NSDictionary.class] && json[@"sig_alg"]) {
                NSError *sigErr = nil;
                NSDictionary *verified = FFVerifySignedResponse(json, &sigErr);
                if (sigErr || !verified) {
                    completion(nil, sigErr ?: FFError(67, @"Server signature verification failed."));
                    return;
                }
                json = verified;
            }
#ifdef FM_REQUIRE_SIGNED_RESPONSES
            else {
                completion(nil, FFError(68, @"Server response is unsigned but signing is required."));
                return;
            }
#endif
            if (![json isKindOfClass:NSDictionary.class] || ![json[@"success"] boolValue]) {
                completion(nil, FFError(34, @"Activation server returned an invalid response."));
                return;
            }
            completion(json, nil);
        }];
    [task resume];
}

static NSArray<NSString *> *FFIntegrityFieldOrder(void) {
    return @[
        @"app_text_sha256", @"app_cstring_sha256",
        @"core_a_text_sha256", @"core_a_export_sha256",
        @"core_b_text_sha256", @"core_b_export_sha256",
        @"info_plist_sha256", @"framework_plist_sha256",
        @"bundle_identifier", @"display_name", @"app_version", @"build_version"
    ];
}

static void ZXProof(NSString *purpose, NSString *context,
                    void (^completion)(NSDictionary *proof, NSError *error)) {
    NSDictionary *integrity = FFIntegrityReport();
    NSString *installationID = ZXInstallID();
    if (!integrity || !installationID.length) {
        completion(nil, FFError(43, @"Application integrity measurement failed."));
        return;
    }
    NSString *safeContext = context ?: @"";
    FFJSONRequest(@"POST", @"/integrity/challenge", @{
        @"installation_id": installationID,
        @"purpose": purpose,
        @"context": safeContext
    }, nil, ^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }
        NSString *challenge = [json[@"challenge"] isKindOfClass:NSString.class] ? json[@"challenge"] : nil;
        if (!challenge.length) {
            completion(nil, FFError(44, @"Security challenge response is invalid."));
            return;
        }
        NSMutableArray<NSString *> *values = [NSMutableArray array];
        for (NSString *field in FFIntegrityFieldOrder()) [values addObject:integrity[field] ?: @""];
        NSString *fingerprint = ZXDigest([[values componentsJoinedByString:@"|"] dataUsingEncoding:NSUTF8StringEncoding]);
        NSString *binding = [NSString stringWithFormat:@"%@|%@|%@|%@|%@",
            challenge, purpose, installationID, safeContext, fingerprint];
        NSString *requestHash = ZXDigest([binding dataUsingEncoding:NSUTF8StringEncoding]);
        completion(@{
            @"challenge": challenge,
            @"request_hash": requestHash,
            @"integrity": integrity
        }, nil);
    });
}

static BOOL ZXPersist(NSDictionary *session) {
    NSString *accessToken = [session[@"access_token"] isKindOfClass:NSString.class] ? session[@"access_token"] : nil;
    NSString *refreshToken = [session[@"refresh_token"] isKindOfClass:NSString.class] ? session[@"refresh_token"] : nil;
    if (![accessToken hasPrefix:@"ffa_"] || ![refreshToken hasPrefix:@"ffr_"]) return NO;
    if (!FFKeychainWrite(FFAccessTokenAccount, accessToken)) return NO;
    if (!FFKeychainWrite(FFRefreshTokenAccount, refreshToken)) {
        FFClearSession();
        return NO;
    }
    return YES;
}

static void FFActivateLicense(NSString *licenseKey, void (^completion)(NSDictionary *response, NSError *error)) {
    NSString *trimmed = [licenseKey stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *installationID = ZXInstallID();
    if (!trimmed.length || !installationID.length) {
        completion(nil, FFError(35, @"Enter the owner license key."));
        return;
    }
    ZXProof(@"activation", @"", ^(NSDictionary *proof, NSError *proofError) {
        if (proofError) {
            completion(nil, proofError);
            return;
        }
        NSDictionary *payload = @{
            @"license_key": trimmed,
            @"installation_id": installationID,
            @"device_model": FFHardwareModel(),
            @"ios_version": UIDevice.currentDevice.systemVersion ?: @"unknown",
            @"app_version": NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"] ?: @"unknown",
            @"proof": proof
        };
        FFJSONRequest(@"POST", @"/license/activate", payload, nil, completion);
    });
}

static void ZXRenew(void (^completion)(NSDictionary *response, NSError *error)) {
    NSString *refreshToken = FFKeychainRead(FFRefreshTokenAccount);
    NSString *installationID = ZXInstallID();
    if (!refreshToken.length || !installationID.length) {
        completion(nil, FFError(36, @"Session refresh is unavailable. Activate the license again."));
        return;
    }
    ZXProof(@"refresh", @"", ^(NSDictionary *proof, NSError *proofError) {
        if (proofError) {
            completion(nil, proofError);
            return;
        }
        FFJSONRequest(@"POST", @"/session/refresh", @{
            @"refresh_token": refreshToken,
            @"installation_id": installationID,
            @"proof": proof
        }, nil, completion);
    });
}

static void FFValidateSession(NSString *accessToken, void (^completion)(NSDictionary *response, NSError *error)) {
    if (!accessToken.length) {
        completion(nil, FFError(37, @"Session is unavailable."));
        return;
    }
    FFJSONRequest(@"GET", @"/session/validate", nil, accessToken, completion);
}

static void FFLogoutSession(NSString *accessToken, void (^completion)(NSError *error)) {
    if (!accessToken.length) {
        if (completion) completion(nil);
        return;
    }
    FFJSONRequest(@"POST", @"/session/logout", @{}, accessToken,
        ^(NSDictionary *response, NSError *error) {
            (void)response;
            if (completion) completion(error);
        });
}

static void FFFetchServiceStatus(void (^completion)(NSDictionary *response, NSError *error)) {
    FFJSONRequest(@"GET", @"/status", nil, nil, completion);
}

static void FFFetchFeatureCatalog(NSString *gameIdentifier, NSString *accessToken,
                                  void (^completion)(NSSet<NSString *> *planFeatures,
                                                     NSSet<NSString *> *serverFeatures,
                                                     NSError *error)) {
    if (!FFGameDefinition(gameIdentifier) || !accessToken.length) {
        completion(nil, nil, FFError(38, @"A supported game and active session are required."));
        return;
    }
    NSString *escapedGame = [gameIdentifier stringByAddingPercentEncodingWithAllowedCharacters:
        NSCharacterSet.URLQueryAllowedCharacterSet];
    NSString *path = [NSString stringWithFormat:@"/feature/catalog?game=%@", escapedGame ?: @""];
    FFJSONRequest(@"GET", path, nil, accessToken, ^(NSDictionary *json, NSError *error) {
        if (error) {
            completion(nil, nil, error);
            return;
        }
        NSDictionary *game = [json[@"game"] isKindOfClass:NSDictionary.class] ? json[@"game"] : nil;
        NSString *responseGame = [game[@"bundle_identifier"] isKindOfClass:NSString.class]
            ? game[@"bundle_identifier"] : nil;
        NSArray *rows = [game[@"features"] isKindOfClass:NSArray.class] ? game[@"features"] : nil;
        if (![responseGame isEqualToString:gameIdentifier] || !rows) {
            completion(nil, nil, FFError(38, @"Feature catalog response is invalid."));
            return;
        }
        NSMutableSet<NSString *> *plan = [NSMutableSet set];
        NSMutableSet<NSString *> *available = [NSMutableSet set];
        NSSet<NSString *> *local = FFLocalFeaturesForGame(gameIdentifier);
        for (NSDictionary *row in rows) {
            if (![row isKindOfClass:NSDictionary.class]) continue;
            NSString *wire = [row[@"id"] isKindOfClass:NSString.class] ? row[@"id"] : nil;
            NSString *feature = ZXLabelFeature(wire) ?: ([local containsObject:wire] ? wire : nil);
            if (!feature || ![local containsObject:feature]) continue;
            if ([row[@"plan_authorized"] boolValue]) [plan addObject:feature];
            if ([row[@"server_available"] boolValue]) [available addObject:feature];
        }
        completion(plan, available, nil);
    });
}

static BOOL ZXIsSHA256(NSString *value);

static void ZXGrant(NSString *feature, NSString *gameIdentifier, NSString *accessToken,
                    void (^completion)(NSString *featureToken, NSString *profileHash, NSError *error)) {
    NSString *wireFeature = ZXWireFeature(feature);
    if (!wireFeature.length || !FFGameDefinition(gameIdentifier) ||
        ![FFLocalFeaturesForGame(gameIdentifier) containsObject:feature]) {
        completion(nil, nil, FFError(38, @"Option authorization response is invalid."));
        return;
    }
#ifdef FM_OFFLINE_BUILD
    (void)accessToken;
    completion(@"ffg_offline", nil, nil);
    return;
#endif
    NSString *context = [NSString stringWithFormat:@"%@|%@", gameIdentifier, wireFeature];
    ZXProof(@"feature", context, ^(NSDictionary *proof, NSError *proofError) {
        if (proofError) {
            completion(nil, nil, proofError);
            return;
        }
        FFJSONRequest(@"POST", @"/feature/authorize", @{
            @"feature": wireFeature, @"game": gameIdentifier, @"proof": proof
        }, accessToken, ^(NSDictionary *json, NSError *error) {
            if (error) {
                completion(nil, nil, error);
                return;
            }
            NSDictionary *authorization = [json[@"authorization"] isKindOfClass:NSDictionary.class] ? json[@"authorization"] : nil;
            NSString *token = [authorization[@"token"] isKindOfClass:NSString.class] ? authorization[@"token"] : nil;
            NSString *authorizedGame = [authorization[@"game"] isKindOfClass:NSString.class] ? authorization[@"game"] : nil;
            NSString *authorizedFeature = [authorization[@"feature"] isKindOfClass:NSString.class] ? authorization[@"feature"] : nil;
            NSString *profileHash = [authorization[@"profile_sha256"] isKindOfClass:NSString.class]
                ? [authorization[@"profile_sha256"] lowercaseString] : nil;
            if (![token hasPrefix:@"ffg_"] || ![authorizedGame isEqualToString:gameIdentifier] ||
                ![authorizedFeature isEqualToString:wireFeature] || !ZXIsSHA256(profileHash)) {
                completion(nil, nil, FFError(38, @"Feature authorization response is invalid."));
                return;
            }
            completion(token, profileHash, nil);
        });
    });
}

static void ZXFetch(NSString *feature, NSString *gameIdentifier, NSString *color, NSString *expectedHash,
                    NSString *accessToken, NSString *featureToken,
                    void (^completion)(NSData *data, NSError *error)) {
#ifdef FM_OFFLINE_BUILD
    (void)accessToken; (void)featureToken; (void)color; (void)expectedHash;
    if (!FFGameDefinition(gameIdentifier) ||
        ![FFLocalFeaturesForGame(gameIdentifier) containsObject:feature]) {
        completion(nil, FFError(39, @"Feature is not available for the selected game."));
        return;
    }
    // Keep data resources extension-qualified.  ESign and similar tools scan
    // extensionless bundle files as candidate Mach-O executables; naming a
    // UnityFS payload BODY/NECK without an extension makes those signers
    // reject the whole .app before certificate selection.
    NSString *offlinePath = FFOfflineProfilePath(feature);
    NSData *offlineData = offlinePath ? [NSData dataWithContentsOfFile:offlinePath] : nil;
    if (!offlineData.length) {
        completion(nil, FFError(40, @"Offline profile not bundled for this feature."));
        return;
    }
    if (![feature isEqualToString:@"HOLOGRAM_GUN"] && !FFDataLooksLikeUnityBundle(offlineData)) {
        completion(nil, FFError(42, @"Bundled offline profile is not a valid UnityFS cache."));
        return;
    }
    completion(offlineData, nil);
    return;
#endif
    NSString *installationID = ZXInstallID();
    NSString *wireFeature = ZXWireFeature(feature);
    if (!installationID.length || !accessToken.length || !featureToken.length ||
        !FFGameDefinition(gameIdentifier) ||
        ![FFLocalFeaturesForGame(gameIdentifier) containsObject:feature]) {
        completion(nil, FFError(39, @"Feature authorization is required."));
        return;
    }
    if (!wireFeature.length) {
        completion(nil, FFError(39, @"Option authorization is unavailable."));
        return;
    }
    NSString *escapedGame = [gameIdentifier stringByAddingPercentEncodingWithAllowedCharacters:
        NSCharacterSet.URLQueryAllowedCharacterSet];
    NSString *endpoint = [NSString stringWithFormat:@"%@/profile/%@?game=%@",
        FFAPIBaseURL(), wireFeature, escapedGame ?: @""];
    if (color.length) {
        NSString *escapedColor = [color stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
        endpoint = [endpoint stringByAppendingFormat:@"&color=%@", escapedColor ?: @""];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:endpoint]
        cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    [request setValue:[@"Bearer " stringByAppendingString:accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:installationID forHTTPHeaderField:@"X-Installation-ID"];
    [request setValue:featureToken forHTTPHeaderField:@"X-Feature-Token"];
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
            if (networkError) {
                completion(nil, FFError(40, @"Could not download the selected option."));
                return;
            }
            NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
            if (http.statusCode < 200 || http.statusCode >= 300) {
                NSDictionary *json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
                completion(nil, FFError(41, FFAPIErrorMessage(json, @"The selected option is unavailable.")));
                return;
            }
            NSString *normalized = feature.uppercaseString;
            NSString *serverHash = [[http valueForHTTPHeaderField:@"X-Profile-SHA256"] lowercaseString];
            NSString *responseGame = [http valueForHTTPHeaderField:@"X-Game-Identifier"];
            // The feature-authorization response is RSA-signed and contains
            // this digest. It is the source of truth for a cache published by
            // the owner bot; raw download headers are only checked to match it.
            NSString *signedHash = expectedHash.lowercaseString;
            NSString *actualHash = [ZXDigest(data) lowercaseString];
            BOOL validFormat = NO;
            if ([@[@"BODY", @"NECK"] containsObject:normalized]) {
                validFormat = data.length >= 40000 && data.length <= (2 * 1024 * 1024) && FFDataLooksLikeUnityBundle(data);
            } else if ([normalized isEqualToString:@"HOLOGRAM_GUN"]) {
                validFormat = data.length > 1000000 && data.length < 30000000 &&
                    memcmp(data.bytes, "FFPKG001", 8) == 0;
            } else if ([normalized isEqualToString:@"THREE_D"]) {
                validFormat = data.length >= 100000 && data.length <= 2000000 &&
                    FFDataLooksLikeUnityBundle(data);
            }
            if (!validFormat || !ZXIsSHA256(serverHash) || !ZXIsSHA256(signedHash) ||
                ![responseGame isEqualToString:gameIdentifier] ||
                ![actualHash isEqualToString:signedHash] ||
                ![serverHash isEqualToString:actualHash]) {
                completion(nil, FFError(42, @"Downloaded option failed integrity validation."));
                return;
            }
            completion(data, nil);
        }];
    [task resume];
}

static BOOL ZXIsSHA256(NSString *value) {
    if (value.length != 64) return NO;
    NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet];
    return [[value lowercaseString] rangeOfCharacterFromSet:invalid].location == NSNotFound;
}

static void ZXFeatureColors(NSString *feature, NSString *gameIdentifier, NSString *accessToken,
                            void (^completion)(NSArray<NSDictionary *> *colors, NSError *error)) {
    NSString *installationID = ZXInstallID();
    BOOL hologram = [feature isEqualToString:@"HOLOGRAM_GUN"];
    BOOL threeD = [feature isEqualToString:@"THREE_D"];
    if (!installationID.length || !accessToken.length || (!hologram && !threeD) ||
        (hologram && ![gameIdentifier isEqualToString:FFBundleIDFreeFireTH]) ||
        !FFGameDefinition(gameIdentifier)) {
        completion(nil, FFError(39, @"Feature authorization is required."));
        return;
    }
    NSString *escapedGame = [gameIdentifier stringByAddingPercentEncodingWithAllowedCharacters:
        NSCharacterSet.URLQueryAllowedCharacterSet];
    NSString *route = hologram ? @"hologram" : @"3d";
    NSString *display = hologram ? @"Hologram" : @"3D";
    NSURL *url = [NSURL URLWithString:[FFAPIBaseURL() stringByAppendingFormat:
        @"/%@/colors?game=%@", route, escapedGame ?: @""]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
        cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    [request setValue:[@"Bearer " stringByAppendingString:accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:installationID forHTTPHeaderField:@"X-Installation-ID"];
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
            if (networkError) {
                completion(nil, FFError(40, [NSString stringWithFormat:@"Could not load %@ options.", display]));
                return;
            }
            NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
            NSDictionary *json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            if (http.statusCode < 200 || http.statusCode >= 300) {
                completion(nil, FFError(41, FFAPIErrorMessage(json,
                    [NSString stringWithFormat:@"%@ options are unavailable.", display])));
                return;
            }
            NSArray *rows = [json[@"colors"] isKindOfClass:NSArray.class] ? json[@"colors"] : nil;
            NSString *responseGame = [json[@"game"] isKindOfClass:NSString.class] ? json[@"game"] : nil;
            if (![responseGame isEqualToString:gameIdentifier]) {
                completion(nil, FFError(41, [NSString stringWithFormat:@"%@ game validation failed.", display]));
                return;
            }
            NSMutableArray<NSDictionary *> *valid = [NSMutableArray array];
            NSCharacterSet *colorCharacters = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"];
            for (NSDictionary *row in rows) {
                NSString *name = [row[@"name"] isKindOfClass:NSString.class] ? row[@"name"] : nil;
                NSString *label = [row[@"label"] isKindOfClass:NSString.class] ? row[@"label"] : nil;
                NSString *hash = [row[@"sha256"] isKindOfClass:NSString.class] ? row[@"sha256"] : nil;
                if (!name.length || name.length > 48 || [name rangeOfCharacterFromSet:colorCharacters.invertedSet].location != NSNotFound || !ZXIsSHA256(hash)) continue;
                [valid addObject:@{@"name": name, @"label": label.length ? label : name, @"sha256": hash.lowercaseString}];
            }
            if (threeD) {
                NSArray *expected = @[@"BLACK", @"PINK", @"BLUE"];
                NSArray *received = [valid valueForKey:@"name"];
                if (![received isEqualToArray:expected]) {
                    completion(nil, FFNamedError(53, @"ASSET_NOT_FOUND", @"3D catalog must contain exactly Black, Pink, and Blue."));
                    return;
                }
            } else if (!valid.count) {
                completion(nil, FFNamedError(53, @"ASSET_NOT_FOUND", @"No Hologram colors are available."));
                return;
            }
            completion(valid, nil);
        }];
    [task resume];
}

static BOOL FFIsKnownCacheFilename(NSString *name) {
    NSString *lower = name.lowercaseString;
    return [lower isEqualToString:@"cache_res"] ||
        [lower hasPrefix:@"cache_res."] ||
        [lower isEqualToString:@"content_cache_compulsory"] ||
        [lower hasPrefix:@"content_cache_compulsory."];
}

static NSURL *FFFindGameAssetBundles(NSURL *root, NSError **error) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSNumber *isDirectory = nil;
    [root getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    if (isDirectory.boolValue && [root.lastPathComponent caseInsensitiveCompare:@"gameassetbundles"] == NSOrderedSame) {
        return root;
    }

    NSArray<NSString *> *relativeCandidates = @[
        @"Documents/contentcache/Compulsory/ios/gameassetbundles",
        @"Documents/contentcache/Optional/ios/gameassetbundles",
        @"Documents/contentcache/Optional/ios/GameAssetBundles",
        @"contentcache/Compulsory/ios/gameassetbundles",
        @"contentcache/Optional/ios/gameassetbundles",
        @"contentcache/Optional/ios/GameAssetBundles",
        @"Compulsory/ios/gameassetbundles",
        @"Optional/ios/gameassetbundles",
        @"ios/gameassetbundles",
        @"gameassetbundles"
    ];
    for (NSString *relativePath in relativeCandidates) {
        NSURL *candidate = [root URLByAppendingPathComponent:relativePath isDirectory:YES];
        BOOL directory = NO;
        if ([fm fileExistsAtPath:candidate.path isDirectory:&directory] && directory) return candidate;
    }

    NSMutableOrderedSet<NSURL *> *cacheParents = [NSMutableOrderedSet orderedSet];
    NSDirectoryEnumerator<NSURL *> *enumerator = [fm enumeratorAtURL:root
                                           includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLIsRegularFileKey]
                                                              options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants
                                                         errorHandler:^BOOL(NSURL *url, NSError *enumerationError) {
        (void)url; (void)enumerationError;
        return YES;
    }];
    NSUInteger visited = 0;
    for (NSURL *url in enumerator) {
        if (++visited > 250000) break;
        NSNumber *directory = nil;
        [url getResourceValue:&directory forKey:NSURLIsDirectoryKey error:nil];
        if (directory.boolValue) {
            if ([url.lastPathComponent caseInsensitiveCompare:@"gameassetbundles"] == NSOrderedSame) {
                return url;
            }
            continue;
        }
        NSNumber *regular = nil;
        [url getResourceValue:&regular forKey:NSURLIsRegularFileKey error:nil];
        if (regular.boolValue && FFIsKnownCacheFilename(url.lastPathComponent)) {
            [cacheParents addObject:url.URLByDeletingLastPathComponent];
        }
    }
    if (cacheParents.count == 1) return cacheParents.firstObject;
    if (error) {
        *error = cacheParents.count > 1
            ? FFError(10, [NSString stringWithFormat:
                @"Found %lu possible cache locations in the game container; no unique target was selected.",
                (unsigned long)cacheParents.count])
            : FFError(10, @"No gameassetbundles or cache_res location was found in the game container.");
    }
    return nil;
}

static NSURL *FFTargetFile(NSURL *directory, NSString *gameIdentifier, BOOL allowBackupOnly, NSError **error) {
    NSFileManager *fm = NSFileManager.defaultManager;
    // The two games keep their own data containers, but current Free Fire
    // builds use different cache naming orders. Prefer the known TH bundle
    // name and the MAX base name, then retain the safe recursive discovery
    // for versioned filenames introduced by game updates.
    NSArray<NSString *> *names = [gameIdentifier isEqualToString:FFBundleIDFreeFireTH]
        ? @[@"cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D", @"cache_res", @"content_cache_compulsory"]
        : @[@"cache_res", @"content_cache_compulsory", @"cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"];
    for (NSString *name in names) {
        NSURL *candidate = [directory URLByAppendingPathComponent:name];
        if ([fm fileExistsAtPath:candidate.path]) return candidate;
    }
    if (allowBackupOnly) {
        for (NSString *name in names) {
            NSURL *candidate = [directory URLByAppendingPathComponent:name];
            NSURL *backup = [NSURL fileURLWithPath:[candidate.path stringByAppendingString:FFBackupSuffix]];
            if ([fm fileExistsAtPath:backup.path]) return candidate;
        }
    }

    NSData *cabMarker = [@"CAB-f35e59c15686beb35c2683bdcd5b9393" dataUsingEncoding:NSASCIIStringEncoding];
    NSString *knownCacheName = @"cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D";
    NSMutableArray<NSURL *> *knownNameMatches = [NSMutableArray array];
    NSMutableArray<NSURL *> *cacheNameMatches = [NSMutableArray array];
    NSMutableArray<NSURL *> *backupMatches = [NSMutableArray array];
    NSMutableArray<NSURL *> *markerMatches = [NSMutableArray array];
    NSMutableArray<NSURL *> *unityCandidates = [NSMutableArray array];
    NSMutableSet<NSString *> *seenPaths = [NSMutableSet set];
    NSArray<NSURLResourceKey> *keys = @[NSURLIsRegularFileKey, NSURLFileSizeKey];
    NSDirectoryEnumerator<NSURL *> *enumerator = [fm enumeratorAtURL:directory
                                           includingPropertiesForKeys:keys
                                                              options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants
                                                         errorHandler:^BOOL(NSURL *url, NSError *enumerationError) {
        (void)url; (void)enumerationError;
        return YES;
    }];
    NSUInteger visited = 0;
    for (NSURL *url in enumerator) {
        if (++visited > 50000) break;
        NSNumber *regular = nil;
        NSNumber *size = nil;
        [url getResourceValue:&regular forKey:NSURLIsRegularFileKey error:nil];
        [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
        if (!regular.boolValue || size.unsignedLongLongValue < 40000 || size.unsignedLongLongValue > 150000) continue;

        BOOL isBackup = [url.path hasSuffix:FFBackupSuffix];
        NSURL *liveURL = isBackup ? [NSURL fileURLWithPath:[url.path substringToIndex:url.path.length - FFBackupSuffix.length]] : url;
        if (isBackup && !allowBackupOnly && ![fm fileExistsAtPath:liveURL.path]) continue;
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];
        if (!FFDataLooksLikeUnityBundle(data)) continue;
        if (![seenPaths containsObject:liveURL.path]) {
            [seenPaths addObject:liveURL.path];
            [unityCandidates addObject:liveURL];
        }
        NSString *liveName = liveURL.lastPathComponent;
        NSString *lowerName = liveName.lowercaseString;
        if ([liveName caseInsensitiveCompare:knownCacheName] == NSOrderedSame && ![knownNameMatches containsObject:liveURL]) {
            [knownNameMatches addObject:liveURL];
        }
        BOOL cacheNameMatch = [lowerName isEqualToString:@"cache_res"] ||
            [lowerName hasPrefix:@"cache_res."] ||
            [lowerName isEqualToString:@"content_cache_compulsory"] ||
            [lowerName hasPrefix:@"content_cache_compulsory."];
        if (cacheNameMatch && ![cacheNameMatches containsObject:liveURL]) [cacheNameMatches addObject:liveURL];
        if (isBackup && ![backupMatches containsObject:liveURL]) [backupMatches addObject:liveURL];
        BOOL markerMatch = [data rangeOfData:cabMarker options:0 range:NSMakeRange(0, data.length)].location != NSNotFound;
        if (markerMatch && ![markerMatches containsObject:liveURL]) [markerMatches addObject:liveURL];
    }

    if (backupMatches.count == 1) return backupMatches.firstObject;
    if (knownNameMatches.count == 1) return knownNameMatches.firstObject;
    if (cacheNameMatches.count == 1) return cacheNameMatches.firstObject;
    if (markerMatches.count == 1) return markerMatches.firstObject;
    if (knownNameMatches.count > 1 || cacheNameMatches.count > 1) {
        NSUInteger count = knownNameMatches.count > 1 ? knownNameMatches.count : cacheNameMatches.count;
        if (error) *error = FFError(11, [NSString stringWithFormat:@"Found %lu files named cache_res. Update Free Fire once, then retry.", (unsigned long)count]);
        return nil;
    }
    if (unityCandidates.count == 1) return unityCandidates.firstObject;
    if (error) {
        NSString *message = unityCandidates.count == 0
            ? @"No matching UnityFS cache bundle was found recursively under gameassetbundles."
            : [NSString stringWithFormat:@"Found %lu UnityFS bundles, but the expected cache_res file name was not present.", (unsigned long)unityCandidates.count];
        *error = FFError(11, message);
    }
    return nil;
}

typedef NS_ENUM(NSInteger, FFAccessMethod) {
    FFAccessMethodNone = 0,
    FFAccessMethodDirect,
    FFAccessMethodAuthorizedFolder,
};

static NSString *FFAccessMethodName(FFAccessMethod method) {
    switch (method) {
        case FFAccessMethodDirect:
#ifdef FM_OFFLINE_BUILD
            return @"3105 MCM DirectAccess";
#else
            return @"DirectAccess";
#endif
        case FFAccessMethodAuthorizedFolder: return @"AuthorizedFolderAccess";
        default: return @"NONE";
    }
}

@interface FFAccessContext : NSObject
@property(nonatomic) FFAccessMethod method;
@property(nonatomic, copy) NSString *gameIdentifier;
@property(nonatomic, strong) NSURL *rootURL;
@property(nonatomic, strong) NSURL *assetBundlesURL;
@property(nonatomic, strong) NSURL *targetURL;
@property(nonatomic, copy) NSString *activeFeature;
@property(nonatomic, strong) NSError *error;
@property(nonatomic, copy) NSString *fallbackReason;
@property(nonatomic) BOOL discovered;
@property(nonatomic) BOOL opened;
@property(nonatomic) BOOL readVerified;
@property(nonatomic) BOOL writeVerified;
@property(nonatomic) BOOL usable;
@property(nonatomic) BOOL needsFolderSelection;
@end

@implementation FFAccessContext
@end

static NSString *FFActiveFeatureAtTarget(NSURL *target, NSString *gameIdentifier) {
    NSData *current = [NSData dataWithContentsOfURL:target options:NSDataReadingMappedIfSafe error:nil];
    if (!current) return @"UNKNOWN";
    NSURL *backup = [NSURL fileURLWithPath:[target.path stringByAppendingString:FFBackupSuffix]];
    NSData *original = [NSData dataWithContentsOfURL:backup options:NSDataReadingMappedIfSafe error:nil];
    if (original && [current isEqualToData:original]) return @"ORIGINAL";
    NSString *key = FFActiveProfileDefaultsKey(gameIdentifier);
    NSString *saved = key ? [NSUserDefaults.standardUserDefaults stringForKey:key] : nil;
    return saved.length ? saved : @"CUSTOM / ORIGINAL";
}

@interface FFGameDetector : NSObject
+ (FFAccessContext *)detectDirectContainerForGame:(NSString *)gameIdentifier;
@end

@implementation FFGameDetector
+ (FFAccessContext *)detectDirectContainerForGame:(NSString *)gameIdentifier {
    FFAccessContext *context = [FFAccessContext new];
    context.method = FFAccessMethodDirect;
    context.gameIdentifier = gameIdentifier;
    FFDiagnosticLog(@"GameDetector", @"Bundle: %@", gameIdentifier ?: @"NONE");

    NSError *error = nil;
    NSString *detectedIdentifier = nil;
    NSURL *assetBundles = nil;
    NSURL *container = FFDirectGameContainer(gameIdentifier, &detectedIdentifier, nil,
        &assetBundles, &error);
    context.rootURL = container;
    context.assetBundlesURL = assetBundles;
    context.discovered = container != nil && [detectedIdentifier isEqualToString:gameIdentifier];
    context.error = error;
    FFDiagnosticLog(@"DirectAccess", @"Discovery: %@%@", context.discovered ? @"SUCCESS" : @"FAILED",
        container.path.length ? [NSString stringWithFormat:@" (%@)", container.path] : @"");
    if (error) FFDiagnosticLog(@"DirectAccess", @"Discovery detail: %@", error.localizedDescription);
    return context;
}
@end

@interface FFAccessVerifier : NSObject
+ (FFAccessContext *)verifyContext:(FFAccessContext *)context
                     requiresWrite:(BOOL)requiresWrite
                   allowBackupOnly:(BOOL)allowBackupOnly;
@end

@implementation FFAccessVerifier
+ (FFAccessContext *)verifyContext:(FFAccessContext *)context
                     requiresWrite:(BOOL)requiresWrite
                   allowBackupOnly:(BOOL)allowBackupOnly {
    NSString *component = FFAccessMethodName(context.method);
    NSFileManager *manager = NSFileManager.defaultManager;
    BOOL isDirectory = NO;
    if (!context.discovered || !context.rootURL ||
        ![manager fileExistsAtPath:context.rootURL.path isDirectory:&isDirectory] || !isDirectory) {
        context.error = context.error ?: FFNamedError(60, @"CONTAINER_NOT_FOUND", @"Game detector did not produce an existing directory.");
        FFDiagnosticLog(component, @"Open: FAILED (%@)", context.error.localizedDescription);
        return context;
    }

    errno = 0;
    int rootDescriptor = open(context.rootURL.fileSystemRepresentation, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    if (rootDescriptor < 0) {
        NSError *posix = FFPOSIXAccessError(61, @"Container root open", context.rootURL, errno);
        context.error = FFNamedError(61, @"CONTAINER_FOUND_ACCESS_DENIED", posix.localizedDescription);
        FFDiagnosticLog(component, @"Open: FAILED (%@)", context.error.localizedDescription);
        return context;
    }
    close(rootDescriptor);
    context.opened = YES;
    FFDiagnosticLog(component, @"Open: SUCCESS");

    NSError *lookupError = nil;
    NSURL *assetBundles = context.assetBundlesURL ?: FFFindGameAssetBundles(context.rootURL, &lookupError);
    NSURL *target = assetBundles
        ? FFTargetFile(assetBundles, context.gameIdentifier, allowBackupOnly, &lookupError) : nil;
    if (!assetBundles || !target) {
        context.error = FFNamedError(62, @"ASSET_NOT_FOUND",
            lookupError.localizedDescription ?: @"Required game files were not found.");
        FFDiagnosticLog(@"AccessVerifier", @"Read: FAILED (%@)", context.error.localizedDescription);
        return context;
    }
    context.assetBundlesURL = assetBundles;
    context.targetURL = target;

    NSURL *readURL = target;
    if (allowBackupOnly && ![manager fileExistsAtPath:target.path]) {
        readURL = [NSURL fileURLWithPath:[target.path stringByAppendingString:FFBackupSuffix]];
    }
    errno = 0;
    int targetDescriptor = open(readURL.fileSystemRepresentation, O_RDONLY | O_CLOEXEC);
    if (targetDescriptor < 0) {
        NSError *posix = FFPOSIXAccessError(63, @"Required game file read", readURL, errno);
        context.error = FFNamedError(63, @"READ_FAILED", posix.localizedDescription);
        FFDiagnosticLog(@"AccessVerifier", @"Read: FAILED (%@)", context.error.localizedDescription);
        return context;
    }
    unsigned char header[8] = {0};
    ssize_t bytesRead = read(targetDescriptor, header, sizeof(header));
    int readErrno = errno;
    close(targetDescriptor);
    const unsigned char unityHeader[] = {'U','n','i','t','y','F','S',0};
    if (bytesRead != (ssize_t)sizeof(header) || memcmp(header, unityHeader, sizeof(unityHeader)) != 0) {
        NSError *readFailure = bytesRead < 0
            ? FFPOSIXAccessError(63, @"Required game file read", readURL, readErrno)
            : FFError(63, @"Required game file is readable but does not have the expected UnityFS header.");
        context.error = FFNamedError(63, @"READ_FAILED", readFailure.localizedDescription);
        FFDiagnosticLog(@"AccessVerifier", @"Read: FAILED (%@)", context.error.localizedDescription);
        return context;
    }
    context.readVerified = YES;
    FFDiagnosticLog(@"AccessVerifier", @"Read: SUCCESS");

    if (requiresWrite) {
        if ([manager fileExistsAtPath:target.path]) {
            errno = 0;
            int writableTarget = open(target.fileSystemRepresentation, O_WRONLY | O_CLOEXEC);
            if (writableTarget < 0) {
                NSError *posix = FFPOSIXAccessError(64, @"Required destination write open", target, errno);
                context.error = FFNamedError(64, @"WRITE_FAILED", posix.localizedDescription);
                FFDiagnosticLog(@"AccessVerifier", @"Write: FAILED (%@)", context.error.localizedDescription);
                return context;
            }
            close(writableTarget);
        }
        NSURL *destination = target.URLByDeletingLastPathComponent;
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        __block NSError *probeError = nil;
        __block BOOL probeSucceeded = NO;
        NSError *coordinationError = nil;
        [coordinator coordinateWritingItemAtURL:destination
                                        options:NSFileCoordinatorWritingForMerging
                                          error:&coordinationError
                                     byAccessor:^(NSURL *coordinatedDestination) {
            NSString *probeName = [NSString stringWithFormat:@".ffaccess-%@.tmp", NSUUID.UUID.UUIDString];
            NSURL *probeURL = [coordinatedDestination URLByAppendingPathComponent:probeName];
            errno = 0;
            int descriptor = open(probeURL.fileSystemRepresentation,
                O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0600);
            if (descriptor < 0) {
                probeError = FFPOSIXAccessError(64, @"Destination write probe open", probeURL, errno);
                return;
            }
            const unsigned char probe[] = {'F','F','A','C','C','E','S','S'};
            ssize_t written = write(descriptor, probe, sizeof(probe));
            int savedErrno = errno;
            close(descriptor);
            if (written != (ssize_t)sizeof(probe)) {
                unlink(probeURL.fileSystemRepresentation);
                probeError = FFPOSIXAccessError(64, @"Destination write probe", probeURL,
                    written < 0 ? savedErrno : EIO);
                return;
            }
            if (unlink(probeURL.fileSystemRepresentation) != 0) {
                probeError = FFPOSIXAccessError(64, @"Destination write probe cleanup", probeURL, errno);
                return;
            }
            probeSucceeded = YES;
        }];
        if (!probeError && coordinationError) probeError = coordinationError;
        if (!probeSucceeded || probeError) {
            context.error = FFNamedError(64, @"WRITE_FAILED",
                probeError.localizedDescription ?: @"Destination write verification failed.");
            FFDiagnosticLog(@"AccessVerifier", @"Write: FAILED (%@)", context.error.localizedDescription);
            return context;
        }
        context.writeVerified = YES;
        FFDiagnosticLog(@"AccessVerifier", @"Write: SUCCESS");
    } else {
        context.writeVerified = YES;
        FFDiagnosticLog(@"AccessVerifier", @"Write: SKIPPED (read-only operation)");
    }

    context.error = nil;
    context.usable = context.opened && context.readVerified && context.writeVerified;
    if (context.usable) {
        context.activeFeature = FFActiveFeatureAtTarget(context.targetURL, context.gameIdentifier);
    }
    return context;
}
@end

@interface FFAccessManager : NSObject
+ (BOOL)storeBookmarkForAuthorizedURL:(NSURL *)url error:(NSError **)error;
+ (NSURL *)beginBookmarkedFolderAccessWithStale:(BOOL *)stale error:(NSError **)error;
+ (void)endBookmarkedFolderAccess:(NSURL *)url;
+ (void)invalidateStoredBookmark:(NSString *)reason;
@end

@implementation FFAccessManager
+ (BOOL)storeBookmarkForAuthorizedURL:(NSURL *)url error:(NSError **)error {
    NSData *bookmark = [url bookmarkDataWithOptions:0
                         includingResourceValuesForKeys:nil relativeToURL:nil error:error];
    if (!bookmark) {
        NSString *detail = (error && *error) ? (*error).localizedDescription : @"creation failed";
        FFDiagnosticLog(@"Bookmark", @"Stored: NO (%@)", detail);
        return NO;
    }
    [NSUserDefaults.standardUserDefaults setObject:bookmark forKey:FFBookmarkKey];
    FFDiagnosticLog(@"Bookmark", @"Stored: YES");
    return YES;
}

+ (NSURL *)beginBookmarkedFolderAccessWithStale:(BOOL *)stale error:(NSError **)error {
    NSData *bookmark = [NSUserDefaults.standardUserDefaults dataForKey:FFBookmarkKey];
    if (!bookmark) {
        if (error) *error = FFError(65, @"No authorized game folder is stored.");
        FFDiagnosticLog(@"Bookmark", @"Restored: NO (missing)");
        return nil;
    }
    BOOL bookmarkStale = NO;
    NSURL *url = [NSURL URLByResolvingBookmarkData:bookmark options:0 relativeToURL:nil
                            bookmarkDataIsStale:&bookmarkStale error:error];
    FFDiagnosticLog(@"Bookmark", @"Restored: %@", url ? @"YES" : @"NO");
    FFDiagnosticLog(@"Bookmark", @"Stale: %@", bookmarkStale ? @"YES" : @"NO");
    if (!url) return nil;

    BOOL accessed = [url startAccessingSecurityScopedResource];
    FFDiagnosticLog(@"AuthorizedFolderAccess", @"Security-scoped resource: %@", accessed ? @"STARTED" : @"FAILED");
    if (!accessed) {
        if (error) *error = FFError(66, @"Folder authorization expired. Select the game folder again.");
        return nil;
    }
    if (bookmarkStale) {
        NSError *renewError = nil;
        if (![self storeBookmarkForAuthorizedURL:url error:&renewError]) {
            [url stopAccessingSecurityScopedResource];
            if (error) *error = renewError ?: FFError(66, @"The stale folder bookmark could not be renewed.");
            return nil;
        }
        FFDiagnosticLog(@"Bookmark", @"Renewed: YES");
    }
    if (stale) *stale = bookmarkStale;
    return url;
}

+ (void)endBookmarkedFolderAccess:(NSURL *)url {
    if (!url) return;
    [url stopAccessingSecurityScopedResource];
    FFDiagnosticLog(@"AuthorizedFolderAccess", @"Security-scoped resource: STOPPED");
}

+ (void)invalidateStoredBookmark:(NSString *)reason {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:FFBookmarkKey];
    FFDiagnosticLog(@"Bookmark", @"Invalidated: %@", reason.length ? reason : @"authorization unavailable");
}
@end

@interface FFCompatibilityRouter : NSObject
+ (FFAccessContext *)routeGame:(NSString *)gameIdentifier requiresWrite:(BOOL)requiresWrite;
+ (FFAccessContext *)verifyAuthorizedURL:(NSURL *)url
                                 forGame:(NSString *)gameIdentifier
                           requiresWrite:(BOOL)requiresWrite;
@end


@implementation FFCompatibilityRouter
+ (FFAccessContext *)verifyAuthorizedURL:(NSURL *)url
                                 forGame:(NSString *)gameIdentifier
                           requiresWrite:(BOOL)requiresWrite {
    FFAccessContext *context = [FFAccessContext new];
    context.method = FFAccessMethodAuthorizedFolder;
    context.gameIdentifier = gameIdentifier;
    context.rootURL = url;
    context.discovered = url != nil;
    return [FFAccessVerifier verifyContext:context requiresWrite:requiresWrite allowBackupOnly:NO];
}

+ (FFAccessContext *)routeGame:(NSString *)gameIdentifier requiresWrite:(BOOL)requiresWrite {
    NSOperatingSystemVersion version = NSProcessInfo.processInfo.operatingSystemVersion;
    FFDiagnosticLog(@"Compatibility", @"iOS: %ld.%ld.%ld", (long)version.majorVersion,
        (long)version.minorVersion, (long)version.patchVersion);
    FFDiagnosticLog(@"GameDetector", @"Bundle: %@", gameIdentifier ?: @"NONE");

    FFAccessContext *direct = [FFGameDetector detectDirectContainerForGame:gameIdentifier];
    if (direct.discovered) {
        [FFAccessVerifier verifyContext:direct requiresWrite:requiresWrite allowBackupOnly:NO];
        if (direct.usable) {
            FFDiagnosticLog(@"Compatibility", @"Selected access method: DirectAccess");
            FFDiagnosticLog(@"Compatibility", @"Final access state: READY");
            return direct;
        }
    }

    // On iOS 18.5 and later 18.x releases, Files does not expose another
    // application's private data container. A document picker cannot grant a
    // URL the user cannot select, so report the verified access state instead
    // of presenting a folder workflow that cannot authorize the target.
    if (version.majorVersion == 18 && version.minorVersion >= 5) {
        direct.needsFolderSelection = NO;
        NSString *state = direct.discovered ? @"CONTAINER_FOUND_ACCESS_DENIED"
                                            : @"AUTHORIZED_CONTAINER_ACCESS_UNAVAILABLE";
        direct.error = FFNamedError(67, state,
            @"iOS 18.5+ did not grant this app legitimate read/write access to the game's private container. The folder is not exposed in Files, so manual folder selection is unavailable.");
        return direct;
    }

#ifdef FM_OFFLINE_BUILD
    direct.needsFolderSelection = NO;
    direct.error = direct.error ?: FFError(67,
        @"3105 MCM direct access is unavailable on this device/signing method. Offline mode does not use a folder picker.");
    FFDiagnosticLog(@"Compatibility", @"Offline direct-only mode: no AuthorizedFolderAccess fallback");
    FFDiagnosticLog(@"Compatibility", @"Final access state: DIRECT ACCESS UNAVAILABLE");
    return direct;
#endif

    NSString *fallbackReason = direct.error.localizedDescription ?: @"Direct access did not pass filesystem verification.";
    FFDiagnosticLog(@"Compatibility", @"Falling back to AuthorizedFolderAccess");
    FFDiagnosticLog(@"Compatibility", @"Fallback reason: %@", fallbackReason);

    NSError *bookmarkError = nil;
    BOOL stale = NO;
    NSURL *authorizedRoot = [FFAccessManager beginBookmarkedFolderAccessWithStale:&stale error:&bookmarkError];
    if (!authorizedRoot) {
        FFAccessContext *failed = [FFAccessContext new];
        failed.method = FFAccessMethodNone;
        failed.gameIdentifier = gameIdentifier;
        failed.fallbackReason = fallbackReason;
        failed.error = bookmarkError ?: FFError(65, @"Select an authorized game folder to continue.");
        failed.needsFolderSelection = YES;
        if (bookmarkError.code == 66) [FFAccessManager invalidateStoredBookmark:bookmarkError.localizedDescription];
        FFDiagnosticLog(@"Compatibility", @"Final access state: AUTHORIZATION REQUIRED");
        return failed;
    }

    FFAccessContext *authorized = [self verifyAuthorizedURL:authorizedRoot
                                                   forGame:gameIdentifier
                                             requiresWrite:requiresWrite];
    authorized.fallbackReason = fallbackReason;
    [FFAccessManager endBookmarkedFolderAccess:authorizedRoot];
    if (authorized.usable) {
        FFDiagnosticLog(@"Compatibility", @"Selected access method: AuthorizedFolderAccess");
        FFDiagnosticLog(@"Compatibility", @"Final access state: READY");
        return authorized;
    }
    [FFAccessManager invalidateStoredBookmark:authorized.error.localizedDescription];
    authorized.needsFolderSelection = YES;
    FFDiagnosticLog(@"Compatibility", @"Final access state: AUTHORIZATION REQUIRED");
    return authorized;
}
@end

static BOOL FFCreateBackupIfNeeded(NSURL *target, NSError **error) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSURL *backup = [NSURL fileURLWithPath:[target.path stringByAppendingString:FFBackupSuffix]];
    if ([fm fileExistsAtPath:backup.path]) {
        NSData *saved = [NSData dataWithContentsOfURL:backup options:NSDataReadingMappedIfSafe error:nil];
        if (saved.length && FFDataLooksLikeUnityBundle(saved)) {
            FFDiagnosticLog(@"ApplyManager", @"Backup Original: VERIFIED (existing, never overwritten)");
            return YES;
        }
        if (error) *error = FFNamedError(13, @"ORIGINAL_BACKUP_FAILED", @"Existing original backup is invalid; apply aborted safely.");
        return NO;
    }
    NSDictionary *attributes = [fm attributesOfItemAtPath:target.path error:error];
    if (!attributes || [attributes fileSize] == 0) {
        if (error) *error = FFNamedError(13, @"ORIGINAL_BACKUP_FAILED", @"Original file is missing or empty.");
        return NO;
    }
    NSData *original = [NSData dataWithContentsOfURL:target options:NSDataReadingMappedIfSafe error:error];
    if (!original.length || !FFDataLooksLikeUnityBundle(original) ||
        ![fm copyItemAtURL:target toURL:backup error:error]) {
        if (error && !*error) *error = FFNamedError(13, @"ORIGINAL_BACKUP_FAILED", @"Could not create the original backup.");
        return NO;
    }
    NSData *saved = [NSData dataWithContentsOfURL:backup options:NSDataReadingMappedIfSafe error:nil];
    if (!saved.length || ![[ZXDigest(original) lowercaseString] isEqualToString:[ZXDigest(saved) lowercaseString]]) {
        [fm removeItemAtURL:backup error:nil];
        if (error) *error = FFNamedError(13, @"ORIGINAL_BACKUP_FAILED", @"Backup verification failed.");
        return NO;
    }
    FFDiagnosticLog(@"ApplyManager", @"Backup Original: SUCCESS + SHA256 VERIFIED");
    return YES;
}

static BOOL FFReplaceTargetWithData(NSURL *target, NSData *data, NSError **error) {
    if (!FFDataLooksLikeUnityBundle(data)) {
        if (error) *error = FFError(14, @"The selected feature is not a valid UnityFS cache bundle.");
        return NO;
    }

    NSFileManager *fm = NSFileManager.defaultManager;
    NSURL *directory = [target URLByDeletingLastPathComponent];
    NSString *temporaryName = [NSString stringWithFormat:@".%@.%@.tmp", target.lastPathComponent, NSUUID.UUID.UUIDString];
    NSURL *temporary = [directory URLByAppendingPathComponent:temporaryName];
    if (![data writeToURL:temporary options:NSDataWritingAtomic error:error]) return NO;

    BOOL succeeded = NO;
    if ([fm fileExistsAtPath:target.path]) {
        NSURL *result = nil;
        succeeded = [fm replaceItemAtURL:target
                            withItemAtURL:temporary
                           backupItemName:nil
                                  options:0
                         resultingItemURL:&result
                                    error:error];
    } else {
        succeeded = [fm moveItemAtURL:temporary toURL:target error:error];
    }
    if (!succeeded && [fm fileExistsAtPath:temporary.path]) [fm removeItemAtURL:temporary error:nil];
    NSData *installed = succeeded ? [NSData dataWithContentsOfURL:target options:NSDataReadingMappedIfSafe error:nil] : nil;
    if (!succeeded || ![[ZXDigest(installed) lowercaseString] isEqualToString:[ZXDigest(data) lowercaseString]]) {
        if (error && !*error) *error = FFNamedError(51, @"APPLY_FAILED", @"Post-write SHA-256 verification failed.");
        return NO;
    }
    FFDiagnosticLog(@"ApplyManager", @"APPLY_SUCCESS: target SHA256 verified");
    return YES;
}

static BOOL FFInstallFeatureData(NSData *data, NSURL *target, NSError **error) {
    if (!FFCreateBackupIfNeeded(target, error)) return NO;
    if (FFReplaceTargetWithData(target, data, error)) return YES;
    NSError *initial = error ? *error : nil;
    NSURL *backup = [NSURL fileURLWithPath:[target.path stringByAppendingString:FFBackupSuffix]];
    NSData *original = [NSData dataWithContentsOfURL:backup options:NSDataReadingMappedIfSafe error:nil];
    if (original.length) FFReplaceTargetWithData(target, original, nil);
    if (error) *error = initial ?: FFNamedError(51, @"APPLY_FAILED", @"Installation failed and original recovery was attempted.");
    return NO;
}

static BOOL FFReplaceRawData(NSURL *target, NSData *data, NSError **error) {
    if (!data.length) {
        if (error) *error = FFError(45, @"Protected resource is empty.");
        return NO;
    }
    NSFileManager *fm = NSFileManager.defaultManager;
    NSURL *directory = target.URLByDeletingLastPathComponent;
    NSURL *temporary = [directory URLByAppendingPathComponent:
        [NSString stringWithFormat:@".%@.%@.tmp", target.lastPathComponent, NSUUID.UUID.UUIDString]];
    if (![data writeToURL:temporary options:NSDataWritingAtomic error:error]) return NO;
    NSURL *result = nil;
    BOOL succeeded = [fm replaceItemAtURL:target withItemAtURL:temporary backupItemName:nil
                                  options:0 resultingItemURL:&result error:error];
    if (!succeeded && [fm fileExistsAtPath:temporary.path]) [fm removeItemAtURL:temporary error:nil];
    NSData *installed = succeeded ? [NSData dataWithContentsOfURL:target options:NSDataReadingMappedIfSafe error:nil] : nil;
    if (!succeeded || ![[ZXDigest(installed) lowercaseString] isEqualToString:[ZXDigest(data) lowercaseString]]) {
        if (error && !*error) *error = FFNamedError(51, @"APPLY_FAILED", @"Post-write SHA-256 verification failed.");
        return NO;
    }
    FFDiagnosticLog(@"ApplyManager", @"APPLY_SUCCESS: protected target SHA256 verified");
    return YES;
}

static BOOL FFInstallRawData(NSURL *target, NSData *data, NSError **error) {
    if (!FFCreateBackupIfNeeded(target, error)) return NO;
    if (FFReplaceRawData(target, data, error)) return YES;
    NSError *initial = error ? *error : nil;
    NSURL *backup = [NSURL fileURLWithPath:[target.path stringByAppendingString:FFBackupSuffix]];
    NSData *original = [NSData dataWithContentsOfURL:backup options:NSDataReadingMappedIfSafe error:nil];
    if (original.length) FFReplaceRawData(target, original, nil);
    if (error) *error = initial ?: FFNamedError(51, @"APPLY_FAILED", @"Installation failed and original recovery was attempted.");
    return NO;
}

static NSURL *FFFindUniqueAssetTarget(NSURL *container, NSURL *assetBundles, NSString *filename,
                                      NSString *displayName, BOOL allowBackupOnly, NSError **error) {
    NSFileManager *fm = NSFileManager.defaultManager;
    NSMutableArray<NSURL *> *roots = [NSMutableArray array];
    if (assetBundles) [roots addObject:assetBundles];
    if (container && (!assetBundles || ![container.path isEqualToString:assetBundles.path])) [roots addObject:container];
    NSMutableSet<NSString *> *exactMatches = [NSMutableSet set];
    NSMutableSet<NSString *> *versionedMatches = [NSMutableSet set];
    NSMutableSet<NSString *> *identityMatches = [NSMutableSet set];
    BOOL threeDTarget = [filename isEqualToString:FFThreeDShaderFilename];
    NSData *threeDIdentity = threeDTarget
        ? [@"CAB-88002acb86723c32269b375ebf7fc438" dataUsingEncoding:NSASCIIStringEncoding]
        : nil;
    NSString *lowerFilename = filename.lowercaseString;

    for (NSURL *root in roots) {
        BOOL regular = NO;
        NSURL *candidate = [root URLByAppendingPathComponent:filename];
        if ([fm fileExistsAtPath:candidate.path isDirectory:&regular] && !regular) {
            [exactMatches addObject:candidate.standardizedURL.path];
        } else if (allowBackupOnly) {
            NSURL *backupCandidate = [NSURL fileURLWithPath:[candidate.path stringByAppendingString:FFBackupSuffix]];
            if ([fm fileExistsAtPath:backupCandidate.path isDirectory:&regular] && !regular) {
                [exactMatches addObject:candidate.standardizedURL.path];
            }
        }
        NSDirectoryEnumerator<NSURL *> *enumerator = [fm enumeratorAtURL:root
            includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLFileSizeKey] options:NSDirectoryEnumerationSkipsHiddenFiles |
            NSDirectoryEnumerationSkipsPackageDescendants errorHandler:^BOOL(NSURL *url, NSError *inner) {
                (void)url; (void)inner; return YES;
            }];
        NSUInteger visited = 0;
        NSUInteger maximum = [root.path isEqualToString:assetBundles.path] ? 250000 : 80000;
        for (NSURL *url in enumerator) {
            if (++visited > maximum) break;
            NSNumber *isRegular = nil;
            NSNumber *fileSize = nil;
            [url getResourceValue:&isRegular forKey:NSURLIsRegularFileKey error:nil];
            if (!isRegular.boolValue) continue;
            BOOL isBackup = allowBackupOnly && [url.path hasSuffix:FFBackupSuffix];
            NSURL *liveURL = isBackup
                ? [NSURL fileURLWithPath:[url.path substringToIndex:url.path.length - FFBackupSuffix.length]]
                : url;
            NSString *lowerName = liveURL.lastPathComponent.lowercaseString;
            if ([lowerName isEqualToString:lowerFilename]) {
                [exactMatches addObject:liveURL.standardizedURL.path];
                continue;
            }
            if (!threeDTarget) continue;
            BOOL versionedName = [lowerName hasPrefix:[lowerFilename stringByAppendingString:@"."]] ||
                [lowerName hasPrefix:[lowerFilename stringByAppendingString:@"~"]];
            if (!versionedName && ![lowerName containsString:@"shader"]) continue;
            [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
            if (fileSize.unsignedLongLongValue < 100000 || fileSize.unsignedLongLongValue > 2000000) continue;
            NSData *candidateData = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];
            if (!FFDataLooksLikeUnityBundle(candidateData)) continue;
            BOOL identityMatch = [candidateData rangeOfData:threeDIdentity options:0
                range:NSMakeRange(0, candidateData.length)].location != NSNotFound;
            if (!identityMatch) continue;
            [identityMatches addObject:liveURL.standardizedURL.path];
            if (versionedName) [versionedMatches addObject:liveURL.standardizedURL.path];
        }
    }
    if (exactMatches.count == 1) return [NSURL fileURLWithPath:exactMatches.anyObject];
    if (exactMatches.count > 1) {
        if (error) *error = FFNamedError(49, @"ASSET_NOT_FOUND",
            [NSString stringWithFormat:@"Multiple exact %@ targets were found; update aborted safely.", displayName]);
        return nil;
    }
    if (versionedMatches.count == 1) return [NSURL fileURLWithPath:versionedMatches.anyObject];
    if (versionedMatches.count > 1 || identityMatches.count > 1) {
        if (error) *error = FFNamedError(49, @"ASSET_NOT_FOUND",
            [NSString stringWithFormat:@"Multiple verified %@ candidates were found; update aborted safely.", displayName]);
        return nil;
    }
    if (identityMatches.count == 1) return [NSURL fileURLWithPath:identityMatches.anyObject];
    if (error) *error = FFNamedError(49, @"ASSET_NOT_FOUND",
        [NSString stringWithFormat:@"The exact %@ target was not found. No unique filename or Unity bundle identity matched; no file was changed.", displayName]);
    return nil;
}

static BOOL FFVerifyDirectAssetTarget(NSURL *target, NSError **error) {
    errno = 0;
    int readDescriptor = open(target.fileSystemRepresentation, O_RDONLY | O_CLOEXEC);
    if (readDescriptor < 0) {
        NSError *posix = FFPOSIXAccessError(63, @"Required asset read open", target, errno);
        if (error) *error = FFNamedError(63, @"READ_FAILED", posix.localizedDescription);
        return NO;
    }
    unsigned char header[8] = {0};
    ssize_t bytesRead = read(readDescriptor, header, sizeof(header));
    close(readDescriptor);
    const unsigned char unityHeader[] = {'U','n','i','t','y','F','S',0};
    if (bytesRead != (ssize_t)sizeof(header) || memcmp(header, unityHeader, sizeof(unityHeader)) != 0) {
        if (error) *error = FFNamedError(63, @"READ_FAILED", @"Required asset is not a readable UnityFS file.");
        return NO;
    }
    errno = 0;
    int writeDescriptor = open(target.fileSystemRepresentation, O_WRONLY | O_CLOEXEC);
    if (writeDescriptor < 0) {
        NSError *posix = FFPOSIXAccessError(64, @"Required asset write open", target, errno);
        if (error) *error = FFNamedError(64, @"WRITE_FAILED", posix.localizedDescription);
        return NO;
    }
    close(writeDescriptor);
    FFDiagnosticLog(@"AccessVerifier", @"Open/Read/Write: SUCCESS (%@)", target.lastPathComponent);
    return YES;
}

static BOOL FFInstallHologramPackage(NSData *package, NSString *selectedGameIdentifier,
                                     NSString **targetPath, NSError **error) {
    if (![selectedGameIdentifier isEqualToString:FFBundleIDFreeFireTH]) {
        if (error) *error = FFError(52, @"Hologram is available only for FREE FIRE TH.");
        return NO;
    }
    if (package.length < 12 || memcmp(package.bytes, "FFPKG001", 8) != 0) {
        if (error) *error = FFError(50, @"Hologram package is invalid.");
        return NO;
    }
    const uint8_t *bytes = package.bytes;
    uint32_t manifestLength = FFReadBE32(bytes + 8);
    if (!FFRangeFits(12, manifestLength, package.length)) {
        if (error) *error = FFError(50, @"Hologram manifest is invalid.");
        return NO;
    }
    NSDictionary *manifest = [NSJSONSerialization JSONObjectWithData:
        [package subdataWithRange:NSMakeRange(12, manifestLength)] options:0 error:error];
    NSArray *files = [manifest[@"files"] isKindOfClass:NSArray.class] ? manifest[@"files"] : nil;
    if (![manifest[@"feature"] isEqualToString:@"HOLOGRAM_GUN"] || files.count != 1) {
        if (error) *error = FFError(50, @"Hologram package metadata is invalid.");
        return NO;
    }
    NSUInteger payloadOffset = 12 + manifestLength;
    NSMutableDictionary<NSString *, NSData *> *validated = [NSMutableDictionary dictionary];
    for (NSDictionary *entry in files) {
        NSString *name = entry[@"name"];
        unsigned long long offset = [entry[@"offset"] unsignedLongLongValue];
        unsigned long long size = [entry[@"size"] unsignedLongLongValue];
        if (![name isEqualToString:FFHologramShaderFilename] ||
            !FFRangeFits(payloadOffset + offset, size, package.length)) return NO;
        NSData *data = [package subdataWithRange:NSMakeRange(payloadOffset + (NSUInteger)offset, (NSUInteger)size)];
        if (![ZXDigest(data) isEqualToString:entry[@"sha256"]]) return NO;
        validated[name] = data;
    }
    NSData *shader = validated[FFHologramShaderFilename];
    if (!shader.length || !FFDataLooksLikeUnityBundle(shader)) {
        if (error) *error = FFError(50, @"Hologram shader data is invalid.");
        return NO;
    }
    NSString *gameIdentifier = nil;
    NSURL *assetBundles = nil;
    NSURL *container = FFDirectGameContainer(selectedGameIdentifier, &gameIdentifier, nil, &assetBundles, error);
    if (!container) return NO;
    if (![gameIdentifier isEqualToString:FFBundleIDFreeFireTH]) {
        if (error) *error = FFError(52, @"Hologram is available only for Free Fire, not Free Fire MAX.");
        return NO;
    }
    NSURL *target = FFFindUniqueAssetTarget(container, assetBundles, FFHologramShaderFilename,
        @"Hologram shader", NO, error);
    if (!target) return NO;
    if (!FFVerifyDirectAssetTarget(target, error)) return NO;
    if (!FFInstallRawData(target, shader, error)) return NO;
    if (targetPath) *targetPath = target.path;
    return YES;
}

static BOOL FFInstallThreeDData(NSData *data, NSString *selectedGameIdentifier,
                                NSString **targetPath, NSError **error) {
    if (!FFGameDefinition(selectedGameIdentifier)) {
        if (error) *error = FFNamedError(60, @"GAME_NOT_FOUND", @"Selected game is unsupported.");
        return NO;
    }
    if (data.length < 100000 || data.length > 2000000 || !FFDataLooksLikeUnityBundle(data)) {
        if (error) *error = FFNamedError(50, @"ASSET_NOT_FOUND", @"3D resource is not a valid UnityFS bundle.");
        return NO;
    }
    NSString *detectedIdentifier = nil;
    NSURL *assetBundles = nil;
    NSURL *container = FFDirectGameContainer(selectedGameIdentifier, &detectedIdentifier, nil,
        &assetBundles, error);
    if (!container || ![detectedIdentifier isEqualToString:selectedGameIdentifier]) {
        if (error && !*error) *error = FFNamedError(60, @"CONTAINER_NOT_FOUND", @"Game data container was not discovered by bundle ID.");
        return NO;
    }
    NSURL *target = FFFindUniqueAssetTarget(container, assetBundles, FFThreeDShaderFilename,
        @"3D shader", NO, error);
    if (!target) return NO;
    if (!FFVerifyDirectAssetTarget(target, error)) return NO;
    if (!FFInstallRawData(target, data, error)) return NO;
    if (targetPath) *targetPath = target.path;
    return YES;
}

static BOOL FFRestoreOriginal(NSURL *target, NSError **error) {
    NSURL *backup = [NSURL fileURLWithPath:[target.path stringByAppendingString:FFBackupSuffix]];
    NSData *data = [NSData dataWithContentsOfURL:backup options:NSDataReadingMappedIfSafe error:error];
    if (!data) {
        if (error && !*error) *error = FFNamedError(15, @"RESTORE_FAILED", @"Original backup was not found.");
        return NO;
    }
    if (!FFReplaceTargetWithData(target, data, error)) {
        if (error && !*error) *error = FFNamedError(51, @"RESTORE_FAILED", @"Original data could not be restored.");
        return NO;
    }
    FFDiagnosticLog(@"ApplyManager", @"RESTORE_SUCCESS: original SHA256 verified");
    return YES;
}

static BOOL FFRestoreDirectAsset(NSString *gameIdentifier, NSString *filename,
                                 NSString *displayName, NSString **targetPath, NSError **error) {
    NSString *detectedIdentifier = nil;
    NSURL *assetBundles = nil;
    NSURL *container = FFDirectGameContainer(gameIdentifier, &detectedIdentifier, nil,
        &assetBundles, error);
    if (!container || ![detectedIdentifier isEqualToString:gameIdentifier]) {
        if (error && !*error) *error = FFNamedError(60, @"CONTAINER_NOT_FOUND", @"Game container is unavailable for restore.");
        return NO;
    }
    NSURL *target = FFFindUniqueAssetTarget(container, assetBundles, filename, displayName, YES, error);
    if (!target || !FFRestoreOriginal(target, error)) return NO;
    if (targetPath) *targetPath = target.path;
    return YES;
}

static void FFSaveHologramState(NSString *gameIdentifier, NSString *color,
                                NSString *targetPath, NSInteger durationDays) {
    NSDate *applied = [NSDate date];
    NSTimeInterval seconds = (durationDays == 3 ? 3 : 1) * 86400.0;
    NSDictionary *state = @{
        @"game": gameIdentifier ?: @"",
        @"color": color ?: @"",
        @"target": targetPath ?: @"",
        @"applied_at": @([applied timeIntervalSince1970]),
        @"expires_at": @([applied timeIntervalSince1970] + seconds),
        @"duration_days": @(durationDays == 3 ? 3 : 1),
    };
    [NSUserDefaults.standardUserDefaults setObject:state forKey:FFHologramStateKey];
    FFDiagnosticLog(@"ApplyManager", @"Hologram state saved: applied=%@ expires=%@",
        state[@"applied_at"], state[@"expires_at"]);
}

static BOOL FFRestoreExpiredHologram(BOOL *restoreNeeded, NSString **gameOut,
                                     NSString **pathOut, NSError **error) {
    NSDictionary *state = [NSUserDefaults.standardUserDefaults dictionaryForKey:FFHologramStateKey];
    NSString *game = [state[@"game"] isKindOfClass:NSString.class] ? state[@"game"] : nil;
    NSNumber *expires = [state[@"expires_at"] isKindOfClass:NSNumber.class] ? state[@"expires_at"] : nil;
    BOOL expired = FFGameDefinition(game) && expires && expires.doubleValue <= NSDate.date.timeIntervalSince1970;
    if (restoreNeeded) *restoreNeeded = expired;
    if (!expired) return YES;
    if (gameOut) *gameOut = game;
    FFDiagnosticLog(@"ApplyManager", @"HOLOGRAM_EXPIRED: automatic restore requested");
    NSString *detectedIdentifier = nil;
    NSURL *assetBundles = nil;
    NSURL *container = FFDirectGameContainer(game, &detectedIdentifier, nil, &assetBundles, error);
    if (!container || ![detectedIdentifier isEqualToString:game]) {
        if (error && !*error) *error = FFNamedError(60, @"CONTAINER_NOT_FOUND", @"Expired Hologram state kept for the next access attempt.");
        return NO;
    }
    NSURL *target = FFFindUniqueAssetTarget(container, assetBundles, FFHologramShaderFilename,
        @"Hologram shader", YES, error);
    if (!target || !FFRestoreOriginal(target, error)) {
        if (error && !*error) *error = FFNamedError(51, @"RESTORE_FAILED", @"Expired Hologram state was retained for retry.");
        return NO;
    }
    if (pathOut) *pathOut = target.path;
    [NSUserDefaults.standardUserDefaults removeObjectForKey:FFHologramStateKey];
    NSString *activeKey = FFActiveProfileDefaultsKey(game);
    if (activeKey) [NSUserDefaults.standardUserDefaults removeObjectForKey:activeKey];
    FFDiagnosticLog(@"ApplyManager", @"RESTORE_SUCCESS: expired Hologram restored and state cleared");
    return YES;
}

typedef void (^FFVerifiedTargetOperation)(NSURL *target, NSError **operationError);

@interface FFFeatureManager : NSObject
+ (BOOL)installProfileData:(NSData *)data
                   forGame:(NSString *)gameIdentifier
              accessMethod:(FFAccessMethod)accessMethod
                targetPath:(NSString **)targetPath
                     error:(NSError **)error;
+ (BOOL)restoreOriginalForGame:(NSString *)gameIdentifier
                  accessMethod:(FFAccessMethod)accessMethod
                    targetPath:(NSString **)targetPath
                         error:(NSError **)error;
@end

@implementation FFFeatureManager
+ (BOOL)performTargetOperationForGame:(NSString *)gameIdentifier
                         accessMethod:(FFAccessMethod)accessMethod
                      allowBackupOnly:(BOOL)allowBackupOnly
                            operation:(FFVerifiedTargetOperation)operation
                           targetPath:(NSString **)targetPath
                                error:(NSError **)error {
    FFDiagnosticLog(@"FeatureManager", @"Requested access method: %@", FFAccessMethodName(accessMethod));
    FFAccessContext *context = nil;
    NSURL *authorizedRoot = nil;
    if (accessMethod == FFAccessMethodDirect) {
        context = [FFGameDetector detectDirectContainerForGame:gameIdentifier];
        if (context.discovered) {
            [FFAccessVerifier verifyContext:context requiresWrite:YES allowBackupOnly:allowBackupOnly];
        }
    } else if (accessMethod == FFAccessMethodAuthorizedFolder) {
        NSError *bookmarkError = nil;
        BOOL stale = NO;
        authorizedRoot = [FFAccessManager beginBookmarkedFolderAccessWithStale:&stale error:&bookmarkError];
        context = [FFAccessContext new];
        context.method = FFAccessMethodAuthorizedFolder;
        context.gameIdentifier = gameIdentifier;
        context.rootURL = authorizedRoot;
        context.discovered = authorizedRoot != nil;
        context.error = bookmarkError;
        if (authorizedRoot) {
            [FFAccessVerifier verifyContext:context requiresWrite:YES allowBackupOnly:allowBackupOnly];
        }
    } else {
        context = [FFAccessContext new];
        context.error = FFError(67, @"No verified filesystem access method is active.");
    }

    if (!context.usable || !context.targetURL) {
        if (authorizedRoot) [FFAccessManager endBookmarkedFolderAccess:authorizedRoot];
        if (error) *error = context.error ?: FFError(67, @"Filesystem access must be verified again.");
        FFDiagnosticLog(@"FeatureManager", @"Final access state: FAILED (%@)",
            context.error.localizedDescription ?: @"verification failed");
        return NO;
    }

    if (targetPath) *targetPath = context.targetURL.path;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    __block NSError *operationError = nil;
    NSError *coordinationError = nil;
    [coordinator coordinateWritingItemAtURL:context.targetURL
                                    options:NSFileCoordinatorWritingForReplacing
                                      error:&coordinationError
                                 byAccessor:^(NSURL *coordinatedTarget) {
        operation(coordinatedTarget, &operationError);
    }];
    if (!operationError && coordinationError) operationError = coordinationError;
    if (authorizedRoot) [FFAccessManager endBookmarkedFolderAccess:authorizedRoot];
    if (operationError) {
        if (error) *error = operationError;
        FFDiagnosticLog(@"FeatureManager", @"Final access state: FAILED (%@)", operationError.localizedDescription);
        return NO;
    }
    FFDiagnosticLog(@"FeatureManager", @"Final access state: SUCCESS");
    return YES;
}

+ (BOOL)installProfileData:(NSData *)data
                   forGame:(NSString *)gameIdentifier
              accessMethod:(FFAccessMethod)accessMethod
                targetPath:(NSString **)targetPath
                     error:(NSError **)error {
    return [self performTargetOperationForGame:gameIdentifier
                                  accessMethod:accessMethod
                               allowBackupOnly:NO
                                     operation:^(NSURL *target, NSError **operationError) {
        if (!FFInstallFeatureData(data, target, operationError) && operationError && !*operationError) {
            *operationError = FFError(51, @"Option installation failed.");
        }
    } targetPath:targetPath error:error];
}

+ (BOOL)restoreOriginalForGame:(NSString *)gameIdentifier
                  accessMethod:(FFAccessMethod)accessMethod
                    targetPath:(NSString **)targetPath
                         error:(NSError **)error {
    return [self performTargetOperationForGame:gameIdentifier
                                  accessMethod:accessMethod
                               allowBackupOnly:YES
                                     operation:^(NSURL *target, NSError **operationError) {
        if (!FFRestoreOriginal(target, operationError) && operationError && !*operationError) {
            *operationError = FFError(51, @"Restore failed.");
        }
    } targetPath:targetPath error:error];
}
@end

typedef void (^FFHologramSelectionHandler)(NSDictionary *color);

@interface FFHologramPickerController : UIViewController
- (instancetype)initWithColors:(NSArray<NSDictionary *> *)colors
                           title:(NSString *)title
                      applyTitle:(NSString *)applyTitle
                     selection:(FFHologramSelectionHandler)selection;
@end

@implementation FFHologramPickerController {
    NSArray<NSDictionary *> *_colors;
    FFHologramSelectionHandler _selection;
    NSArray<UIButton *> *_colorButtons;
    UIButton *_applyButton;
    NSInteger _selectedIndex;
    NSString *_pickerTitle;
    NSString *_pickerApplyTitle;
}

- (instancetype)initWithColors:(NSArray<NSDictionary *> *)colors
                           title:(NSString *)title
                      applyTitle:(NSString *)applyTitle
                     selection:(FFHologramSelectionHandler)selection {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _colors = [colors copy];
        _selection = [selection copy];
        _pickerTitle = [title copy] ?: @"OPTIONS";
        _pickerApplyTitle = [applyTitle copy] ?: @"APPLY";
        _selectedIndex = NSNotFound;
        self.modalPresentationStyle = UIModalPresentationPageSheet;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.view.backgroundColor = FFVIPBackground();
    UIImage *robotImage = [UIImage imageNamed:@"FFCacheManagerBackground.jpg"];
    if (robotImage) {
        UIImageView *robotView = [[UIImageView alloc] initWithImage:robotImage];
        robotView.frame = self.view.bounds;
        robotView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        robotView.contentMode = UIViewContentModeScaleAspectFill;
        robotView.alpha = 0.08;
        [self.view addSubview:robotView];
    }
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:18],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-18],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:20],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-24],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-36],
    ]];
    UILabel *title = [UILabel new];
    title.text = _pickerTitle;
    title.textColor = FFPrimaryText();
    title.font = [UIFont systemFontOfSize:28 weight:UIFontWeightHeavy];
    [stack addArrangedSubview:title];
    UILabel *subtitle = [UILabel new];
    subtitle.text = @"SELECT COLOR";
    subtitle.textColor = FFStatusCyan();
    subtitle.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightBold];
    [stack addArrangedSubview:subtitle];

    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    NSMutableArray<UIButton *> *rowButtons = [NSMutableArray array];
    for (NSUInteger index = 0; index < _colors.count; index++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = (NSInteger)index;
        [button setTitle:_colors[index][@"label"] forState:UIControlStateNormal];
        [button setTitleColor:FFPrimaryText() forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        button.backgroundColor = FFVIPPanel();
        button.layer.cornerRadius = 17;
        button.layer.cornerCurve = kCACornerCurveContinuous;
        button.layer.borderWidth = 1;
        button.layer.borderColor = [FFVIPGold() colorWithAlphaComponent:0.16].CGColor;
        button.accessibilityLabel = [NSString stringWithFormat:@"%@ %@ option",
            _colors[index][@"label"], _pickerTitle];
        [button.heightAnchor constraintEqualToConstant:72].active = YES;
        [button addTarget:self action:@selector(selectColor:) forControlEvents:UIControlEventTouchUpInside];
        FFPrepareExistingButtonForVisualFeedback(button);
        [buttons addObject:button];
        [rowButtons addObject:button];
        if (rowButtons.count == 2) {
            UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:rowButtons];
            row.axis = UILayoutConstraintAxisHorizontal;
            row.spacing = 12;
            row.distribution = UIStackViewDistributionFillEqually;
            [stack addArrangedSubview:row];
            rowButtons = [NSMutableArray array];
        }
    }
    if (rowButtons.count) {
        UIView *spacer = [UIView new];
        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[rowButtons.firstObject, spacer]];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.spacing = 12;
        row.distribution = UIStackViewDistributionFillEqually;
        [stack addArrangedSubview:row];
    }
    _colorButtons = buttons;
    _applyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_applyButton setTitle:_pickerApplyTitle forState:UIControlStateNormal];
    [_applyButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _applyButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    _applyButton.backgroundColor = FFVIPGold();
    _applyButton.layer.cornerRadius = 18;
    _applyButton.layer.cornerCurve = kCACornerCurveContinuous;
    _applyButton.layer.shadowColor = FFVIPGold().CGColor;
    _applyButton.layer.shadowOpacity = 0.20;
    _applyButton.layer.shadowRadius = 14;
    _applyButton.layer.shadowOffset = CGSizeMake(0, 6);
    _applyButton.enabled = NO;
    _applyButton.alpha = 0.42;
    [_applyButton.heightAnchor constraintEqualToConstant:54].active = YES;
    [_applyButton addTarget:self action:@selector(applyColor) forControlEvents:UIControlEventTouchUpInside];
    FFPrepareExistingButtonForVisualFeedback(_applyButton);
    [stack addArrangedSubview:_applyButton];
    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancel setTitle:@"CANCEL" forState:UIControlStateNormal];
    [cancel setTitleColor:FFSecondaryText() forState:UIControlStateNormal];
    cancel.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    cancel.layer.cornerRadius = 16;
    cancel.layer.cornerCurve = kCACornerCurveContinuous;
    cancel.layer.borderWidth = 1;
    cancel.layer.borderColor = [FFLilac() colorWithAlphaComponent:0.72].CGColor;
    cancel.contentEdgeInsets = UIEdgeInsetsMake(12, 18, 12, 18);
    [cancel addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    FFPrepareExistingButtonForVisualFeedback(cancel);
    [stack addArrangedSubview:cancel];
}

- (void)selectColor:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= (NSInteger)_colors.count) return;
    _selectedIndex = sender.tag;
    for (UIButton *button in _colorButtons) {
        BOOL selected = button.tag == _selectedIndex;
        button.layer.borderColor = [(selected ? FFVIPGold() : FFLilac())
            colorWithAlphaComponent:selected ? 0.86 : 0.34].CGColor;
        button.backgroundColor = selected ? [FFVIPGold() colorWithAlphaComponent:0.16] : FFVIPPanel();
        button.accessibilityValue = selected ? @"selected" : @"not selected";
    }
    _applyButton.enabled = YES;
    _applyButton.alpha = 1.0;
}

- (void)applyColor {
    if (_selectedIndex == NSNotFound || _selectedIndex >= (NSInteger)_colors.count) return;
    NSDictionary *color = _colors[(NSUInteger)_selectedIndex];
    [self dismissViewControllerAnimated:YES completion:^{
        if (self->_selection) self->_selection(color);
    }];
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

typedef NS_ENUM(NSInteger, FFAppScreen) {
    FFAppScreenAccess,
    FFAppScreenGameSelection,
    FFAppScreenMain,
};

typedef NS_ENUM(NSInteger, FFMainTab) {
    FFMainTabGame,
    FFMainTabControl,
    FFMainTabStatus,
};

@interface FFHomeViewController : UIViewController <UIDocumentPickerDelegate>
@end

@interface FFHomeViewController ()
- (void)activateLicenseValue:(NSString *)licenseKey;
- (void)restoreSessionIfAvailable;
- (void)refreshSessionForOperation:(void (^)(NSString *accessToken, NSError *error))completion;
- (void)beginHologramColorSelection;
- (void)presentHologramColors:(NSArray<NSDictionary *> *)colors;
- (void)beginThreeDColorSelection;
- (void)presentThreeDColors:(NSArray<NSDictionary *> *)colors;
- (void)chooseHologramDurationForColor:(NSDictionary *)color;
- (void)restoreExpiredHologramIfNeeded;
- (void)applyFeature:(NSString *)feature color:(NSString *)color expectedHash:(NSString *)expectedHash
        durationDays:(NSInteger)durationDays;
- (void)updateGameRouting:(NSString *)gameIdentifier;
- (void)installFeatureDataFromSelectedFolder:(NSData *)profileData feature:(NSString *)feature;
- (void)restoreOriginalFromSelectedFolder;
- (void)rebuildInterface;
- (void)loadFeatureCatalogForSelectedGame;
- (void)fetchServerStatus;
- (void)applySelectedFeature;
- (void)inspectDirectAccessWithCompletion:(void (^)(BOOL ready))completion;
- (void)finishAccessAttemptWithContext:(FFAccessContext *)context
                             completion:(void (^)(BOOL ready))completion;
- (void)runSelectedGame;
- (void)logoutChangeKeyPressed;
- (void)activateClipboardLicenseIfAvailable;
- (void)clipboardChanged:(NSNotification *)notification;
- (void)licenseFieldChanged:(UITextField *)field;
@end

@implementation FFHomeViewController {
    UILabel *_statusLabel;
    UILabel *_activeLabel;
    UITextField *_licenseField;
    UIButton *_licenseButton;
    UIButton *_folderButton;
    UIButton *_compatibilityFolderButton;
    UIButton *_restoreButton;
    NSArray<UIButton *> *_featureButtons;
    NSArray<UIView *> *_featureRows;
    NSArray<NSString *> *_features;
    NSSet<NSString *> *_allowedFeatures;
    NSSet<NSString *> *_serverAvailableFeatures;
    NSString *_activationToken;
    NSString *_connectedGameIdentifier;
    NSString *_selectedGameIdentifier;
    NSString *_selectedFeature;
    NSString *_operationFeature;
    NSString *_statusText;
    NSString *_activeText;
    NSDictionary *_licenseSnapshot;
    NSDictionary *_deviceSnapshot;
    NSDictionary *_sessionSnapshot;
    NSDictionary *_serverSnapshot;
    NSString *_serverStatusError;
    FFAccessContext *_accessContext;
    NSDate *_lastValidationDate;
    UIScrollView *_rootScroll;
    UIStackView *_rootStack;
    UISegmentedControl *_tabControl;
    UIButton *_continueButton;
    UIButton *_applyButton;
    UIButton *_runButton;
    UIButton *_logoutButton;
    NSUInteger _sessionGeneration;
    NSInteger _lastClipboardChangeCount;
    FFAccessMethod _accessMethod;
    void (^_pendingAccessCompletion)(BOOL ready);
    BOOL _clipboardActivationAttempted;
    BOOL _folderPickerPresented;
    FFAppScreen _screen;
    FFMainTab _selectedTab;
    BOOL _licensed;
    BOOL _busy;
    BOOL _usingSelectedFolder;
    BOOL _statusIsError;
    BOOL _gameInstalled;
    BOOL _readyToRun;
    BOOL _hologramRestoreInProgress;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"NOVA BODY";
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.view.backgroundColor = FFVIPBackground();
    // Decorative layer only: it sits behind the existing interface and does
    // not participate in hit testing or alter any current control.
    UIImage *robotImage = [UIImage imageNamed:@"FFCacheManagerBackground.jpg"];
    if (robotImage) {
        UIImageView *robotView = [[UIImageView alloc] initWithImage:robotImage];
        robotView.translatesAutoresizingMaskIntoConstraints = NO;
        robotView.contentMode = UIViewContentModeScaleAspectFill;
        robotView.alpha = 0.22;
        robotView.clipsToBounds = YES;
        [self.view insertSubview:robotView atIndex:0];
        [NSLayoutConstraint activateConstraints:@[
            [robotView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [robotView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [robotView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [robotView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        ]];
    }
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = FFVIPBackground();
    appearance.titleTextAttributes = @{NSForegroundColorAttributeName: FFPrimaryText()};
    appearance.largeTitleTextAttributes = @{NSForegroundColorAttributeName: FFPrimaryText()};
    self.navigationController.navigationBar.standardAppearance = appearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
#ifdef FM_OFFLINE_BUILD
    // This product keeps the FF Cache Manager interface.  The 3105 component is only
    // the internal MCM/container access engine; its Cleaner/Wallpaper UI and
    // unrelated modules are intentionally not part of this build.
    _features = @[@"BODY", @"NECK"];
#else
    _features = @[@"BODY", @"NECK"];
#endif
    _allowedFeatures = [NSSet set];
    _serverAvailableFeatures = [NSSet set];
#ifdef FM_OFFLINE_BUILD
    _statusText = @"LOCAL MODE — READY";
    _activeText = @"—";
    _screen = FFAppScreenGameSelection;
    _selectedTab = FFMainTabControl;
    _licensed = YES;
    _activationToken = @"OFFLINE";
    _allowedFeatures = FFBundledOfflineFeatures();
    _serverAvailableFeatures = FFBundledOfflineFeatures();
#else
    _statusText = @"CHECKING SECURE SESSION…";
    _activeText = @"—";
    _screen = FFAppScreenAccess;
    _selectedTab = FFMainTabControl;
#endif
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    _lastClipboardChangeCount = UIPasteboard.generalPasteboard.changeCount;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clipboardChanged:)
                                                 name:UIPasteboardChangedNotification
                                               object:UIPasteboard.generalPasteboard];
    [self buildInterface];
#ifndef FM_OFFLINE_BUILD
    _licenseField.text = @"";
    FFKeychainDelete(FFLegacyLicenseAccount);
    [self fetchServerStatus];
    [self restoreSessionIfAvailable];
#endif
}

- (UILabel *)labelWithText:(NSString *)text font:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = font;
    label.textColor = color;
    label.numberOfLines = 0;
    return label;
}

- (UIView *)cardWithContent:(UIView *)content {
    UIView *card = [UIView new];
    card.backgroundColor = FFVIPPanel();
    card.layer.cornerRadius = 16;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [FFVIPGold() colorWithAlphaComponent:0.20].CGColor;
    card.layer.shadowColor = FFVIPGold().CGColor;
    card.layer.shadowOpacity = 0.14;
    card.layer.shadowRadius = 18;
    card.layer.shadowOffset = CGSizeMake(0, 4);
    [card addSubview:content];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [content.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [content.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [content.topAnchor constraintEqualToAnchor:card.topAnchor constant:15],
        [content.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-15]
    ]];
    return card;
}

- (UIButton *)actionButton:(NSString *)title color:(UIColor *)color selector:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [button setTitleColor:FFPrimaryText() forState:UIControlStateNormal];
    button.backgroundColor = color;
    button.layer.cornerRadius = 12;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.layer.shadowColor = color.CGColor;
    button.layer.shadowOpacity = 0.20;
    button.layer.shadowRadius = 14;
    button.layer.shadowOffset = CGSizeMake(0, 6);
    button.contentEdgeInsets = UIEdgeInsetsMake(14, 18, 14, 18);
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    FFPrepareExistingButtonForVisualFeedback(button);
    return button;
}

- (void)buildInterface {
    [self rebuildInterface];
}

- (UILabel *)statusBadgeWithText:(NSString *)text active:(BOOL)active tint:(UIColor *)tint {
    UILabel *label = [self labelWithText:text
        font:[UIFont systemFontOfSize:11 weight:UIFontWeightBold]
        color:active ? tint : UIColor.secondaryLabelColor];
    label.backgroundColor = [(active ? tint : UIColor.secondaryLabelColor) colorWithAlphaComponent:0.10];
    label.layer.cornerRadius = 9;
    label.layer.cornerCurve = kCACornerCurveContinuous;
    label.clipsToBounds = YES;
    label.textAlignment = NSTextAlignmentCenter;
    label.accessibilityLabel = text;
    [label.heightAnchor constraintGreaterThanOrEqualToConstant:34].active = YES;
    return label;
}

- (UIView *)informationRow:(NSString *)title value:(NSString *)value {
    UIStackView *row = [UIStackView new];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 12;
    UILabel *left = [self labelWithText:title
        font:[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold]
        color:FFSecondaryText()];
    UILabel *right = [self labelWithText:value.length ? value : @"—"
        font:[UIFont systemFontOfSize:12 weight:UIFontWeightBold]
        color:FFPrimaryText()];
    right.textAlignment = NSTextAlignmentRight;
    [right setContentCompressionResistancePriority:UILayoutPriorityRequired
        forAxis:UILayoutConstraintAxisHorizontal];
    [row addArrangedSubview:left];
    [row addArrangedSubview:right];
    return row;
}

- (void)addConsoleHeader:(NSString *)title subtitle:(NSString *)subtitle toStack:(UIStackView *)stack {
    [stack addArrangedSubview:[self labelWithText:@"NOVA BODY  •  LOCAL CONTROL"
        font:[UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightBold] color:FFVIPGold()]];
    [stack addArrangedSubview:[self labelWithText:title
        font:[UIFont systemFontOfSize:28 weight:UIFontWeightHeavy] color:FFPrimaryText()]];
    if (subtitle.length) {
        [stack addArrangedSubview:[self labelWithText:subtitle
            font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
            color:FFSecondaryText()]];
    }
}

- (void)addLogoutChangeKeyButtonToStack:(UIStackView *)stack {
#ifdef FM_OFFLINE_BUILD
    (void)stack;
    return;
#endif
    if (!_licensed) return;
    _logoutButton = [self actionButton:@"LOGOUT / CHANGE KEY"
        color:UIColor.systemRedColor selector:@selector(logoutChangeKeyPressed)];
    _logoutButton.accessibilityLabel = @"Logout and change license key";
    [_logoutButton.heightAnchor constraintGreaterThanOrEqualToConstant:48].active = YES;
    [stack addArrangedSubview:_logoutButton];
}

- (UIButton *)gameCard:(NSDictionary<NSString *, NSString *> *)game index:(NSInteger)index {
    BOOL selected = [_selectedGameIdentifier isEqualToString:game[@"bundleIdentifier"]];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.tag = index;
    button.titleLabel.numberOfLines = 0;
    button.titleLabel.textAlignment = NSTextAlignmentLeft;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.contentEdgeInsets = UIEdgeInsetsMake(20, 18, 20, 18);
    NSString *title = [NSString stringWithFormat:@"%@%@\n%@\n%@",
        game[@"displayName"], selected ? @"  ✓" : @"", game[@"subtitle"], game[@"bundleIdentifier"]];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:selected ? FFPrimaryText() : FFSecondaryText()
        forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    button.backgroundColor = FFVIPPanel();
    button.layer.cornerRadius = 22;
    button.layer.cornerCurve = kCACornerCurveContinuous;
    button.layer.borderWidth = selected ? 1.5 : 1.0;
    button.layer.borderColor = [(selected ? FFVIPGold() : FFLilac())
        colorWithAlphaComponent:selected ? 0.78 : 0.09].CGColor;
    button.layer.shadowColor = FFVIPGold().CGColor;
    button.layer.shadowOpacity = selected ? 0.24 : 0.0;
    button.layer.shadowRadius = 14;
    button.layer.shadowOffset = CGSizeMake(0, 6);
    button.accessibilityLabel = [NSString stringWithFormat:@"%@, %@",
        game[@"displayName"], selected ? @"selected" : @"not selected"];
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:132].active = YES;
    [button addTarget:self action:@selector(selectGameCard:) forControlEvents:UIControlEventTouchUpInside];
    FFPrepareExistingButtonForVisualFeedback(button);
    return button;
}

- (void)buildAccessContent {
    [self addConsoleHeader:@"VIP ACCESS"
        subtitle:@"Secure, device-bound access validated by the server." toStack:_rootStack];

    UIStackView *security = [UIStackView new];
    security.axis = UILayoutConstraintAxisVertical;
    security.spacing = 9;
    BOOL sessionActive = _licensed && _activationToken.length;
    BOOL deviceVerified = [_deviceSnapshot[@"status"] isEqualToString:@"ACTIVE"];
    BOOL serverLive = [_serverSnapshot[@"success"] boolValue];
    [security addArrangedSubview:[self statusBadgeWithText:
        sessionActive ? @"●  SECURE SESSION" : @"○  SESSION PENDING"
        active:sessionActive tint:UIColor.systemGreenColor]];
    [security addArrangedSubview:[self statusBadgeWithText:
        deviceVerified ? @"●  DEVICE BOUND" : @"○  DEVICE PENDING"
        active:deviceVerified tint:FFStatusCyan()]];
    NSString *serverBadge = serverLive ? @"●  SERVER LIVE" :
        (_serverStatusError.length ? @"!  SERVER UNAVAILABLE" : @"○  SERVER CHECKING");
    [security addArrangedSubview:[self statusBadgeWithText:serverBadge
        active:serverLive tint:serverLive ? UIColor.systemGreenColor :
            (_serverStatusError.length ? UIColor.systemRedColor : UIColor.systemGrayColor)]];
    [_rootStack addArrangedSubview:[self cardWithContent:security]];

    _licenseField = [UITextField new];
    _licenseField.placeholder = @"ENTER OWNER LICENSE";
    _licenseField.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:@"ENTER OWNER LICENSE"
        attributes:@{NSForegroundColorAttributeName: UIColor.tertiaryLabelColor}];
    _licenseField.textColor = FFPrimaryText();
    _licenseField.secureTextEntry = YES;
    _licenseField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _licenseField.returnKeyType = UIReturnKeyDone;
    _licenseField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    _licenseField.autocorrectionType = UITextAutocorrectionTypeNo;
    _licenseField.spellCheckingType = UITextSpellCheckingTypeNo;
    _licenseField.backgroundColor = FFVIPPanel();
    _licenseField.layer.cornerRadius = 18;
    _licenseField.layer.cornerCurve = kCACornerCurveContinuous;
    _licenseField.layer.borderWidth = 1;
    _licenseField.layer.borderColor = [FFLilac() colorWithAlphaComponent:0.72].CGColor;
    _licenseField.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightSemibold];
    _licenseField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    _licenseField.leftViewMode = UITextFieldViewModeAlways;
    [_licenseField addTarget:self action:@selector(licenseFieldChanged:)
            forControlEvents:UIControlEventEditingChanged];
    [_licenseField.heightAnchor constraintEqualToConstant:54].active = YES;
    [_rootStack addArrangedSubview:_licenseField];

    _licenseButton = [self actionButton:@"ACTIVATE VIP" color:FFVIPGold()
        selector:@selector(activateLicensePressed)];
    [_rootStack addArrangedSubview:_licenseButton];

    UIStackView *statusStack = [UIStackView new];
    statusStack.axis = UILayoutConstraintAxisVertical;
    statusStack.spacing = 6;
    _statusLabel = [self labelWithText:_statusText ?: @"LICENSE REQUIRED"
        font:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
        color:_statusIsError ? UIColor.systemRedColor : UIColor.labelColor];
    _activeLabel = [self labelWithText:[NSString stringWithFormat:@"ACTIVE: %@", _activeText ?: @"—"]
        font:[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold] color:FFVIPGold()];
    [statusStack addArrangedSubview:_statusLabel];
    [statusStack addArrangedSubview:_activeLabel];
    [_rootStack addArrangedSubview:[self cardWithContent:statusStack]];

    // This is deliberately scheduled after the field and status card exist.
    // It reads only a key-shaped clipboard value and never writes the key to
    // persistent storage.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self activateClipboardLicenseIfAvailable];
    });
}

- (void)buildGameSelectionContent:(BOOL)insideMain {
    [self addConsoleHeader:@"SELECT GAME"
        subtitle:@"Every authorization and file operation is locked to this selection."
        toStack:_rootStack];
    [self addLogoutChangeKeyButtonToStack:_rootStack];
    NSArray *games = FFSupportedGames();
    for (NSUInteger index = 0; index < games.count; index++) {
        [_rootStack addArrangedSubview:[self gameCard:games[index] index:(NSInteger)index]];
    }
#ifdef FM_OFFLINE_BUILD
    [_rootStack addArrangedSubview:[self statusBadgeWithText:@"●  OFFLINE PROFILES READY"
        active:YES tint:UIColor.systemGreenColor]];
#else
    BOOL serverLive = [_serverSnapshot[@"success"] boolValue];
    [_rootStack addArrangedSubview:[self statusBadgeWithText:
        serverLive ? @"●  SERVER LIVE" : @"○  SERVER UNAVAILABLE"
        active:serverLive tint:UIColor.systemGreenColor]];
#endif
    _continueButton = [self actionButton:insideMain ? @"USE SELECTED GAME" : @"CONTINUE"
        color:FFVIPGold() selector:@selector(continueWithSelectedGame)];
    _continueButton.enabled = _selectedGameIdentifier.length > 0 && !_busy;
    _continueButton.alpha = _continueButton.enabled ? 1.0 : 0.42;
    [_rootStack addArrangedSubview:_continueButton];
}

- (void)buildFeatureGrid {
    NSSet<NSString *> *local = FFLocalFeaturesForGame(_selectedGameIdentifier);
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    NSMutableArray<UIView *> *cards = [NSMutableArray array];
    NSMutableArray<UIButton *> *currentRow = [NSMutableArray array];
    for (NSUInteger index = 0; index < _features.count; index++) {
        NSString *feature = _features[index];
        BOOL localFeature = [local containsObject:feature];
        BOOL plan = [_allowedFeatures containsObject:feature];
        BOOL server = [_serverAvailableFeatures containsObject:feature];
        BOOL available = localFeature && plan && server;
        BOOL selected = [_selectedFeature isEqualToString:feature];
        BOOL active = _readyToRun && [_activeText containsString:feature];
        NSString *state = !localFeature ? @"NOT AVAILABLE FOR GAME" :
            (active ? @"ACTIVE ✓" : (selected ? @"SELECTED" :
            (available ? @"AVAILABLE" : (plan ? @"UNAVAILABLE" : @"NOT IN PLAN"))));
        if (_busy && [_operationFeature isEqualToString:feature]) state = @"WORKING…";
        UIButton *card = [UIButton buttonWithType:UIButtonTypeSystem];
        card.tag = (NSInteger)index;
        card.titleLabel.numberOfLines = 0;
        card.titleLabel.textAlignment = NSTextAlignmentLeft;
        card.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        card.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        card.contentEdgeInsets = UIEdgeInsetsMake(17, 15, 17, 15);
        [card setTitle:[NSString stringWithFormat:@"%@\n%@", FFFeatureDisplayName(feature), state]
            forState:UIControlStateNormal];
        [card setTitleColor:available ? FFPrimaryText() : FFSecondaryText()
            forState:UIControlStateNormal];
        card.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        card.backgroundColor = FFVIPPanel();
        card.layer.cornerRadius = 14;
        card.layer.cornerCurve = kCACornerCurveContinuous;
        card.layer.borderWidth = selected ? 1.5 : 1.0;
        UIColor *border = active ? UIColor.systemGreenColor : (selected ? FFVIPGold() :
            (available ? FFVIPGold() : FFLilac()));
        card.layer.borderColor = [border colorWithAlphaComponent:
            (active || selected) ? 0.80 : (available ? 0.28 : 0.08)].CGColor;
        card.layer.shadowColor = border.CGColor;
        card.layer.shadowOpacity = (active || selected) ? 0.20 : 0.06;
        card.layer.shadowRadius = 14;
        card.layer.shadowOffset = CGSizeMake(0, 6);
        card.enabled = !_busy && available;
        card.alpha = card.enabled ? 1.0 : 0.56;
        card.accessibilityLabel = [NSString stringWithFormat:@"%@, %@",
            FFFeatureDisplayName(feature), state];
        [card.heightAnchor constraintEqualToConstant:126].active = YES;
        [card addTarget:self action:@selector(enableFeature:) forControlEvents:UIControlEventTouchUpInside];
        FFPrepareExistingButtonForVisualFeedback(card);
        [buttons addObject:card];
        [cards addObject:card];
        [currentRow addObject:card];
        if (currentRow.count == 1) {
            UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:currentRow];
            row.axis = UILayoutConstraintAxisHorizontal;
            row.spacing = 12;
            row.distribution = UIStackViewDistributionFillEqually;
            [_rootStack addArrangedSubview:row];
            currentRow = [NSMutableArray array];
        }
    }
    if (currentRow.count) {
        UIView *spacer = [UIView new];
        UIStackView *row = [[UIStackView alloc]
            initWithArrangedSubviews:@[currentRow.firstObject, spacer]];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.spacing = 12;
        row.distribution = UIStackViewDistributionFillEqually;
        [_rootStack addArrangedSubview:row];
    }
    _featureButtons = buttons;
    _featureRows = cards;
}

- (void)buildControlContent {
    NSDictionary *game = FFGameDefinition(_selectedGameIdentifier);
    [self addConsoleHeader:@"CONTROL CENTER"
        subtitle:
#ifdef FM_OFFLINE_BUILD
            @"Local engine • BODY + NECK • direct device workflow."
#else
            @"Authorize, apply, verify, then run the selected game."
#endif
        toStack:_rootStack];
    [self addLogoutChangeKeyButtonToStack:_rootStack];

    UIStackView *gameInfo = [UIStackView new];
    gameInfo.axis = UILayoutConstraintAxisVertical;
    gameInfo.spacing = 5;
    [gameInfo addArrangedSubview:[self labelWithText:game[@"displayName"] ?: @"NO GAME SELECTED"
        font:[UIFont systemFontOfSize:19 weight:UIFontWeightHeavy] color:FFPrimaryText()]];
    [gameInfo addArrangedSubview:[self labelWithText:game[@"bundleIdentifier"] ?: @"—"
        font:[UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightSemibold]
        color:FFStatusCyan()]];
    [_rootStack addArrangedSubview:[self cardWithContent:gameInfo]];

    UIStackView *statusRow = [UIStackView new];
    statusRow.axis = UILayoutConstraintAxisHorizontal;
    statusRow.spacing = 7;
    statusRow.distribution = UIStackViewDistributionFillEqually;
#ifdef FM_OFFLINE_BUILD
    [statusRow addArrangedSubview:[self statusBadgeWithText:@"OFFLINE ● ACTIVE"
        active:YES tint:UIColor.systemGreenColor]];
    [statusRow addArrangedSubview:[self statusBadgeWithText:
        _accessMethod == FFAccessMethodDirect ? @"3105 MCM ● READY" : @"3105 MCM ○"
        active:_accessMethod == FFAccessMethodDirect tint:FFStatusCyan()]];
    [statusRow addArrangedSubview:[self statusBadgeWithText:
        [NSString stringWithFormat:@"FILES ● %lu", (unsigned long)FFBundledOfflineFeatures().count]
        active:FFBundledOfflineFeatures().count > 0 tint:UIColor.systemGreenColor]];
#else
    [statusRow addArrangedSubview:[self statusBadgeWithText:
        _licensed ? @"LICENSE ● ACTIVE" : @"LICENSE ○"
        active:_licensed tint:UIColor.systemGreenColor]];
    BOOL verified = [_deviceSnapshot[@"status"] isEqualToString:@"ACTIVE"];
    [statusRow addArrangedSubview:[self statusBadgeWithText:
        verified ? @"DEVICE ● VERIFIED" : @"DEVICE ○"
        active:verified tint:FFStatusCyan()]];
    BOOL live = [_serverSnapshot[@"success"] boolValue];
    [statusRow addArrangedSubview:[self statusBadgeWithText:
        live ? @"SERVER ● LIVE" : @"SERVER ○"
        active:live tint:UIColor.systemGreenColor]];
#endif
    [_rootStack addArrangedSubview:statusRow];

    [_rootStack addArrangedSubview:[self labelWithText:@"FEATURES"
        font:[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightBold]
        color:FFSecondaryText()]];
    [self buildFeatureGrid];

    _applyButton = [self actionButton:
        _selectedFeature.length ? [NSString stringWithFormat:@"APPLY %@",
            FFFeatureDisplayName(_selectedFeature)] : @"SELECT A FEATURE"
        color:FFVIPGold() selector:@selector(applySelectedFeature)];
    BOOL canApply = !_busy && _licensed && _selectedFeature.length &&
        [_allowedFeatures containsObject:_selectedFeature] &&
        [_serverAvailableFeatures containsObject:_selectedFeature];
    _applyButton.enabled = canApply;
    _applyButton.alpha = canApply ? 1.0 : 0.42;
    [_rootStack addArrangedSubview:_applyButton];

    UIStackView *result = [UIStackView new];
    result.axis = UILayoutConstraintAxisVertical;
    result.spacing = 6;
    _statusLabel = [self labelWithText:_statusText ?: @"SELECT A FEATURE"
        font:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
        color:_statusIsError ? UIColor.systemRedColor : UIColor.labelColor];
    _activeLabel = [self labelWithText:[NSString stringWithFormat:@"ACTIVE: %@", _activeText ?: @"—"]
        font:[UIFont systemFontOfSize:12 weight:UIFontWeightBold] color:FFStatusCyan()];
    [result addArrangedSubview:_statusLabel];
    [result addArrangedSubview:_activeLabel];
    [_rootStack addArrangedSubview:[self cardWithContent:result]];

#ifndef FM_OFFLINE_BUILD
    NSOperatingSystemVersion folderVersion = NSProcessInfo.processInfo.operatingSystemVersion;
    BOOL folderAuthorizationAvailable = !(folderVersion.majorVersion == 18 && folderVersion.minorVersion >= 5);
    if (_accessMethod != FFAccessMethodDirect && folderAuthorizationAvailable) {
        NSString *folderTitle = _accessMethod == FFAccessMethodAuthorizedFolder
            ? @"CHANGE AUTHORIZED GAME FOLDER" : @"SELECT AUTHORIZED GAME FOLDER";
        _compatibilityFolderButton = [self actionButton:folderTitle
            color:UIColor.systemBlueColor selector:@selector(selectFolder)];
        [_rootStack addArrangedSubview:_compatibilityFolderButton];
    }
#endif

    if (_readyToRun) {
        _runButton = [self actionButton:
            [_selectedGameIdentifier isEqualToString:FFBundleIDFreeFireMAX]
                ? @"RUN FREE FIRE MAX" : @"RUN FREE FIRE"
            color:UIColor.systemGreenColor selector:@selector(runSelectedGame)];
        [_rootStack addArrangedSubview:_runButton];
    }
    _restoreButton = [self actionButton:@"RESTORE ORIGINAL"
        color:UIColor.systemRedColor selector:@selector(restoreOriginal)];
    [_rootStack addArrangedSubview:_restoreButton];
}

- (NSString *)formattedEpoch:(id)value {
    if (![value respondsToSelector:@selector(doubleValue)] || [value doubleValue] <= 0) return @"—";
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[value doubleValue]]];
}

- (UIView *)statusSection:(NSString *)title rows:(NSArray<UIView *> *)rows {
    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    [stack addArrangedSubview:[self labelWithText:title
        font:[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightBold] color:FFVIPGold()]];
    for (UIView *row in rows) [stack addArrangedSubview:row];
    return [self cardWithContent:stack];
}

- (void)buildStatusContent {
    [self addConsoleHeader:@"SYSTEM STATUS"
        subtitle:@"Only server and secure-session values are shown." toStack:_rootStack];
    [self addLogoutChangeKeyButtonToStack:_rootStack];
    NSString *used = [_licenseSnapshot[@"devices_used"] stringValue] ?: @"—";
    NSString *maximum = [_licenseSnapshot[@"max_devices"] stringValue] ?: @"—";
    [_rootStack addArrangedSubview:[self statusSection:@"LICENSE" rows:@[
        [self informationRow:@"STATUS" value:_licenseSnapshot[@"status"] ?: (_licensed ? @"ACTIVE" : @"INACTIVE")],
        [self informationRow:@"PLAN" value:_licenseSnapshot[@"plan"] ?: @"—"],
        [self informationRow:@"EXPIRES" value:[self formattedEpoch:_licenseSnapshot[@"expires_at"]]],
        [self informationRow:@"DEVICE LIMIT" value:[NSString stringWithFormat:@"%@ / %@", used, maximum]],
    ]]];
    NSString *slot = [_deviceSnapshot[@"slot"] stringValue] ?: @"—";
    [_rootStack addArrangedSubview:[self statusSection:@"DEVICE" rows:@[
        [self informationRow:@"REGISTERED" value:
            [_deviceSnapshot[@"status"] isEqualToString:@"ACTIVE"] ? @"YES" : @"NO"],
        [self informationRow:@"DEVICE SLOT" value:slot],
        [self informationRow:@"INSTALLATION STATUS" value:_gameInstalled ? @"GAME FOUND" : @"NOT VERIFIED"],
    ]]];
    NSDateFormatter *validationFormatter = [NSDateFormatter new];
    validationFormatter.dateStyle = NSDateFormatterMediumStyle;
    validationFormatter.timeStyle = NSDateFormatterMediumStyle;
    [_rootStack addArrangedSubview:[self statusSection:@"SESSION" rows:@[
        [self informationRow:@"STATUS" value:_licensed ? @"ACTIVE" : @"EXPIRED"],
        [self informationRow:@"LAST VALIDATION" value:
            _lastValidationDate ? [validationFormatter stringFromDate:_lastValidationDate] : @"—"],
    ]]];
    NSOperatingSystemVersion os = NSProcessInfo.processInfo.operatingSystemVersion;
    NSString *osVersion = [NSString stringWithFormat:@"%ld.%ld.%ld", (long)os.majorVersion,
        (long)os.minorVersion, (long)os.patchVersion];
    [_rootStack addArrangedSubview:[self statusSection:@"ACCESS COMPATIBILITY" rows:@[
        [self informationRow:@"iOS" value:osVersion],
        [self informationRow:@"ROUTING" value:@"CAPABILITY-BASED"],
        [self informationRow:@"ACCESS METHOD" value:FFAccessMethodName(_accessMethod)],
        [self informationRow:@"FILESYSTEM" value:_gameInstalled ? @"VERIFIED / READY" : @"NOT VERIFIED"],
    ]]];
    BOOL live = [_serverSnapshot[@"success"] boolValue];
    BOOL maintenance = [_serverSnapshot[@"maintenance"] boolValue];
    [_rootStack addArrangedSubview:[self statusSection:@"SERVER" rows:@[
        [self informationRow:@"STATUS" value:live ? @"ONLINE" : @"UNAVAILABLE"],
        [self informationRow:@"APP VERSION STATUS" value:_licensed ? @"ACCEPTED" : @"NOT VALIDATED"],
        [self informationRow:@"MAINTENANCE STATUS" value:maintenance ? @"ACTIVE" : @"NORMAL"],
    ]]];
}

- (void)rebuildInterface {
    NSString *pendingLicense = _licenseField.text;
    [_rootScroll removeFromSuperview];
    [_tabControl removeFromSuperview];
    _rootScroll = nil;
    _rootStack = nil;
    _tabControl = nil;
    _licenseField = nil;
    _licenseButton = nil;
    _folderButton = nil;
    _compatibilityFolderButton = nil;
    _continueButton = nil;
    _applyButton = nil;
    _runButton = nil;
    _logoutButton = nil;
    _restoreButton = nil;
    _featureButtons = @[];
    _featureRows = @[];
    _statusLabel = nil;
    _activeLabel = nil;

    _rootScroll = [UIScrollView new];
    _rootScroll.translatesAutoresizingMaskIntoConstraints = NO;
    _rootScroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:_rootScroll];

    NSLayoutYAxisAnchor *bottomAnchor = self.view.bottomAnchor;
    if (_screen == FFAppScreenMain) {
        _tabControl = [[UISegmentedControl alloc] initWithItems:@[@"GAME", @"CONTROL", @"STATUS"]];
        _tabControl.selectedSegmentIndex = _selectedTab;
        _tabControl.selectedSegmentTintColor = FFVIPGold();
        _tabControl.backgroundColor = [FFVIPPanel() colorWithAlphaComponent:0.96];
        _tabControl.layer.cornerRadius = 18;
        _tabControl.layer.cornerCurve = kCACornerCurveContinuous;
        _tabControl.layer.borderWidth = 1;
        _tabControl.layer.borderColor = [FFLilac() colorWithAlphaComponent:0.72].CGColor;
        [_tabControl setTitleTextAttributes:@{
            NSForegroundColorAttributeName: FFPrimaryText(),
            NSFontAttributeName: [UIFont systemFontOfSize:12 weight:UIFontWeightBold]
        } forState:UIControlStateNormal];
        _tabControl.translatesAutoresizingMaskIntoConstraints = NO;
        [_tabControl addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:_tabControl];
        [NSLayoutConstraint activateConstraints:@[
            [_tabControl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
            [_tabControl.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
            [_tabControl.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8],
            [_tabControl.heightAnchor constraintEqualToConstant:42],
        ]];
        bottomAnchor = _tabControl.topAnchor;
    }
    [NSLayoutConstraint activateConstraints:@[
        [_rootScroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_rootScroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_rootScroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_rootScroll.bottomAnchor constraintEqualToAnchor:bottomAnchor
            constant:_screen == FFAppScreenMain ? -10 : 0],
    ]];

    _rootStack = [UIStackView new];
    _rootStack.axis = UILayoutConstraintAxisVertical;
    _rootStack.spacing = 14;
    _rootStack.translatesAutoresizingMaskIntoConstraints = NO;
    [_rootScroll addSubview:_rootStack];
    [NSLayoutConstraint activateConstraints:@[
        [_rootStack.leadingAnchor constraintEqualToAnchor:_rootScroll.frameLayoutGuide.leadingAnchor constant:16],
        [_rootStack.trailingAnchor constraintEqualToAnchor:_rootScroll.frameLayoutGuide.trailingAnchor constant:-16],
        [_rootStack.topAnchor constraintEqualToAnchor:_rootScroll.contentLayoutGuide.topAnchor constant:18],
        [_rootStack.bottomAnchor constraintEqualToAnchor:_rootScroll.contentLayoutGuide.bottomAnchor constant:-28],
        [_rootStack.widthAnchor constraintEqualToAnchor:_rootScroll.frameLayoutGuide.widthAnchor constant:-32],
    ]];

    if (_screen == FFAppScreenAccess) {
        [self buildAccessContent];
        _licenseField.text = pendingLicense ?: @"";
    } else if (_screen == FFAppScreenGameSelection) {
        [self buildGameSelectionContent:NO];
    } else if (_selectedTab == FFMainTabGame) {
        [self buildGameSelectionContent:YES];
    } else if (_selectedTab == FFMainTabStatus) {
        [self buildStatusContent];
    } else {
        [self buildControlContent];
    }

    UIStackView *brandStack = [UIStackView new];
    brandStack.axis = UILayoutConstraintAxisVertical;
    brandStack.spacing = 6;
    UILabel *owner = [self labelWithText:[NSString stringWithFormat:@"OFFICIAL OWNER  •  %@", FFOwnerTelegram]
        font:[UIFont systemFontOfSize:12 weight:UIFontWeightHeavy] color:FFVIPGold()];
    owner.textAlignment = NSTextAlignmentCenter;
    [brandStack addArrangedSubview:owner];
    UIButton *channel = [UIButton buttonWithType:UIButtonTypeSystem];
    [channel setTitle:@"OFFICIAL TELEGRAM CHANNEL" forState:UIControlStateNormal];
    [channel setTitleColor:FFStatusCyan() forState:UIControlStateNormal];
    channel.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    channel.accessibilityValue = FFOfficialChannelURL;
    [channel addTarget:self action:@selector(openOfficialChannel:) forControlEvents:UIControlEventTouchUpInside];
    [brandStack addArrangedSubview:channel];
    [_rootStack addArrangedSubview:[self cardWithContent:brandStack]];

    [self setBusy:_busy];
}

- (void)openOfficialChannel:(UIButton *)sender {
    (void)sender;
    if (!FFBrandIdentityIsValid()) return;
    NSURL *url = [NSURL URLWithString:FFOfficialChannelURL];
    if (url) [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}

- (void)selectGameCard:(UIButton *)sender {
    if (_busy || !_licensed || sender.tag < 0 ||
        sender.tag >= (NSInteger)FFSupportedGames().count) return;
    NSString *newGame = FFSupportedGames()[(NSUInteger)sender.tag][@"bundleIdentifier"];
    if (!FFGameDefinition(newGame)) return;
    if (![_selectedGameIdentifier isEqualToString:newGame]) {
        _selectedGameIdentifier = newGame;
        _connectedGameIdentifier = nil;
        _selectedFeature = nil;
        _operationFeature = nil;
        _serverAvailableFeatures = [NSSet set];
        _accessContext = nil;
        _accessMethod = FFAccessMethodNone;
        _gameInstalled = NO;
        _readyToRun = NO;
        _activeText = @"—";
        _statusText = @"GAME SELECTED — CONTINUE TO VERIFY";
        _statusIsError = NO;
    }
    [self rebuildInterface];
}

- (void)continueWithSelectedGame {
    if (_busy || !_licensed || !FFGameDefinition(_selectedGameIdentifier)) return;
    _screen = FFAppScreenMain;
    _selectedTab = FFMainTabControl;
    _statusText = @"LOADING FEATURE AVAILABILITY…";
    _statusIsError = NO;
    [self rebuildInterface];
    [self loadFeatureCatalogForSelectedGame];
}

- (void)tabChanged:(UISegmentedControl *)control {
    if (_busy) {
        control.selectedSegmentIndex = _selectedTab;
        return;
    }
    _selectedTab = (FFMainTab)control.selectedSegmentIndex;
    [self rebuildInterface];
}

- (void)fetchServerStatus {
#ifdef FM_OFFLINE_BUILD
    _serverSnapshot = nil;
    return;
#endif
    FFFetchServiceStatus(^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_serverSnapshot = error ? nil : response;
            self->_serverStatusError = error.localizedDescription;
            if (error && self->_screen == FFAppScreenAccess && !self->_busy) {
                [self setStatus:[NSString stringWithFormat:@"SERVER CONNECTION FAILED — %@",
                    error.localizedDescription ?: @"TRY AGAIN"] path:nil active:nil error:YES];
            } else if (!error && self->_screen == FFAppScreenAccess &&
                       !self->_busy && !self->_licensed) {
                [self setStatus:@"SERVER READY — ENTER LICENSE TO ACTIVATE"
                    path:nil active:@"—" error:NO];
            }
            if (self->_screen != FFAppScreenMain || self->_selectedTab == FFMainTabStatus) {
                [self rebuildInterface];
            }
        });
    });
}

- (void)loadFeatureCatalogForSelectedGame {
    NSString *game = _selectedGameIdentifier;
#ifdef FM_OFFLINE_BUILD
    if (!FFGameDefinition(game)) return;
    NSMutableSet<NSString *> *available = [FFBundledOfflineFeatures() mutableCopy];
    [available intersectSet:FFLocalFeaturesForGame(game)];
    _allowedFeatures = available.copy;
    _serverAvailableFeatures = available.copy;
    [self setBusy:NO];
    [self rebuildInterface];
    [self inspectDirectAccess];
    return;
#endif
    NSString *token = _activationToken;
    if (!FFGameDefinition(game) || !token.length) return;
    [self setBusy:YES];
    FFFetchFeatureCatalog(game, token, ^(NSSet<NSString *> *planFeatures,
                                         NSSet<NSString *> *serverFeatures, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self->_selectedGameIdentifier isEqualToString:game]) return;
            if (error) {
                self->_allowedFeatures = [NSSet set];
                self->_serverAvailableFeatures = [NSSet set];
                [self setBusy:NO];
                [self setStatus:error.localizedDescription path:nil active:nil error:YES];
                [self rebuildInterface];
                return;
            }
            self->_allowedFeatures = planFeatures ?: [NSSet set];
            self->_serverAvailableFeatures = serverFeatures ?: [NSSet set];
            [self setBusy:NO];
            [self rebuildInterface];
            [self inspectDirectAccess];
        });
    });
}

- (void)setBusy:(BOOL)busy {
    _busy = busy;
    _licenseField.enabled = !busy;
    _licenseButton.enabled = !busy;
    _continueButton.enabled = !busy && _selectedGameIdentifier.length > 0;
    _continueButton.alpha = _continueButton.enabled ? 1.0 : 0.42;
    _tabControl.enabled = !busy;
    _logoutButton.enabled = !busy && _licensed;
    _logoutButton.alpha = _logoutButton.enabled ? 1.0 : 0.42;
    _restoreButton.enabled = !busy && _licensed && _selectedGameIdentifier.length > 0;
    _restoreButton.alpha = _restoreButton.enabled ? 1.0 : 0.42;
    _compatibilityFolderButton.enabled = !busy && _licensed && _selectedGameIdentifier.length > 0;
    _compatibilityFolderButton.alpha = _compatibilityFolderButton.enabled ? 1.0 : 0.42;
    _runButton.enabled = !busy && _readyToRun && _gameInstalled;
    for (UIButton *button in _featureButtons) {
        NSInteger index = button.tag;
        NSString *feature = index >= 0 && index < (NSInteger)_features.count
            ? _features[(NSUInteger)index] : nil;
        BOOL allowed = feature && [_allowedFeatures containsObject:feature] &&
            [_serverAvailableFeatures containsObject:feature] &&
            [FFLocalFeaturesForGame(_selectedGameIdentifier) containsObject:feature];
        button.enabled = !busy && _licensed && allowed;
        button.alpha = button.enabled ? 1.0 : 0.56;
    }
    BOOL canApply = !busy && _licensed && _selectedFeature.length &&
        [_allowedFeatures containsObject:_selectedFeature] &&
        [_serverAvailableFeatures containsObject:_selectedFeature];
    _applyButton.enabled = canApply;
    _applyButton.alpha = canApply ? 1.0 : 0.42;
    self.navigationItem.hidesBackButton = busy;
}

- (void)updateGameRouting:(NSString *)gameIdentifier {
    if (gameIdentifier.length && ![gameIdentifier isEqualToString:_selectedGameIdentifier]) {
        _connectedGameIdentifier = nil;
        _gameInstalled = NO;
        [self setStatus:@"GAME ROUTING MISMATCH" path:nil active:nil error:YES];
        return;
    }
    BOOL verified = gameIdentifier.length > 0 && _accessContext.usable &&
        [_accessContext.gameIdentifier isEqualToString:gameIdentifier];
    _connectedGameIdentifier = verified ? gameIdentifier : nil;
    _gameInstalled = verified;
    FFDiagnosticLog(@"Compatibility", @"CONNECTED: %@", verified ? @"YES" : @"NO");
    [self setBusy:_busy];
}

- (void)setStatus:(NSString *)status path:(NSString *)path active:(NSString *)active error:(BOOL)isError {
    (void)path;
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_statusText = status ?: @"";
        self->_statusIsError = isError;
        self->_statusLabel.text = self->_statusText;
        self->_statusLabel.textColor = isError ? UIColor.systemRedColor : UIColor.labelColor;
        if (active) {
            self->_activeText = active;
            self->_activeLabel.text = [NSString stringWithFormat:@"ACTIVE: %@", active];
        }
    });
}

- (void)activateLicensePressed {
    if (_busy) return;
    [self activateLicenseValue:_licenseField.text ?: @""];
}

- (void)licenseFieldChanged:(UITextField *)field {
    if (_busy || _licensed) return;
    NSString *licenseKey = FFLicenseKeyFromText(field.text ?: @"");
    if (!licenseKey.length) return;
    // This covers a normal paste into the existing field as well as the
    // clipboard observer.  Do not make the user press Activate twice.
    field.text = licenseKey;
    _clipboardActivationAttempted = YES;
    [self activateLicenseValue:licenseKey];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    (void)notification;
    [self restoreExpiredHologramIfNeeded];
    if (_screen != FFAppScreenAccess || _busy || _licensed) return;
    _clipboardActivationAttempted = NO;
    [self activateClipboardLicenseIfAvailable];
}

- (void)clipboardChanged:(NSNotification *)notification {
    (void)notification;
    NSInteger changeCount = UIPasteboard.generalPasteboard.changeCount;
    if (changeCount == _lastClipboardChangeCount) return;
    _lastClipboardChangeCount = changeCount;
    if (_screen != FFAppScreenAccess || _busy || _licensed) return;
    // A newly copied key is an intentional retry.  The existing digest guard
    // still prevents logout from immediately reusing the old clipboard key.
    _clipboardActivationAttempted = NO;
    [self activateClipboardLicenseIfAvailable];
}

- (void)restoreExpiredHologramIfNeeded {
    if (_hologramRestoreInProgress) return;
    NSDictionary *state = [NSUserDefaults.standardUserDefaults dictionaryForKey:FFHologramStateKey];
    NSNumber *expires = [state[@"expires_at"] isKindOfClass:NSNumber.class] ? state[@"expires_at"] : nil;
    if (!expires || expires.doubleValue > NSDate.date.timeIntervalSince1970) return;
    _hologramRestoreInProgress = YES;
    [self setStatus:@"HOLOGRAM_EXPIRED — RESTORING ORIGINAL…" path:nil active:nil error:NO];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSError *error = nil;
        NSString *game = nil;
        NSString *path = nil;
        BOOL needed = NO;
        BOOL restored = FFRestoreExpiredHologram(&needed, &game, &path, &error);
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_hologramRestoreInProgress = NO;
            if (!needed) return;
            if (!restored) {
                [self setStatus:error.localizedDescription ?: @"RESTORE_FAILED: expired Hologram state retained."
                    path:path active:nil error:YES];
                return;
            }
            if ([self->_selectedGameIdentifier isEqualToString:game]) self->_readyToRun = NO;
            [self setStatus:@"RESTORE_SUCCESS — EXPIRED HOLOGRAM RESTORED"
                path:path active:@"ORIGINAL" error:NO];
            [self rebuildInterface];
        });
    });
}

- (void)activateClipboardLicenseIfAvailable {
    if (_clipboardActivationAttempted || _busy || _licensed ||
        _screen != FFAppScreenAccess) return;
    // Existing session tokens have priority.  restoreSessionIfAvailable will
    // rebuild the Access screen after a failed refresh, at which point this
    // clipboard flow can safely run without racing a valid saved session.
    if (FFKeychainRead(FFAccessTokenAccount).length ||
        FFKeychainRead(FFRefreshTokenAccount).length) return;
    NSString *licenseKey = FFClipboardLicenseKey();
    if (!licenseKey.length) return;
    NSString *digest = ZXDigest([licenseKey dataUsingEncoding:NSUTF8StringEncoding]);
    NSString *blockedDigest = [NSUserDefaults.standardUserDefaults
        stringForKey:FFAutoClipboardLicenseDigestKey];
    // Logout must not immediately sign the user back in with the old key that
    // is still on the system clipboard. Copying a different key changes this
    // digest and enables the automatic flow again.
    if (digest.length && [digest isEqualToString:blockedDigest]) return;
    _clipboardActivationAttempted = YES;
    _licenseField.text = licenseKey;
    [self setStatus:@"LICENSE KEY DETECTED — ACTIVATING…" path:nil active:@"—" error:NO];
    [self activateLicenseValue:licenseKey];
}

- (void)logoutChangeKeyPressed {
    if (_busy) return;
    NSString *oldAccessToken = [_activationToken copy] ?: FFKeychainRead(FFAccessTokenAccount);
    NSString *clipboardLicense = FFClipboardLicenseKey();
    if (clipboardLicense.length) {
        NSString *digest = ZXDigest([clipboardLicense dataUsingEncoding:NSUTF8StringEncoding]);
        if (digest.length) [NSUserDefaults.standardUserDefaults setObject:digest
            forKey:FFAutoClipboardLicenseDigestKey];
    } else {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:FFAutoClipboardLicenseDigestKey];
    }
    ++_sessionGeneration;
    FFClearSession();
    _licensed = NO;
    _activationToken = nil;
    _licenseSnapshot = nil;
    _deviceSnapshot = nil;
    _sessionSnapshot = nil;
    _allowedFeatures = [NSSet set];
    _serverAvailableFeatures = [NSSet set];
    _accessContext = nil;
    _accessMethod = FFAccessMethodNone;
    _pendingAccessCompletion = nil;
    _connectedGameIdentifier = nil;
    _selectedGameIdentifier = nil;
    _selectedFeature = nil;
    _operationFeature = nil;
    _activeText = @"—";
    _statusText = @"LICENSE CLEARED — ENTER A NEW KEY";
    _statusIsError = NO;
    _gameInstalled = NO;
    _readyToRun = NO;
    _usingSelectedFolder = NO;
    _folderPickerPresented = NO;
    _clipboardActivationAttempted = NO;
    _screen = FFAppScreenAccess;
    _selectedTab = FFMainTabControl;
    [self rebuildInterface];
    _licenseField.text = @"";
    _licenseField.enabled = YES;
    [_licenseField becomeFirstResponder];
    FFLogoutSession(oldAccessToken, ^(NSError *error) {
        (void)error; // Local logout is immediate; server revocation is best effort when offline.
    });
}

- (void)activateLicenseValue:(NSString *)licenseKey {
    if (_busy) return;
    NSString *trimmed = FFLicenseKeyFromText(licenseKey);
    if (!trimmed.length) {
        [self setStatus:@"COPY OR ENTER A VALID LICENSE KEY" path:nil active:@"—" error:YES];
        return;
    }
    NSUInteger generation = ++_sessionGeneration;
    [self setBusy:YES];
    [self setStatus:@"ACTIVATING LICENSE…" path:nil active:nil error:NO];
    FFActivateLicense(trimmed, ^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (generation != self->_sessionGeneration) return;
            if (error) {
                self->_licensed = NO;
                self->_activationToken = nil;
                self->_allowedFeatures = [NSSet set];
                self->_serverAvailableFeatures = [NSSet set];
                FFClearSession();
                [self setBusy:NO];
                [self setStatus:error.localizedDescription path:nil active:@"—" error:YES];
                return;
            }
            NSDictionary *session = [response[@"session"] isKindOfClass:NSDictionary.class] ? response[@"session"] : nil;
            if (!session || !ZXPersist(session)) {
                self->_licensed = NO;
                self->_activationToken = nil;
                [self setBusy:NO];
                [self setStatus:@"Could not store the secure session." path:nil active:@"—" error:YES];
                return;
            }
            self->_licenseField.text = @"";
            [NSUserDefaults.standardUserDefaults removeObjectForKey:FFAutoClipboardLicenseDigestKey];
            [self applySessionResponse:response accessToken:session[@"access_token"]];
            self->_serverAvailableFeatures = [NSSet set];
            self->_selectedGameIdentifier = nil;
            self->_selectedFeature = nil;
            self->_readyToRun = NO;
            self->_screen = FFAppScreenGameSelection;
            [self setBusy:NO];
            [self setStatus:@"LICENSE ACTIVE ✓" path:nil active:@"—" error:NO];
            [self rebuildInterface];
        });
    });
}

- (void)applySessionResponse:(NSDictionary *)response accessToken:(NSString *)accessToken {
    NSDictionary *session = [response[@"session"] isKindOfClass:NSDictionary.class] ? response[@"session"] : nil;
    if ([session[@"access_token"] isKindOfClass:NSString.class]) {
        if (!ZXPersist(session)) {
            FFClearSession();
            _licensed = NO;
            _activationToken = nil;
            return;
        }
        accessToken = session[@"access_token"];
    }
    NSDictionary *license = [response[@"license"] isKindOfClass:NSDictionary.class]
        ? response[@"license"] : nil;
    NSDictionary *device = [response[@"device"] isKindOfClass:NSDictionary.class]
        ? response[@"device"] : nil;
    if (license) _licenseSnapshot = license;
    if (device) _deviceSnapshot = device;
    if (session) _sessionSnapshot = session;
    NSDictionary *features = [response[@"features"] isKindOfClass:NSDictionary.class] ? response[@"features"] : nil;
    if (features) {
        NSMutableSet *allowed = [NSMutableSet set];
        for (NSString *feature in _features) {
            NSString *wireFeature = ZXWireFeature(feature);
            if ([features[wireFeature] boolValue] || [features[feature] boolValue]) [allowed addObject:feature];
        }
        _allowedFeatures = allowed;
    }
    _activationToken = accessToken;
    _licensed = accessToken.length > 0;
    if (_licensed) _lastValidationDate = [NSDate date];
    [self setBusy:_busy];
}

- (void)restoreSessionIfAvailable {
    NSString *accessToken = FFKeychainRead(FFAccessTokenAccount);
    NSString *refreshToken = FFKeychainRead(FFRefreshTokenAccount);
    if (!accessToken.length || !refreshToken.length) return;
    NSUInteger generation = ++_sessionGeneration;
    [self setStatus:@"CHECKING SAVED SESSION…" path:nil active:nil error:NO];
    FFValidateSession(accessToken, ^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (generation != self->_sessionGeneration) return;
            if (!error) {
                [self applySessionResponse:response accessToken:accessToken];
                self->_screen = FFAppScreenGameSelection;
                self->_selectedGameIdentifier = nil;
                self->_serverAvailableFeatures = [NSSet set];
                [self setBusy:NO];
                [self setStatus:@"LICENSE ACTIVE ✓" path:nil active:@"—" error:NO];
                [self rebuildInterface];
                return;
            }
            ZXRenew(^(NSDictionary *refreshResponse, NSError *refreshError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (generation != self->_sessionGeneration) return;
                    if (refreshError) {
                        FFClearSession();
                        self->_licensed = NO;
                        self->_activationToken = nil;
                        self->_allowedFeatures = [NSSet set];
                        self->_serverAvailableFeatures = [NSSet set];
                        self->_screen = FFAppScreenAccess;
                        [self setBusy:NO];
                        [self setStatus:@"LICENSE REQUIRED" path:nil active:@"—" error:NO];
                        [self rebuildInterface];
                        return;
                    }
                    [self applySessionResponse:refreshResponse accessToken:nil];
                    self->_screen = FFAppScreenGameSelection;
                    self->_selectedGameIdentifier = nil;
                    self->_serverAvailableFeatures = [NSSet set];
                    [self setBusy:NO];
                    [self setStatus:@"LICENSE ACTIVE ✓" path:nil active:@"—" error:NO];
                    [self rebuildInterface];
                });
            });
        });
    });
}

- (void)refreshSessionForOperation:(void (^)(NSString *accessToken, NSError *error))completion {
#ifdef FM_OFFLINE_BUILD
    _activationToken = @"OFFLINE";
    _licensed = YES;
    completion(_activationToken, nil);
    return;
#endif
    ZXRenew(^(NSDictionary *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                FFClearSession();
                self->_licensed = NO;
                self->_activationToken = nil;
                self->_allowedFeatures = [NSSet set];
                self->_serverAvailableFeatures = [NSSet set];
                completion(nil, error);
                return;
            }
            [self applySessionResponse:response accessToken:nil];
            completion(self->_activationToken, nil);
        });
    });
}

- (void)selectFolder {
    if (_folderPickerPresented || _busy || !FFGameDefinition(_selectedGameIdentifier)) return;
    NSOperatingSystemVersion version = NSProcessInfo.processInfo.operatingSystemVersion;
    if (version.majorVersion == 18 && version.minorVersion >= 5) {
        [self setStatus:@"AUTHORIZED_CONTAINER_ACCESS_UNAVAILABLE: iOS 18.5+ does not expose the game's private folder in Files. Direct access must be legitimately granted and verified."
            path:@"" active:@"—" error:YES];
        return;
    }
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[UTTypeFolder] asCopy:NO];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    _folderPickerPresented = YES;
    FFDiagnosticLog(@"Compatibility", @"Presenting AuthorizedFolderAccess picker");
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    (void)controller;
    _folderPickerPresented = NO;
    NSURL *url = urls.firstObject;
    if (!url) {
        void (^pending)(BOOL) = _pendingAccessCompletion;
        _pendingAccessCompletion = nil;
        if (pending) pending(NO);
        return;
    }
    BOOL accessed = [url startAccessingSecurityScopedResource];
    FFDiagnosticLog(@"AuthorizedFolderAccess", @"Security-scoped resource: %@", accessed ? @"STARTED" : @"FAILED");
    if (!accessed) {
        NSError *accessError = FFError(66, @"The selected folder did not grant security-scoped access.");
        [self setStatus:accessError.localizedDescription path:@"" active:@"—" error:YES];
        void (^pending)(BOOL) = _pendingAccessCompletion;
        _pendingAccessCompletion = nil;
        if (pending) pending(NO);
        return;
    }
    NSString *selectedGame = [_selectedGameIdentifier copy];
    [self setBusy:YES];
    [self setStatus:@"VERIFYING AUTHORIZED GAME FOLDER…" path:@"" active:@"—" error:NO];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        FFAccessContext *context = [FFCompatibilityRouter verifyAuthorizedURL:url
                                                                     forGame:selectedGame
                                                               requiresWrite:YES];
        NSError *bookmarkError = nil;
        if (context.usable && ![FFAccessManager storeBookmarkForAuthorizedURL:url error:&bookmarkError]) {
            context.usable = NO;
            context.error = bookmarkError ?: FFError(65, @"Could not save folder authorization.");
        }
        [url stopAccessingSecurityScopedResource];
        FFDiagnosticLog(@"AuthorizedFolderAccess", @"Security-scoped resource: STOPPED");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![self->_selectedGameIdentifier isEqualToString:selectedGame]) return;
            void (^pending)(BOOL) = self->_pendingAccessCompletion;
            self->_pendingAccessCompletion = nil;
            [self finishAccessAttemptWithContext:context completion:pending];
        });
    });
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    (void)controller;
    _folderPickerPresented = NO;
    [self setBusy:NO];
    [self setStatus:@"FOLDER AUTHORIZATION CANCELLED — NO FILE WAS CHANGED"
        path:@"" active:@"—" error:YES];
    void (^pending)(BOOL) = _pendingAccessCompletion;
    _pendingAccessCompletion = nil;
    if (pending) pending(NO);
}

- (NSURL *)resolvedRoot:(BOOL *)stale error:(NSError **)error {
    NSData *bookmark = [NSUserDefaults.standardUserDefaults dataForKey:FFBookmarkKey];
    if (!bookmark) {
        if (error) *error = FFError(20, @"Select the Free Fire folder first.");
        return nil;
    }
    return [NSURL URLByResolvingBookmarkData:bookmark
                                     options:0
                               relativeToURL:nil bookmarkDataIsStale:stale error:error];
}

- (void)withSelectedRoot:(void (^)(NSURL *root, NSError **operationError))operation completion:(void (^)(NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSError *error = nil;
        BOOL stale = NO;
        NSURL *root = [FFAccessManager beginBookmarkedFolderAccessWithStale:&stale error:&error];
        if (!root) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(error); });
            return;
        }
        operation(root, &error);
        [FFAccessManager endBookmarkedFolderAccess:root];
        dispatch_async(dispatch_get_main_queue(), ^{ completion(error); });
    });
}

- (NSString *)activeFeatureForTarget:(NSURL *)target {
    return FFActiveFeatureAtTarget(target, _selectedGameIdentifier);
}

- (void)reconnectAutomatically {
    [self inspectDirectAccess];
}

- (void)inspectSelectedFolder {
    [self inspectDirectAccessWithCompletion:nil];
}

- (void)inspectDirectAccess {
    [self inspectDirectAccessWithCompletion:nil];
}

- (void)finishAccessAttemptWithContext:(FFAccessContext *)context
                             completion:(void (^)(BOOL ready))completion {
    [self setBusy:NO];
    if (context.usable && [context.gameIdentifier isEqualToString:_selectedGameIdentifier]) {
        _accessContext = context;
        _accessMethod = context.method;
        _usingSelectedFolder = context.method == FFAccessMethodAuthorizedFolder;
        [self updateGameRouting:context.gameIdentifier];
        NSString *gameName = FFGameDefinition(context.gameIdentifier)[@"displayName"] ?: @"FREE FIRE";
        NSString *methodName = context.method == FFAccessMethodDirect ? @"DIRECT ACCESS" : @"AUTHORIZED FOLDER";
        [self setStatus:[NSString stringWithFormat:@"%@ READY — %@", gameName, methodName]
            path:context.targetURL.path active:context.activeFeature ?: @"UNKNOWN" error:NO];
        [self rebuildInterface];
        if (completion) completion(YES);
        return;
    }

    _accessContext = nil;
    _accessMethod = FFAccessMethodNone;
    _usingSelectedFolder = NO;
    _connectedGameIdentifier = nil;
    _gameInstalled = NO;
    _readyToRun = NO;
    NSString *message = context.error.localizedDescription ?: @"No usable filesystem access method is available.";
#ifndef FM_OFFLINE_BUILD
    if (context.needsFolderSelection) {
        NSString *fallback = context.fallbackReason.length
            ? [NSString stringWithFormat:@"Direct access failed: %@\nSelect the authorized game folder.", context.fallbackReason]
            : @"Select the authorized game folder.";
        [self setStatus:fallback path:@"" active:@"—" error:YES];
        _pendingAccessCompletion = [completion copy];
        [self rebuildInterface];
        dispatch_async(dispatch_get_main_queue(), ^{ [self selectFolder]; });
        return;
    }
#endif
    [self setStatus:message path:@"" active:@"—" error:YES];
    [self rebuildInterface];
    if (completion) completion(NO);
}

- (void)inspectDirectAccessWithCompletion:(void (^)(BOOL ready))completion {
    if (_busy) {
        if (completion) completion(NO);
        return;
    }
    NSString *selectedGame = _selectedGameIdentifier;
    if (!_licensed || !_activationToken.length || !FFGameDefinition(selectedGame)) {
        [self setStatus:@"LICENSE AND GAME SELECTION REQUIRED" path:nil active:@"—" error:YES];
        if (completion) completion(NO);
        return;
    }
    [self setBusy:YES];
    [self setStatus:@"VERIFYING SESSION…" path:@"" active:@"—" error:NO];
    [self refreshSessionForOperation:^(NSString *accessToken, NSError *sessionError) {
        (void)accessToken;
        if (sessionError) {
            [self setBusy:NO];
            [self setStatus:sessionError.localizedDescription path:@"" active:@"—" error:YES];
            if (completion) completion(NO);
            return;
        }
        [self setStatus:@"CHECKING FILESYSTEM ACCESS COMPATIBILITY…" path:@"" active:@"—" error:NO];
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            FFAccessContext *context = [FFCompatibilityRouter routeGame:selectedGame requiresWrite:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self->_selectedGameIdentifier isEqualToString:selectedGame]) return;
                [self finishAccessAttemptWithContext:context completion:completion];
            });
        });
    }];
}

- (void)enableFeature:(UIButton *)sender {
    if (_busy || !_licensed || sender.tag < 0 || sender.tag >= (NSInteger)_features.count) return;
    NSString *feature = _features[(NSUInteger)sender.tag];
    if (![FFLocalFeaturesForGame(_selectedGameIdentifier) containsObject:feature] ||
        ![_allowedFeatures containsObject:feature] ||
        ![_serverAvailableFeatures containsObject:feature]) return;
    _selectedFeature = feature;
    _readyToRun = NO;
    _statusText = [NSString stringWithFormat:@"%@ SELECTED — ACCESS WILL BE VERIFIED ON APPLY",
        FFFeatureDisplayName(feature)];
    _statusIsError = NO;
    [self rebuildInterface];
}

- (void)applySelectedFeature {
    if (_busy || !_licensed || !_selectedFeature.length) return;
    NSString *feature = [_selectedFeature copy];
    if (!_gameInstalled) {
        [self setStatus:@"VERIFYING GAME BEFORE APPLY…" path:nil active:nil error:NO];
        [self inspectDirectAccessWithCompletion:^(BOOL ready) {
            if (ready && [self->_selectedFeature isEqualToString:feature]) {
                [self applySelectedFeature];
            }
        }];
        return;
    }
    if ([_selectedFeature isEqualToString:@"HOLOGRAM_GUN"]) {
        [self beginHologramColorSelection];
    } else if ([_selectedFeature isEqualToString:@"THREE_D"]) {
        [self beginThreeDColorSelection];
    } else {
        [self applyFeature:_selectedFeature color:nil expectedHash:nil durationDays:0];
    }
}

- (void)runSelectedGame {
    if (_busy || !_readyToRun || !_gameInstalled || !FFGameDefinition(_selectedGameIdentifier)) {
        [self setStatus:@"GAME NOT READY" path:nil active:nil error:YES];
        return;
    }
    NSError *error = nil;
    if (!FFLaunchGame(_selectedGameIdentifier, &error)) {
        _gameInstalled = NO;
        _readyToRun = NO;
        [self setStatus:error.localizedDescription ?: @"GAME NOT INSTALLED"
            path:nil active:nil error:YES];
        [self rebuildInterface];
        return;
    }
    [self setStatus:@"GAME LAUNCHED" path:nil active:_activeText error:NO];
}

- (void)beginHologramColorSelection {
    NSString *selectedGame = _selectedGameIdentifier;
#ifdef FM_OFFLINE_BUILD
    (void)selectedGame;
    [self setStatus:@"HOLOGRAM is disabled in offline builds." path:nil active:nil error:YES];
    return;
#endif
    if (![selectedGame isEqualToString:FFBundleIDFreeFireTH] ||
        ![_connectedGameIdentifier isEqualToString:selectedGame] ||
        _accessMethod != FFAccessMethodDirect) {
        [self setStatus:@"Hologram is available only for verified FREE FIRE TH."
            path:nil active:nil error:YES];
        return;
    }
    [self setBusy:YES];
    [self setStatus:@"VERIFYING FREE FIRE FOR HOLOGRAM…" path:nil active:nil error:NO];
    [self refreshSessionForOperation:^(NSString *accessToken, NSError *sessionError) {
        if (sessionError) {
            [self setBusy:NO];
            [self setStatus:sessionError.localizedDescription path:nil active:nil error:YES];
            return;
        }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            FFAccessContext *context = [FFGameDetector detectDirectContainerForGame:selectedGame];
            if (context.discovered) {
                [FFAccessVerifier verifyContext:context requiresWrite:YES allowBackupOnly:NO];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!context.usable) {
                    [self setBusy:NO];
                    [self setStatus:context.error.localizedDescription ?: @"Direct access verification failed."
                        path:nil active:nil error:YES];
                    return;
                }
                self->_accessContext = context;
                self->_accessMethod = FFAccessMethodDirect;
                [self updateGameRouting:context.gameIdentifier];
                if (![context.gameIdentifier isEqualToString:FFBundleIDFreeFireTH]) {
                    [self setBusy:NO];
                    [self setStatus:@"Hologram is available only for Free Fire, not Free Fire MAX." path:nil active:nil error:YES];
                    return;
                }
                [self setStatus:@"LOADING HOLOGRAM COLORS…" path:nil active:nil error:NO];
                ZXFeatureColors(@"HOLOGRAM_GUN", selectedGame, accessToken,
                    ^(NSArray<NSDictionary *> *colors, NSError *colorError) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setBusy:NO];
                        if (colorError) {
                            [self setStatus:colorError.localizedDescription path:nil active:nil error:YES];
                            return;
                        }
                        [self presentHologramColors:colors];
                    });
                });
            });
        });
    }];
}

- (void)presentHologramColors:(NSArray<NSDictionary *> *)colors {
    if (!colors.count || ![_selectedGameIdentifier isEqualToString:FFBundleIDFreeFireTH]) {
        [self setStatus:@"NO VALID HOLOGRAM COLORS AVAILABLE" path:nil active:nil error:YES];
        return;
    }
    FFHologramPickerController *picker = [[FFHologramPickerController alloc]
        initWithColors:colors title:@"HOLOGRAM" applyTitle:@"NEXT — DURATION"
        selection:^(NSDictionary *color) {
            [self chooseHologramDurationForColor:color];
        }];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)chooseHologramDurationForColor:(NSDictionary *)color {
    if (![color[@"name"] isKindOfClass:NSString.class] || ![color[@"sha256"] isKindOfClass:NSString.class]) return;
    UIAlertController *duration = [UIAlertController alertControllerWithTitle:@"HOLOGRAM DURATION"
        message:@"Original will restore automatically after expiration."
        preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSNumber *days in @[@1, @3]) {
        NSString *title = [NSString stringWithFormat:@"%@ Day%@", days, days.integerValue == 1 ? @"" : @"s"];
        [duration addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *action) {
                (void)action;
                [self applyFeature:@"HOLOGRAM_GUN" color:color[@"name"]
                    expectedHash:color[@"sha256"] durationDays:days.integerValue];
            }]];
    }
    [duration addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = duration.popoverPresentationController;
    if (popover) { popover.sourceView = self.view; popover.sourceRect = self.view.bounds; }
    [self presentViewController:duration animated:YES completion:nil];
}

- (void)beginThreeDColorSelection {
    NSString *selectedGame = _selectedGameIdentifier;
#ifdef FM_OFFLINE_BUILD
    (void)selectedGame;
    [self setStatus:@"3D is disabled in offline builds." path:nil active:nil error:YES];
    return;
#endif
    if (!FFGameDefinition(selectedGame) || ![_connectedGameIdentifier isEqualToString:selectedGame] ||
        _accessMethod != FFAccessMethodDirect) {
        [self setStatus:@"CONTAINER_FOUND_ACCESS_DENIED: 3D requires verified direct game access."
            path:nil active:nil error:YES];
        return;
    }
    [self setBusy:YES];
    [self setStatus:@"VERIFYING GAME FOR 3D…" path:nil active:nil error:NO];
    [self refreshSessionForOperation:^(NSString *accessToken, NSError *sessionError) {
        if (sessionError) {
            [self setBusy:NO];
            [self setStatus:sessionError.localizedDescription path:nil active:nil error:YES];
            return;
        }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            FFAccessContext *context = [FFGameDetector detectDirectContainerForGame:selectedGame];
            if (context.discovered) [FFAccessVerifier verifyContext:context requiresWrite:YES allowBackupOnly:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!context.usable) {
                    [self setBusy:NO];
                    [self setStatus:context.error.localizedDescription ?: @"CONTAINER_FOUND_ACCESS_DENIED"
                        path:nil active:nil error:YES];
                    return;
                }
                self->_accessContext = context;
                self->_accessMethod = FFAccessMethodDirect;
                [self updateGameRouting:context.gameIdentifier];
                [self setStatus:@"LOADING 3D OPTIONS…" path:nil active:nil error:NO];
                ZXFeatureColors(@"THREE_D", selectedGame, accessToken,
                    ^(NSArray<NSDictionary *> *colors, NSError *colorError) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setBusy:NO];
                        if (colorError) {
                            [self setStatus:colorError.localizedDescription path:nil active:nil error:YES];
                            return;
                        }
                        [self presentThreeDColors:colors];
                    });
                });
            });
        });
    }];
}

- (void)presentThreeDColors:(NSArray<NSDictionary *> *)colors {
    NSArray *received = [colors valueForKey:@"name"];
    if (![received isEqualToArray:@[@"BLACK", @"PINK", @"BLUE"]]) {
        [self setStatus:@"ASSET_NOT_FOUND: Black, Pink, Blue catalog verification failed."
            path:nil active:nil error:YES];
        return;
    }
    FFHologramPickerController *picker = [[FFHologramPickerController alloc]
        initWithColors:colors title:@"3D" applyTitle:@"APPLY 3D"
        selection:^(NSDictionary *color) {
            [self applyFeature:@"THREE_D" color:color[@"name"]
                expectedHash:color[@"sha256"] durationDays:0];
        }];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)applyFeature:(NSString *)feature color:(NSString *)color expectedHash:(NSString *)expectedHash
        durationDays:(NSInteger)durationDays {
    NSString *selectedGame = _selectedGameIdentifier;
    if (_busy || !_gameInstalled || !FFGameDefinition(selectedGame) ||
        ![FFLocalFeaturesForGame(selectedGame) containsObject:feature] ||
        ![_allowedFeatures containsObject:feature] ||
        ![_serverAvailableFeatures containsObject:feature]) {
        [self setStatus:@"FEATURE UNAVAILABLE FOR SELECTED GAME" path:nil active:nil error:YES];
        return;
    }
    if ([feature isEqualToString:@"HOLOGRAM_GUN"] && durationDays != 1 && durationDays != 3) {
        [self setStatus:@"APPLY_FAILED: Hologram duration must be 1 Day or 3 Days."
            path:nil active:nil error:YES];
        return;
    }
    _operationFeature = feature;
    _readyToRun = NO;
    [self setBusy:YES];
    BOOL coloredFeature = [@[@"HOLOGRAM_GUN", @"THREE_D"] containsObject:feature];
    NSString *operation = coloredFeature && color.length
        ? [NSString stringWithFormat:@"%@ %@", FFFeatureDisplayName(feature), color] : feature;
    _statusText = [NSString stringWithFormat:@"AUTHORIZING %@…", operation];
    _statusIsError = NO;
    [self rebuildInterface];
    [self setStatus:_statusText path:nil active:nil error:NO];
    [self refreshSessionForOperation:^(NSString *accessToken, NSError *sessionError) {
        if (sessionError) {
            self->_operationFeature = nil;
            [self setBusy:NO];
            [self setStatus:sessionError.localizedDescription path:nil active:nil error:YES];
            [self rebuildInterface];
            return;
        }
        ZXGrant(feature, selectedGame, accessToken, ^(NSString *featureToken, NSString *profileHash, NSError *authorizationError) {
            if (authorizationError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->_operationFeature = nil;
                    [self setBusy:NO];
                    [self setStatus:authorizationError.localizedDescription path:nil active:nil error:YES];
                    [self rebuildInterface];
                });
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setStatus:[NSString stringWithFormat:@"APPLYING %@…", operation]
                    path:nil active:nil error:NO];
            });
            NSString *downloadHash = coloredFeature ? expectedHash : profileHash;
            ZXFetch(feature, selectedGame, color, downloadHash, accessToken, featureToken,
                ^(NSData *profileData, NSError *downloadError) {
                if (downloadError) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self->_operationFeature = nil;
                        [self setBusy:NO];
                        [self setStatus:downloadError.localizedDescription path:nil active:nil error:YES];
                        [self rebuildInterface];
                    });
                    return;
                }
                if (coloredFeature &&
                    self->_accessMethod != FFAccessMethodDirect) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self->_operationFeature = nil;
                        [self setBusy:NO];
                        [self setStatus:@"CONTAINER_FOUND_ACCESS_DENIED: selected option requires verified direct game access."
                            path:nil active:nil error:YES];
                        [self rebuildInterface];
                    });
                    return;
                }
                FFAccessMethod accessMethod = self->_accessMethod;
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                    NSError *error = nil;
                    NSString *path = nil;
                    BOOL installed = NO;
                    if ([feature isEqualToString:@"HOLOGRAM_GUN"]) {
                        FFAccessContext *direct = [FFGameDetector detectDirectContainerForGame:selectedGame];
                        if (direct.discovered) {
                            [FFAccessVerifier verifyContext:direct requiresWrite:YES allowBackupOnly:NO];
                        }
                        if (!direct.usable) {
                            error = direct.error ?: FFNamedError(67, @"CONTAINER_FOUND_ACCESS_DENIED", @"Direct filesystem access is no longer usable.");
                        } else {
                            installed = FFInstallHologramPackage(profileData, selectedGame, &path, &error);
                        }
                    } else if ([feature isEqualToString:@"THREE_D"]) {
                        installed = FFInstallThreeDData(profileData, selectedGame, &path, &error);
                    } else {
                        installed = [FFFeatureManager installProfileData:profileData
                            forGame:selectedGame accessMethod:accessMethod targetPath:&path error:&error];
                    }
                    if (!installed && !error) error = FFNamedError(51, @"APPLY_FAILED", @"Option installation failed safely.");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (![self->_selectedGameIdentifier isEqualToString:selectedGame]) return;
                        self->_operationFeature = nil;
                        [self setBusy:NO];
                        if (error) {
                            if ([error.domain isEqualToString:@"com.acidevloper.ffcache"] &&
                                error.code >= 60 && error.code <= 67) {
                                self->_accessContext = nil;
                                self->_accessMethod = FFAccessMethodNone;
                                self->_usingSelectedFolder = NO;
                                self->_connectedGameIdentifier = nil;
                                self->_gameInstalled = NO;
                                self->_readyToRun = NO;
                            }
                            [self setStatus:error.localizedDescription path:path active:nil error:YES];
                        } else {
                            NSString *active = coloredFeature && color.length
                                ? [NSString stringWithFormat:@"%@ / %@", FFFeatureDisplayName(feature), color] : feature;
                            NSString *key = FFActiveProfileDefaultsKey(selectedGame);
                            if (key) [NSUserDefaults.standardUserDefaults setObject:active forKey:key];
                            if ([feature isEqualToString:@"HOLOGRAM_GUN"]) {
                                FFSaveHologramState(selectedGame, color, path, durationDays);
                            }
                            self->_readyToRun = YES;
                            [self setStatus:[NSString stringWithFormat:@"APPLY_SUCCESS — %@ ACTIVE", active]
                                path:path active:active error:NO];
                        }
                        [self rebuildInterface];
                    });
                });
            });
        });
    }];
}

- (void)installFeatureDataFromSelectedFolder:(NSData *)profileData feature:(NSString *)feature {
    __block NSString *path = nil;
    [self setStatus:[NSString stringWithFormat:@"APPLYING %@…", feature] path:nil active:nil error:NO];
    [self withSelectedRoot:^(NSURL *root, NSError **operationError) {
        NSFileCoordinator *rootCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        __block NSError *inner = nil;
        [rootCoordinator coordinateReadingItemAtURL:root options:0 error:&inner byAccessor:^(NSURL *coordinatedRoot) {
            NSURL *directory = FFFindGameAssetBundles(coordinatedRoot, &inner);
            NSURL *target = directory ? FFTargetFile(directory, self->_selectedGameIdentifier, NO, &inner) : nil;
            if (!target) return;
            path = target.path;
            NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [fileCoordinator coordinateWritingItemAtURL:target options:NSFileCoordinatorWritingForReplacing error:&inner byAccessor:^(NSURL *coordinatedTarget) {
                if (!FFInstallFeatureData(profileData, coordinatedTarget, &inner) && !inner) {
                    inner = FFError(51, @"Option installation failed.");
                }
            }];
        }];
        if (inner) *operationError = inner;
    } completion:^(NSError *error) {
        [self setBusy:NO];
        if (error) {
            [self setStatus:error.localizedDescription path:path active:nil error:YES];
            return;
        }
        NSString *key = FFActiveProfileDefaultsKey(self->_selectedGameIdentifier);
        if (key) [NSUserDefaults.standardUserDefaults setObject:feature forKey:key];
        [self setStatus:[NSString stringWithFormat:@"%@ ACTIVE", feature] path:path active:feature error:NO];
    }];
}

- (void)restoreOriginal {
    NSString *selectedGame = _selectedGameIdentifier;
    if (_busy || !_licensed || !_activationToken.length ||
        !FFGameDefinition(selectedGame)) {
        if (!_busy) [self setStatus:@"LICENSE AND INSTALLED GAME REQUIRED"
            path:nil active:@"—" error:YES];
        return;
    }
    if (!_gameInstalled) {
        [self setStatus:@"VERIFYING GAME BEFORE RESTORE…" path:nil active:nil error:NO];
        [self inspectDirectAccessWithCompletion:^(BOOL ready) {
            if (ready && [self->_selectedGameIdentifier isEqualToString:selectedGame]) {
                [self restoreOriginal];
            }
        }];
        return;
    }
    [self setBusy:YES];
    [self setStatus:@"VERIFYING SESSION…" path:nil active:nil error:NO];
    [self refreshSessionForOperation:^(NSString *accessToken, NSError *sessionError) {
        (void)accessToken;
        if (sessionError) {
            [self setBusy:NO];
            [self setStatus:sessionError.localizedDescription path:nil active:nil error:YES];
            return;
        }
        [self setStatus:@"Restoring original cache…" path:nil active:nil error:NO];
        FFAccessMethod accessMethod = self->_accessMethod;
        NSString *activeKey = FFActiveProfileDefaultsKey(selectedGame);
        NSString *activeProfile = activeKey ? [NSUserDefaults.standardUserDefaults stringForKey:activeKey] : nil;
        __block NSString *path = nil;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSError *error = nil;
            BOOL restored = NO;
            if ([activeProfile hasPrefix:@"HOLOGRAM"]) {
                restored = FFRestoreDirectAsset(selectedGame, FFHologramShaderFilename,
                    @"Hologram shader", &path, &error);
            } else if ([activeProfile hasPrefix:@"3D"]) {
                restored = FFRestoreDirectAsset(selectedGame, FFThreeDShaderFilename,
                    @"3D shader", &path, &error);
            } else {
                restored = [FFFeatureManager restoreOriginalForGame:selectedGame
                    accessMethod:accessMethod targetPath:&path error:&error];
            }
            if (!restored && !error) error = FFNamedError(51, @"RESTORE_FAILED", @"Restore failed safely.");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self->_selectedGameIdentifier isEqualToString:selectedGame]) return;
                [self setBusy:NO];
                if (error) {
                    if ([error.domain isEqualToString:@"com.acidevloper.ffcache"] &&
                        error.code >= 60 && error.code <= 67) {
                        self->_accessContext = nil;
                        self->_accessMethod = FFAccessMethodNone;
                        self->_usingSelectedFolder = NO;
                        self->_connectedGameIdentifier = nil;
                        self->_gameInstalled = NO;
                    }
                    [self setStatus:error.localizedDescription path:path active:nil error:YES];
                }
                else {
                    NSString *key = FFActiveProfileDefaultsKey(selectedGame);
                    if (key) [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
                    if ([activeProfile hasPrefix:@"HOLOGRAM"]) {
                        [NSUserDefaults.standardUserDefaults removeObjectForKey:FFHologramStateKey];
                    }
                    self->_readyToRun = NO;
                    [self setStatus:@"RESTORE_SUCCESS — ORIGINAL RESTORED" path:path active:@"ORIGINAL" error:NO];
                }
                [self rebuildInterface];
            });
        });
    }];
}

- (void)restoreOriginalFromSelectedFolder {
    __block NSString *path = nil;
    [self withSelectedRoot:^(NSURL *root, NSError **operationError) {
        NSFileCoordinator *rootCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        __block NSError *inner = nil;
        [rootCoordinator coordinateReadingItemAtURL:root options:0 error:&inner byAccessor:^(NSURL *coordinatedRoot) {
            NSURL *directory = FFFindGameAssetBundles(coordinatedRoot, &inner);
            NSURL *target = directory ? FFTargetFile(directory, self->_selectedGameIdentifier, YES, &inner) : nil;
            if (!target) return;
            path = target.path;
            NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [fileCoordinator coordinateWritingItemAtURL:target options:NSFileCoordinatorWritingForReplacing error:&inner byAccessor:^(NSURL *coordinatedTarget) {
                FFRestoreOriginal(coordinatedTarget, &inner);
            }];
        }];
        if (inner) *operationError = inner;
    } completion:^(NSError *error) {
        [self setBusy:NO];
        if (error) {
            [self setStatus:error.localizedDescription path:path active:nil error:YES];
            return;
        }
        NSString *key = FFActiveProfileDefaultsKey(self->_selectedGameIdentifier);
        if (key) [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
        [self setStatus:@"Original cache restored" path:path active:@"ORIGINAL" error:NO];
    }];
}

@end


@interface FFAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end


@implementation FFAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application; (void)launchOptions;
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    if (!FFBrandIdentityIsValid()) {
        UIViewController *blocked = [UIViewController new];
        blocked.view.backgroundColor = UIColor.systemBackgroundColor;
        UILabel *message = [UILabel new];
        message.translatesAutoresizingMaskIntoConstraints = NO;
        message.numberOfLines = 0;
        message.textAlignment = NSTextAlignmentCenter;
        message.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
        message.text = @"OFFICIAL BRAND IDENTITY CHECK FAILED\n@KODAIBATIB6";
        [blocked.view addSubview:message];
        [NSLayoutConstraint activateConstraints:@[
            [message.centerXAnchor constraintEqualToAnchor:blocked.view.centerXAnchor],
            [message.centerYAnchor constraintEqualToAnchor:blocked.view.centerYAnchor],
            [message.leadingAnchor constraintGreaterThanOrEqualToAnchor:blocked.view.leadingAnchor constant:24],
            [message.trailingAnchor constraintLessThanOrEqualToAnchor:blocked.view.trailingAnchor constant:-24],
        ]];
        self.window.rootViewController = blocked;
        [self.window makeKeyAndVisible];
        return YES;
    }
    UINavigationController *navigation = [[UINavigationController alloc]
        initWithRootViewController:[FFHomeViewController new]];
    navigation.navigationBar.tintColor = FFVIPGold();
    self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];

    // Free release: automatically open the official Telegram channel once
    // when the application is launched. No button press is required.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!FFBrandIdentityIsValid()) return;
        NSURL *officialChannel = [NSURL URLWithString:FFOfficialChannelURL];
        if (officialChannel) {
            [UIApplication.sharedApplication openURL:officialChannel
                                             options:@{}
                                   completionHandler:nil];
        }
    });
    return YES;
}
@end

// Anti-debug: request the kernel deny debugger attachment for this process.
// Bypassable by a determined reverser (patch out this call site or intercept
// syscall 26) but raises the bar for lldb / debugserver / frida-server attach.
// Reached via direct syscall so the symbol `ptrace` never appears in the
// import table.
#include <sys/syscall.h>
#include <unistd.h>
#define FF_PT_DENY_ATTACH 31
static void FFDenyDebugger(void) {
    syscall(SYS_ptrace, FF_PT_DENY_ATTACH, 0, 0, 0);
}

int main(int argc, char *argv[]) {
    FFDenyDebugger();
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(FFAppDelegate.class));
    }
}

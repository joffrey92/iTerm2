//
//  iTermPreferences.m
//  iTerm
//
//  Created by George Nachman on 4/6/14.
//
// At a minimum, each preference must have:
// - A key declared in the header and defined here
// - A default value in +defaultValueMap
// - A control defined in its view controller
//
// Optionally, it may have a function that computes its value (set in +computedObjectDictionary)
// and the view controller may customize how its control's appearance changes dynamically.

#import "iTermPreferences.h"
#import "iTermRemotePreferences.h"
#import "WindowArrangements.h"

#define BLOCK(x) [^id() { return [self x]; } copy]

NSString *const kTabStyleMetal = @"Metal";
NSString *const kTabStyleAqua = @"Aqua";
NSString *const kTabStyleUnified = @"Unified";
NSString *const kTabStyleAdium = @"Adium";

NSString *const kPreferenceKeyOpenBookmark = @"OpenBookmark";
NSString *const kPreferenceKeyOpenArrangementAtStartup = @"OpenArrangementAtStartup";
NSString *const kPreferenceKeyQuitWhenAllWindowsClosed = @"QuitWhenAllWindowsClosed";
NSString *const kPreferenceKeyConfirmClosingMultipleTabs = @"OnlyWhenMoreTabs";  // The key predates split panes
NSString *const kPreferenceKeyPromptOnQuit = @"PromptOnQuit";
NSString *const kPreferenceKeyInstantReplayMemoryMegabytes = @"IRMemory";
NSString *const kPreferenceKeySavePasteAndCommandHistory = @"SavePasteHistory";  // The key predates command history
NSString *const kPreferenceKeyAddBonjourHostsToProfiles = @"EnableRendezvous";  // The key predates the name Bonjour
NSString *const kPreferenceKeyCheckForUpdatesAutomatically = @"SUEnableAutomaticChecks";  // Key defined by Sparkle
NSString *const kPreferenceKeyCheckForTestReleases = @"CheckTestRelease";
NSString *const kPreferenceKeyLoadPrefsFromCustomFolder = @"LoadPrefsFromCustomFolder";
NSString *const kPreferenceKeyCustomFolder = @"PrefsCustomFolder";
NSString *const kPreferenceKeySelectionCopiesText = @"CopySelection";
NSString *const kPreferenceKeyCopyLastNewline = @"CopyLastNewline";
NSString *const kPreferenceKeyAllowClipboardAccessFromTerminal = @"AllowClipboardAccess";
NSString *const kPreferenceKeyCharactersConsideredPartOfAWordForSelection = @"WordCharacters";
NSString *const kPreferenceKeySmartWindowPlacement = @"SmartPlacement";
NSString *const kPreferenceKeyAdjustWindowForFontSizeChange = @"AdjustWindowForFontSizeChange";
NSString *const kPreferenceKeyMaximizeVerticallyOnly = @"MaxVertically";
NSString *const kPreferenceKeyLionStyleFullscren = @"UseLionStyleFullscreen";
NSString *const kPreferenceKeyOpenTmuxWindowsIn = @"OpenTmuxWindowsIn";
NSString *const kPreferenceKeyTmuxDashboardLimit = @"TmuxDashboardLimit";
NSString *const kPreferenceKeyAutoHideTmuxClientSession = @"AutoHideTmuxClientSession";

NSString *const kPreferenceKeyWindowStyle = @"kPreferenceKeyWindowStyle";
NSString *const kPreferenceKeyTabPosition = @"TabViewType";
NSString *const kPreferenceKeyHideTabBar = @"HideTab";
NSString *const kPreferenceKeyHighlightTabLabels = @"HighlightTabLabels";
NSString *const kPreferenceKeyHideTabNumber = @"HideTabNumber";
NSString *const kPreferenceKeyHideTabCloseButton = @"HideTabCloseButton";
NSString *const kPreferenceKeyHideTabActivityIndicator = @"HideActivityIndicator";
NSString *const kPreferenceKeyTimeToHoldCmdToShowTabsInFullScreen = @"FsTabDelay";
NSString *const kPreferenceKeyShowPaneTitles = @"ShowPaneTitles";
NSString *const kPreferenceKeyHideMenuBarInFullscreen = @"HideMenuBarInFullscreen";
NSString *const kPreferenceKeyShowWindowNumber = @"WindowNumber";
NSString *const kPreferenceKeyShowJobName = @"JobName";
NSString *const kPreferenceKeyShowProfileName = @"ShowBookmarkName";  // The key predates bookmarks being renamed to profiles
NSString *const kPreferenceKeyDimOnlyText = @"DimOnlyText";
NSString *const kPreferenceKeyDimmingAmount = @"SplitPaneDimmingAmount";
NSString *const kPreferenceKeyDimInactiveSplitPanes = @"DimInactiveSplitPanes";
NSString *const kPreferenceKeyAnimateDimming = @"AnimateDimming";
NSString *const kPreferenceKeyShowWindowBorder = @"UseBorder";
NSString *const kPreferenceKeyHideScrollbar = @"HideScrollbar";
NSString *const kPreferenceKeyDisableFullscreenTransparencyByDefault = @"DisableFullscreenTransparency";
NSString *const kPreferenceKeyDimBackgroundWindows = @"DimBackgroundWindows";

NSString *const kPreferenceKeyControlRemapping = @"Control";
NSString *const kPreferenceKeyLeftOptionRemapping = @"LeftOption";
NSString *const kPreferenceKeyRightOptionRemapping = @"RightOption";
NSString *const kPreferenceKeyLeftCommandRemapping = @"LeftCommand";
NSString *const kPreferenceKeyRightCommandRemapping = @"RightCommand";
NSString *const kPreferenceKeySwitchTabModifier = @"SwitchTabModifier";
NSString *const kPreferenceKeySwitchWindowModifier = @"SwitchWindowModifier";
NSString *const kPreferenceKeyHotkeyEnabled = @"Hotkey";
NSString *const kPreferenceKeyHotKeyCode = @"HotkeyCode";
NSString *const kPreferenceKeyHotkeyCharacter = @"HotkeyChar";  // Nonzero if hotkey char is set.
NSString *const kPreferenceKeyHotkeyModifiers = @"HotkeyModifiers";
NSString *const kPreferenceKeyHotKeyTogglesWindow = @"HotKeyTogglesWindow";
NSString *const kPreferenceKeyHotkeyProfileGuid = @"HotKeyBookmark";
NSString *const kPreferenceKeyHotkeyAutoHides = @"HotkeyAutoHides";

NSString *const kPreferenceKeyCmdClickOpensURLs = @"CommandSelection";
NSString *const kPreferenceKeyControlLeftClickBypassesContextMenu = @"PassOnControlClick";
NSString *const kPreferenceKeyOptionClickMovesCursor = @"OptionClickMovesCursor";
NSString *const kPreferenceKeyThreeFingerEmulatesMiddle = @"ThreeFingerEmulates";
NSString *const kPreferenceKeyFocusFollowsMouse = @"FocusFollowsMouse";
NSString *const kPreferenceKeyTripleClickSelectsFullWrappedLines = @"TripleClickSelectsFullWrappedLines";

NSString *const kPreferenceKeyAppVersion = @"iTerm Version";
NSString *const kPreferenceAutoCommandHistory = @"AutoCommandHistory";

static NSMutableDictionary *gObservers;

@implementation iTermPreferences

+ (void)initializeUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    // Force antialiasing to be allowed on small font sizes
    [userDefaults setInteger:1 forKey:@"AppleAntiAliasingThreshold"];
    [userDefaults setInteger:1 forKey:@"AppleSmoothFixedFontsSizeThreshold"];
    
    // Turn off scroll animations because they screw up the terminal scrolling.
    [userDefaults setInteger:0 forKey:@"AppleScrollAnimationEnabled"];

    // Override smooth scrolling, which breaks various things (such as the
    // assumption, when detectUserScroll is called, that scrolls happen
    // immediately), and generally sucks with a terminal.
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NSScrollAnimationEnabled"];

    // Store the current app version in prefs
    NSDictionary *infoDictionary = [[NSBundle bundleForClass:[self class]] infoDictionary];
    [userDefaults setObject:infoDictionary[@"CFBundleVersion"] forKey:kPreferenceKeyAppVersion];

    // Load prefs from remote.
    [[iTermRemotePreferences sharedInstance] copyRemotePrefsToLocalUserDefaults];
}

#pragma mark - Default values

+ (NSDictionary *)defaultValueMap {
    static NSDictionary *dict;
    if (!dict) {
        dict = @{ kPreferenceKeyOpenBookmark: @NO,
                  kPreferenceKeyOpenArrangementAtStartup: @NO,
                  kPreferenceKeyQuitWhenAllWindowsClosed: @NO,
                  kPreferenceKeyConfirmClosingMultipleTabs: @YES,
                  kPreferenceKeyPromptOnQuit: @YES,
                  kPreferenceKeyInstantReplayMemoryMegabytes: @4,
                  kPreferenceKeySavePasteAndCommandHistory: @NO,
                  kPreferenceKeyAddBonjourHostsToProfiles: @NO,
                  kPreferenceKeyCheckForUpdatesAutomatically: @YES,
                  kPreferenceKeyCheckForTestReleases: @YES,
                  kPreferenceKeyLoadPrefsFromCustomFolder: @NO,
                  kPreferenceKeyCustomFolder: [NSNull null],
                  kPreferenceKeySelectionCopiesText: @YES,
                  kPreferenceKeyCopyLastNewline: @NO,
                  kPreferenceKeyAllowClipboardAccessFromTerminal: @NO,
                  kPreferenceKeyCharactersConsideredPartOfAWordForSelection: @"/-+\\~_.",
                  kPreferenceKeySmartWindowPlacement: @NO,
                  kPreferenceKeyAdjustWindowForFontSizeChange: @YES,
                  kPreferenceKeyMaximizeVerticallyOnly: @NO,
                  kPreferenceKeyLionStyleFullscren: @YES,
                  kPreferenceKeyOpenTmuxWindowsIn: @(OPEN_TMUX_WINDOWS_IN_WINDOWS),
                  kPreferenceKeyTmuxDashboardLimit: @10,
                  kPreferenceKeyAutoHideTmuxClientSession: @NO,
                  
                  kPreferenceKeyWindowStyle: @(TAB_STYLE_METAL),
                  kPreferenceKeyTabPosition: @(TAB_POSITION_TOP),
                  kPreferenceKeyHideTabBar: @YES,
                  kPreferenceKeyHighlightTabLabels: @YES,
                  kPreferenceKeyHideTabNumber: @NO,
                  kPreferenceKeyHideTabCloseButton: @NO,
                  kPreferenceKeyHideTabActivityIndicator: @NO,
                  kPreferenceKeyTimeToHoldCmdToShowTabsInFullScreen: @1.0,
                  kPreferenceKeyShowPaneTitles: @YES,
                  kPreferenceKeyHideMenuBarInFullscreen:@YES,
                  kPreferenceKeyShowWindowNumber: @YES,
                  kPreferenceKeyShowJobName: @YES,
                  kPreferenceKeyShowProfileName: @NO,
                  kPreferenceKeyDimOnlyText: @NO,
                  kPreferenceKeyDimmingAmount: @0.4,
                  kPreferenceKeyDimInactiveSplitPanes: @YES,
                  kPreferenceKeyAnimateDimming: @NO,
                  kPreferenceKeyShowWindowBorder: @NO,
                  kPreferenceKeyHideScrollbar: @NO,
                  kPreferenceKeyDisableFullscreenTransparencyByDefault: @NO,
                  kPreferenceKeyDimBackgroundWindows: @NO,

                  kPreferenceKeyControlRemapping: @(kPreferencesModifierTagControl),
                  kPreferenceKeyLeftOptionRemapping: @(kPreferencesModifierTagLeftOption),
                  kPreferenceKeyRightOptionRemapping: @(kPreferencesModifierTagRightOption),
                  kPreferenceKeyLeftCommandRemapping: @(kPreferencesModifierTagLeftCommand),
                  kPreferenceKeyRightCommandRemapping: @(kPreferencesModifierTagRightCommand),
                  kPreferenceKeySwitchTabModifier: @(kPreferencesModifierTagEitherCommand),
                  kPreferenceKeySwitchWindowModifier: @(kPreferencesModifierTagCommandAndOption),
                  kPreferenceKeyHotkeyEnabled: @NO,
                  kPreferenceKeyHotKeyCode: @0,
                  kPreferenceKeyHotkeyCharacter: @0,
                  kPreferenceKeyHotkeyModifiers: @0,
                  kPreferenceKeyHotKeyTogglesWindow: @NO,
                  kPreferenceKeyHotkeyProfileGuid: [NSNull null],
                  kPreferenceKeyHotkeyAutoHides: @YES,

                  kPreferenceKeyCmdClickOpensURLs: @YES,
                  kPreferenceKeyControlLeftClickBypassesContextMenu: @NO,
                  kPreferenceKeyOptionClickMovesCursor: @YES,
                  kPreferenceKeyThreeFingerEmulatesMiddle: @NO,
                  kPreferenceKeyFocusFollowsMouse: @NO,
                  kPreferenceKeyTripleClickSelectsFullWrappedLines: @NO,
                  
                  kPreferenceAutoCommandHistory: @NO,
                  };
        [dict retain];
    }
    return dict;
}

+ (id)defaultObjectForKey:(NSString *)key {
    id obj = [self defaultValueMap][key];
    if ([obj isKindOfClass:[NSNull class]]) {
        return nil;
    } else {
        return obj;
    }
}

+ (BOOL)defaultValueForKey:(NSString *)key isCompatibleWithType:(PreferenceInfoType)type {
    id defaultValue = [self defaultValueMap][key];
    switch (type) {
        case kPreferenceInfoTypeIntegerTextField:
        case kPreferenceInfoTypePopup:
            return ([defaultValue isKindOfClass:[NSNumber class]] &&
                    [defaultValue doubleValue] == ceil([defaultValue doubleValue]));
        case kPreferenceInfoTypeCheckbox:
            return ([defaultValue isKindOfClass:[NSNumber class]] &&
                    ([defaultValue intValue] == YES ||
                     [defaultValue intValue] == NO));
        case kPreferenceInfoTypeSlider:
            return [defaultValue isKindOfClass:[NSNumber class]];
        case kPreferenceInfoTypeTokenField:
            return ([defaultValue isKindOfClass:[NSArray class]] ||
                    [defaultValue isKindOfClass:[NSNull class]]);
        case kPreferenceInfoTypeStringTextField:
            return ([defaultValue isKindOfClass:[NSString class]] ||
                    [defaultValue isKindOfClass:[NSNull class]]);
        case kPreferenceInfoTypeMatrix:
            return [defaultValue isKindOfClass:[NSString class]];
        case kPreferenceInfoTypeColorWell:
            return [defaultValue isKindOfClass:[NSDictionary class]];
    }
    
    return NO;
}

#pragma mark - Computed values

// Returns a dictionary from key to a ^id() block. The block will return an object value for the
// preference or nil if the normal path (of taking the NSUserDefaults value or +defaultObjectForKey)
// should be used.
+ (NSDictionary *)computedObjectDictionary {
    static NSDictionary *dict;
    if (!dict) {
        dict = @{ kPreferenceKeyOpenArrangementAtStartup: BLOCK(computedOpenArrangementAtStartup),
                  kPreferenceKeyCustomFolder: BLOCK(computedCustomFolder),
                  kPreferenceKeyCharactersConsideredPartOfAWordForSelection: BLOCK(computedWordChars) };
        [dict retain];
    }
    return dict;
}

+ (id)computedObjectForKey:(NSString *)key {
    id (^block)() = [self computedObjectDictionary][key];
    if (block) {
        return block();
    } else {
        return nil;
    }
}

+ (NSString *)uncomputedObjectForKey:(NSString *)key {
    id object = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (!object) {
        object = [self defaultObjectForKey:key];
    }
    return object;
}

+ (id)objectForKey:(NSString *)key {
    id object = [self computedObjectForKey:key];
    if (!object) {
        object = [self uncomputedObjectForKey:key];
    }
    return object;
}

+ (void)setObject:(id)object forKey:(NSString *)key {
    NSArray *observers = gObservers[key];
    id before = nil;
    if (observers) {
        before = [self objectForKey:key];
        
        // nil out observers if there is no change.
        if (before && object && [before isEqual:object]) {
            observers = nil;
        } else if (!before && !object) {
            observers = nil;
        }
    }
    if (object) {
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }

    for (void (^block)(id, id) in observers) {
        block(before, object);
    }
}

#pragma mark - APIs

+ (BOOL)keyHasDefaultValue:(NSString *)key {
    return ([self defaultValueMap][key] != nil);
}

+ (BOOL)boolForKey:(NSString *)key {
    return [(NSNumber *)[self objectForKey:key] boolValue];
}

+ (void)setBool:(BOOL)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

+ (int)intForKey:(NSString *)key {
    return [(NSNumber *)[self objectForKey:key] intValue];
}

+ (void)setInt:(int)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

+ (double)floatForKey:(NSString *)key {
    return [(NSNumber *)[self objectForKey:key] doubleValue];
}

+ (void)setFloat:(double)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

+ (NSString *)stringForKey:(NSString *)key {
    id object = [self objectForKey:key];
    assert(!object || [object isKindOfClass:[NSString class]]);
    return object;
}

+ (void)setString:(NSString *)value forKey:(NSString *)key {
    [self setObject:value forKey:key];
}

+ (void)addObserverForKey:(NSString *)key block:(void (^)(id before, id after))block {
    if (!gObservers) {
        gObservers = [[NSMutableDictionary alloc] init];
    }
    NSMutableArray *observersForKey = gObservers[key];
    if (!observersForKey) {
        observersForKey = [NSMutableArray array];
        gObservers[key] = observersForKey;
    }
    [observersForKey addObject:[block copy]];
}

+ (NSUInteger)maskForModifierTag:(iTermPreferencesModifierTag)tag {
    switch (tag) {
        case kPreferencesModifierTagEitherCommand:
            return NSCommandKeyMask;
            
        case kPreferencesModifierTagCommandAndOption:
            return NSCommandKeyMask | NSAlternateKeyMask;
            
        case kPreferencesModifierTagEitherOption:
            return NSAlternateKeyMask;
            
        default:
            NSLog(@"Unexpected value for maskForModifierTag: %d", tag);
            return NSCommandKeyMask | NSAlternateKeyMask;
    }
}

#pragma mark - Value Computation Methods

+ (NSNumber *)computedOpenArrangementAtStartup {
    if ([WindowArrangements count] == 0) {
        return @NO;
    } else {
        return nil;
    }
}

// Text fields don't like nil strings.
+ (NSString *)computedCustomFolder {
    NSString *prefsCustomFolder = [self uncomputedObjectForKey:kPreferenceKeyCustomFolder];
    return prefsCustomFolder ?: @"";
}

// Text fields don't like nil strings.
+ (NSString *)computedWordChars {
    NSString *wordChars =
        [self uncomputedObjectForKey:kPreferenceKeyCharactersConsideredPartOfAWordForSelection];
    return wordChars ?: @"";
}

#pragma mark - Migration

+ (BOOL)migratePreferences
{
    NSString *prefDir = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
                             stringByAppendingPathComponent:@"Preferences"];
    
    NSString *reallyOldPrefs = [prefDir stringByAppendingPathComponent:@"iTerm.plist"];
    NSString *somewhatOldPrefs = [prefDir stringByAppendingPathComponent:@"net.sourceforge.iTerm.plist"];
    NSString *newPrefs = [prefDir stringByAppendingPathComponent:@"com.googlecode.iterm2.plist"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:newPrefs]) {
        return NO;
    }
    NSString* source;
    if ([fileManager fileExistsAtPath:somewhatOldPrefs]) {
        source = somewhatOldPrefs;
    } else if ([fileManager fileExistsAtPath:reallyOldPrefs]) {
        source = reallyOldPrefs;
    } else {
        return NO;
    }
    
    NSLog(@"Preference file migrated");
    [fileManager copyItemAtPath:source toPath:newPrefs error:nil];
    [NSUserDefaults resetStandardUserDefaults];
    return (YES);
}

@end

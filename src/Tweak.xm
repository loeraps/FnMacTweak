#import "./views/popupViewController.h"
#import "./globals.h"

#import "../lib/fishhook.h"
#import <sys/sysctl.h>

#import <GameController/GameController.h>
#import <UIKit/UIKit.h>

/* Suggestions list:
    - remap keybinding - perfectly possible, but is it really necessary?
    - disable invalid key chime playing on Mac - not possible as far as I know
    - disable Esc key from unfullscreening the game - not possible as far as I know
*/

// --------- DEVICE SPOOFING ---------

// Code largely taken from PlayCover's Playtools library:

// Save original function pointers
static int (*orig_sysctl)(int *, u_int, void *, size_t *, void *, size_t) = NULL;
static int (*orig_sysctlbyname)(const char *, void *, size_t *, void *, size_t) = NULL;

// Update output of sysctl for key values hw.machine, hw.product and hw.target to match iOS output
// This spoofs the device type to apps allowing us to report as any iOS device
static int pt_sysctl(int *name, u_int namelen, void *buf, size_t *size, void *arg0, size_t arg1) {
    if (name[0] == CTL_HW && (name[1] == HW_MACHINE || name[1] == HW_PRODUCT)) {
        if (buf == NULL) {
            *size = strlen(DEVICE_MODEL) + 1;
        } else {
            if (*size > strlen(DEVICE_MODEL)) {
                strcpy((char *)buf, DEVICE_MODEL);
            } else {
                return ENOMEM;
            }
        }
        return 0;
    } else if (name[0] == CTL_HW && name[1] == HW_TARGET) {
        if (buf == NULL) {
            *size = strlen(OEM_ID) + 1;
        } else {
            if (*size > strlen(OEM_ID)) {
                strcpy((char *)buf, OEM_ID);
            } else {
                return ENOMEM;
            }
        }
        return 0;
    }
    return orig_sysctl(name, namelen, buf, size, arg0, arg1);
}

// Spoof sysctlbyname for hw.machine, hw.product, hw.model, hw.target
static int pt_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if ((strcmp(name, "hw.machine") == 0) || (strcmp(name, "hw.product") == 0) || (strcmp(name, "hw.model") == 0)) {
        if (oldp == NULL) {
            int ret = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
            // We don't want to accidentally decrease it because the real sysctl call will ENOMEM
            // as model are much longer on Macs (eg. MacBookAir10,1)
            if (oldlenp && *oldlenp < strlen(DEVICE_MODEL) + 1) {
                *oldlenp = strlen(DEVICE_MODEL) + 1;
            }
            return ret;
        } else if (oldp != NULL) {
            int ret = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
            const char *machine = DEVICE_MODEL;
            strncpy((char *)oldp, machine, strlen(machine));
            ((char *)oldp)[strlen(machine)] = '\0';
            if (oldlenp) *oldlenp = strlen(machine) + 1;
            return ret;
        }
    } else if (strcmp(name, "hw.target") == 0) {
        if (oldp == NULL) {
            int ret = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
            if (oldlenp && *oldlenp < strlen(OEM_ID) + 1) {
                *oldlenp = strlen(OEM_ID) + 1;
            }
            return ret;
        } else if (oldp != NULL) {
            int ret = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
            const char *machine = OEM_ID;
            strncpy((char *)oldp, machine, strlen(machine));
            ((char *)oldp)[strlen(machine)] = '\0';
            if (oldlenp) *oldlenp = strlen(machine) + 1;
            return ret;
        }
    }
    return orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
}

// --------- CONSTRUCTOR ---------

%ctor {
    // We use Fishhook instead of the built-in stuff because we are in a jailed environment
    struct rebinding rebindings[] = {
        {"sysctl", (void *)pt_sysctl, (void **)&orig_sysctl},
        {"sysctlbyname", (void *)pt_sysctlbyname, (void **)&orig_sysctlbyname}
    };
    rebind_symbols(rebindings, 2);

    // Temporary (will remove maybe in case of keybinds support)
    TRIGGER_KEY = GCKeyCodeLeftAlt;
    POPUP_KEY = GCKeyCodeKeyP;
}

// --------- HELPER FUNCTIONS ---------

// Initialize the popup window
static void createPopup() {
    popupWindow = [[UIWindow alloc] initWithFrame:CGRectMake(100, 100, 330, 350)];
    popupWindow.windowLevel = UIWindowLevelAlert + 1;
    popupWindow.layer.cornerRadius = 15;
    popupWindow.clipsToBounds = true;
    
    popupViewController *popupVC = [popupViewController new];
    popupWindow.rootViewController = popupVC;
}

// Force a pointer lock update
static void updateMouseLock(BOOL value) {
    // Very hacky way to bypass the deprecation notice error
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    #pragma clang diagnostic pop

    UIViewController *mainViewController = keyWindow.rootViewController;
    [mainViewController setNeedsUpdateOfPrefersPointerLocked];

    if (value == false) {
        isAlreadyFocused = false;
    }
}

// --------- THEOS HOOKS ---------

// Disable mouse movement when the mouse isn't locked
%hook GCMouseInput

- (void)setMouseMovedHandler:(GCMouseMoved)handler {
    if (!handler) {
        %orig;
        return;
    }
    
    GCMouseMoved customHandler = ^(GCMouseInput * _Nonnull eventMouse, float deltaX, float deltaY) {
        // Only call the original handler if the mouse is locked
        if (isMouseLocked) {
            // Right-click is being held, so the user is likely aiming down sights
            if (GCMouse.current.mouseInput.rightButton.value == 1.0) {
                handler(eventMouse, deltaX * ADS_MULTIPLIER_X / 100.0f, deltaY * ADS_MULTIPLIER_Y / 100.0f);
            } else {
                handler(eventMouse, deltaX * LOOK_MULTIPLIER_X / 100.0f, deltaY * LOOK_MULTIPLIER_Y / 100.0f);
            }
        }
    };

    // Handle our custom method instead
    %orig(customHandler);
}

%end

// Disable GameController framework mouse touch input when we're using touch input
%hook GCControllerButtonInput

- (void)setPressedChangedHandler:(GCControllerButtonValueChangedHandler)handler {
    if (!handler) {
        %orig;
        return;
    }
    
    // Only intercept the left mouse button
    if (self == GCMouse.current.mouseInput.leftButton) {
        GCControllerButtonValueChangedHandler customHandler = ^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
            // Only call the original handler if the mouse is locked
            if (isMouseLocked) {
                // Only register mouse presses once we've already clicked once, indicating that our pointer is fully "locked"; to avoid presses when the mouse isn't already hidden
                if (isAlreadyFocused) {
                    handler(button, value, pressed);
                } else {
                    isAlreadyFocused = true;
                }
            }
        };

        // Handle our custom method instead
        %orig(customHandler);
    } else {
        %orig;
    }
}

%end

// Press key to enable/disable mouse locking
%hook GCKeyboardInput

- (void)setKeyChangedHandler:(GCKeyboardValueChangedHandler)handler {
    if (!handler) {
        %orig;
        return;
    }
    
    // Only execute if we're assigning it to something to avoid an error
    GCKeyboardValueChangedHandler customHandler = ^(GCKeyboardInput * _Nonnull keyboard, GCControllerButtonInput * _Nonnull key, GCKeyCode keyCode, BOOL pressed) {
        // Check whether the triggering key was pressed and wasn't released
        if (!pressed) {
            handler(keyboard, key, keyCode, pressed);
            return;
        }

        if (keyCode == TRIGGER_KEY) {
            // Don't allow us to manually control the pointer visibility if we're in the popup settings UI
            if (isPopupVisible) return;
            
            // Toggle mouse-pointer functionality and request an update
            isMouseLocked = !isMouseLocked;

            updateMouseLock(isMouseLocked);
        } else if (keyCode == POPUP_KEY) {
            if (!popupWindow) {
                // Create window if it doesn't exist yet
                createPopup();
            }
            
            // Toggle visibility
            isPopupVisible = !isPopupVisible;
            popupWindow.hidden = !isPopupVisible;

            // Show mouse
            isMouseLocked = false;
            updateMouseLock(isMouseLocked);
        } else {
            // Idk, is this really necessary??
            // if (!isMouseLocked) return;

            // Call the original handler (equivalent to %orig)
            handler(keyboard, key, keyCode, pressed);
        }
    };

    // Handle our custom method instead
    %orig(customHandler);
}

%end

// Disable pointer "locking" mechanism, see UE source code for reference (IOSView.cpp)
%hook IOSViewController

- (BOOL)prefersPointerLocked {
    return isMouseLocked;
}

%end

// Enable 120 frames per second on any screen
%hook UIScreen

- (NSInteger)maximumFramesPerSecond {
    return 120;
}

%end

// See UE source code for reference (IOSView.cpp); normally mouse clicks get ignored, so trick the game into thinking they're touchscreen clicks
%hook UITouch

- (UITouchType)type {
    UITouchType _original = %orig;
    
    // UITouchTypeIndirectPointer = 3
    if (!isMouseLocked && _original == UITouchTypeIndirectPointer) {
        // UITouchTypeDirect = 0
        return UITouchTypeDirect;
    }
    else {
        return _original;
    }
}

%end
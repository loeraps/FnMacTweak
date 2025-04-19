TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FnMacTweak

FnMacTweak_FILES = ./src/Tweak.xm ./src/views/popupViewController.m ./src/globals.m ./lib/fishhook.c
FnMacTweak_FRAMEWORKS = UIKit
FnMacTweak_CFLAGS = -fobjc-arc

DEBUG = 0

include $(THEOS_MAKE_PATH)/tweak.mk

PRODUCT_BUILD_PROP_OVERRIDES += BUILD_UTC_DATE=0

ifneq ($(TARGET_SCREEN_WIDTH) $(TARGET_SCREEN_HEIGHT),$(space))
# determine the smaller dimension
TARGET_BOOTANIMATION_SIZE := $(shell \
  if [ $(TARGET_SCREEN_WIDTH) -lt $(TARGET_SCREEN_HEIGHT) ]; then \
    echo $(TARGET_SCREEN_WIDTH); \
  else \
    echo $(TARGET_SCREEN_HEIGHT); \
  fi )

# get a sorted list of the sizes
bootanimation_sizes := $(subst .zip,, $(shell ls vendor/glaze/prebuilt/common/bootanimation))
bootanimation_sizes := $(shell echo -e $(subst $(space),'\n',$(bootanimation_sizes)) | sort -rn)

# find the appropriate size and set
define check_and_set_bootanimation
$(eval TARGET_BOOTANIMATION_NAME := $(shell \
  if [ -z "$(TARGET_BOOTANIMATION_NAME)" ]; then
    if [ $(1) -le $(TARGET_BOOTANIMATION_SIZE) ]; then \
      echo $(1); \
      exit 0; \
    fi;
  fi;
  echo $(TARGET_BOOTANIMATION_NAME); ))
endef
$(foreach size,$(bootanimation_sizes), $(call check_and_set_bootanimation,$(size)))

PRODUCT_BOOTANIMATION := vendor/glaze/prebuilt/common/bootanimation/$(TARGET_BOOTANIMATION_NAME).zip
endif

ifeq ($(PRODUCT_GMS_CLIENTID_BASE),)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.com.google.clientidbase=android-google
else
PRODUCT_PROPERTY_OVERRIDES += \
    ro.com.google.clientidbase=$(PRODUCT_GMS_CLIENTID_BASE)
endif

PRODUCT_PROPERTY_OVERRIDES += \
    keyguard.no_require_sim=true

PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.selinux=1

# Disable excessive dalvik debug messages
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.debug.alloc=0

# Default sounds
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.ringtone=Titania.ogg \
    ro.config.notification_sound=Tethys.ogg

# Backup Tool
PRODUCT_COPY_FILES += \
    vendor/glaze/prebuilt/common/bin/backuptool.sh:install/bin/backuptool.sh \
    vendor/glaze/prebuilt/common/bin/backuptool.functions:install/bin/backuptool.functions \
    vendor/glaze/prebuilt/common/bin/50-glaze.sh:system/addon.d/50-glaze.sh

# Signature compatibility validation
PRODUCT_COPY_FILES += \
    vendor/glaze/prebuilt/common/bin/otasigcheck.sh:install/bin/otasigcheck.sh

# GLAZE-specific init file
PRODUCT_COPY_FILES += \
    vendor/glaze/prebuilt/common/etc/init.local.rc:root/init.glaze.rc

# SELinux filesystem labels
PRODUCT_COPY_FILES += \
    vendor/glaze/prebuilt/common/etc/init.d/50selinuxrelabel:system/etc/init.d/50selinuxrelabel

# Enable SIP+VoIP on all targets
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml

# Don't export PS1 in /system/etc/mkshrc.
PRODUCT_COPY_FILES += \
    vendor/glaze/prebuilt/common/etc/mkshrc:system/etc/mkshrc \
    vendor/glaze/prebuilt/common/etc/sysctl.conf:system/etc/sysctl.conf

PRODUCT_COPY_FILES += \
    vendor/glaze/prebuilt/common/etc/init.d/00banner:system/etc/init.d/00banner \
    vendor/glaze/prebuilt/common/etc/init.d/90userinit:system/etc/init.d/90userinit \
    vendor/glaze/prebuilt/common/bin/sysinit:system/bin/sysinit

# debug packages
ifneq ($(TARGET_BUILD_VARIENT),user)
PRODUCT_PACKAGES += \
    Development
endif

# Optional packages
PRODUCT_PACKAGES += \
    Basic \
    LiveWallpapersPicker \
    PhaseBeam

# Include explicitly to work around GMS issues
PRODUCT_PACKAGES += \
    libprotobuf-cpp-full \
    librsjni

# AudioFX
PRODUCT_PACKAGES += \
    AudioFX

# CM Hardware Abstraction Framework
PRODUCT_PACKAGES += \
    org.cyanogenmod.hardware \
    org.cyanogenmod.hardware.xml

# Extra Optional packages
PRODUCT_PACKAGES += \
    LatinIME \
    BluetoothExt

PRODUCT_PACKAGES += \
		ThemeInterfacer

# GlazeOS Statistics
PRODUCT_COPY_FILES +=  \
		vendor/glaze/prebuilt/common/app/GlazeStats/GlazeStats.apk:system/app/GlazeStats/GlazeStats.apk \

## Don't compile SystemUITests
EXCLUDE_SYSTEMUI_TESTS := true

# Extra tools
PRODUCT_PACKAGES += \
    openvpn \
    e2fsck \
    mke2fs \
    tune2fs \
    mkfs.ntfs \
    fsck.ntfs \
    mount.ntfs

WITH_EXFAT ?= true
ifeq ($(WITH_EXFAT),true)
TARGET_USES_EXFAT := true
PRODUCT_PACKAGES += \
    mount.exfat \
    fsck.exfat \
    mkfs.exfat
endif

# Stagefright FFMPEG plugin
PRODUCT_PACKAGES += \
    libffmpeg_extractor \
    libffmpeg_omx \
    media_codecs_ffmpeg.xml

PRODUCT_PROPERTY_OVERRIDES += \
    media.sf.omx-plugin=libffmpeg_omx.so \
    media.sf.extractor-plugin=libffmpeg_extractor.so

# easy way to extend to add more packages
-include vendor/extra/product.mk

# Telephony
PRODUCT_PACKAGES += \
    telephony-ext

PRODUCT_BOOT_JARS += \
    telephony-ext

PRODUCT_PACKAGE_OVERLAYS += \
    vendor/glaze/overlay/common \
    vendor/glaze/overlay/dictionaries

# Versioning System
# GlazeOS version.
PRODUCT_VERSION_MAJOR = 1
PRODUCT_VERSION_MINOR = 0
PRODUCT_VERSION_MAINTENANCE = 0
ifdef GLAZE_BUILD_EXTRA
    GLAZE_POSTFIX := -$(GLAZE_BUILD_EXTRA)
endif
ifndef GLAZE_BUILD_TYPE
    GLAZE_BUILD_TYPE := UNOFFICIAL
endif

ifndef GLAZE_POSTFIX
    GLAZE_POSTFIX := -$(shell date +"%Y%m%d-%H%M")
endif

GLAZE_VERSION := GlazeOS-$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)-$(GLAZE_BUILD_TYPE)$(GLAZE_BUILD)

PRODUCT_PROPERTY_OVERRIDES += \
    BUILD_DISPLAY_ID=$(BUILD_ID) \
    glaze.ota.version=$(shell date +%Y%m%d) \
    ro.glaze.version=$(GLAZE_VERSION) \
    ro.glazeversion=$(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR) \
    ro.glaze.buildtype=$(GLAZE_BUILD_TYPE)

EXTENDED_POST_PROCESS_PROPS := vendor/glaze/tools/glaze_process_props.py

ifeq ($(BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE),)
  ADDITIONAL_DEFAULT_PROPERTIES += \
    ro.device.cache_dir=/data/cache
else
  ADDITIONAL_DEFAULT_PROPERTIES += \
    ro.device.cache_dir=/cache
endif

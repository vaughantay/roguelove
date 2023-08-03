# Source files folder
SOURCE := src
# Output folder
OUT := build
# Resources folder
RESOURCES := resources
# Temp folder
TEMP := temp

# LOVE version
LOVE_VERSION := 11.4
# LOVE_NX version (for switch)
LOVE_NX_VERSION := 11.4

# Game version
GAME_VERSION := 1.0
# Game author
GAME_AUTHOR := Taylor Vaughan
# Game title
TITLE := Roguelove

DIR := $(shell pwd)

all: lovefile desktop console

resources: resources-win32 resources-win64 resources-macos resources-switch

desktop: lovefile win64 win32 macos

console: lovefile switch

resources-win32:
	@mkdir -p $(RESOURCES)

	@mkdir -p $(TEMP)/build-win32
	@wget -O $(TEMP)/build-win32/love-win32.zip https://github.com/love2d/love/releases/download/$(LOVE_VERSION)/love-$(LOVE_VERSION)-win32.zip
	@unzip $(TEMP)/build-win32/love-win32.zip -d $(RESOURCES)/ "*.dll" "*.exe" "*.txt"

	@rm -rf $(TEMP)

resources-win64:
	@mkdir -p $(RESOURCES)

	@mkdir -p $(TEMP)/build-win64
	@wget -O $(TEMP)/build-win64/love-win64.zip https://github.com/love2d/love/releases/download/$(LOVE_VERSION)/love-$(LOVE_VERSION)-win64.zip
	@unzip $(TEMP)/build-win64/love-win64.zip -d $(RESOURCES)/ "*.dll" "*.exe" "*.txt"

	@rm -rf $(TEMP)

resources-macos:
	@mkdir -p $(RESOURCES)

	@mkdir -p $(TEMP)/build-macos
	@wget -O $(TEMP)/build-macos/love-macos.zip https://github.com/love2d/love/releases/download/$(LOVE_VERSION)/love-$(LOVE_VERSION)-macos.zip
	@unzip $(TEMP)/build-macos/love-macos.zip -d $(RESOURCES)/

	@rm -rf $(TEMP)

resources-switch:
	@mkdir -p $(RESOURCES)/switch
	@wget -O $(RESOURCES)/switch/love.elf https://github.com/retronx-team/love-nx/releases/download/11.4-nx1/love.elf

lovefile:
	@rm -rf $(OUT)/lovefile
	@mkdir -p $(OUT)/lovefile

	@cd $(SOURCE); zip -r -9 $(DIR)/$(OUT)/lovefile/$(TITLE).love .

	@mkdir -p $(OUT)/release
	@rm -f build/release/$(TITLE)-lovefile.zip
	@cd build/lovefile; zip -9 -r ../release/$(TITLE)-lovefile.zip .

win32: lovefile
	$(eval BITS := 32)
	$(eval LOVE_PATH := $(RESOURCES)/love-$(LOVE_VERSION)-win$(BITS))

	@rm -rf $(OUT)/win$(BITS)
	@mkdir -p $(OUT)/win$(BITS)

	@cp $(LOVE_PATH)/OpenAL32.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/SDL2.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/license.txt $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/lua51.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/mpg123.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/love.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/msvcp120.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/msvcr120.dll $(OUT)/win$(BITS)

	@cat $(LOVE_PATH)/love.exe $(OUT)/lovefile/$(TITLE).love > $(OUT)/win$(BITS)/$(TITLE).exe

	@mkdir -p $(OUT)/release
	@rm -f $(OUT)/release/$(TITLE)-win$(BITS).zip
	@cd $(OUT)/win$(BITS); zip -9 -r ../release/${TITLE}-win32.zip .

win32-full: resources-win32 win32

win64: lovefile
	$(eval BITS := 64)
	$(eval LOVE_PATH := $(RESOURCES)/love-$(LOVE_VERSION)-win$(BITS))

	@rm -rf $(OUT)/win$(BITS)
	@mkdir -p $(OUT)/win$(BITS)

	@cp $(LOVE_PATH)/OpenAL32.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/SDL2.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/license.txt $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/lua51.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/mpg123.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/love.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/msvcp120.dll $(OUT)/win$(BITS)
	@cp $(LOVE_PATH)/msvcr120.dll $(OUT)/win$(BITS)

	@cat $(LOVE_PATH)/love.exe $(OUT)/lovefile/$(TITLE).love > $(OUT)/win$(BITS)/$(TITLE).exe

	@mkdir -p $(OUT)/release
	@rm -f $(OUT)/release/$(TITLE)-win$(BITS).zip
	@cd $(OUT)/win$(BITS); zip -9 -r ../release/${TITLE}-win64.zip .

win64-full: resources-win64 win64

macos: lovefile
	@rm -rf $(OUT)/macos
	@mkdir -p "$(OUT)/macos/$(TITLE).app"

	@cp -r $(RESOURCES)/love.app/. $(OUT)/macos/$(TITLE).app

	@cp $(OUT)/lovefile/$(TITLE).love "$(OUT)/macos/$(TITLE).app/Contents/Resources"

	@mkdir -p $(OUT)/release
	@rm -f $(OUT)/release/$(TITLE)-macos.zip
	@cd $(OUT)/macos; zip -9 -r ../release/$(TITLE)-macos.zip .

macos-full: resources-macos macos

switch: lovefile
	@rm -rf $(OUT)/switch

	@mkdir -p $(TEMP)/build-switch/romfs
	@mkdir -p $(OUT)/switch

	@cp $(OUT)/lovefile/$(TITLE).love "$(TEMP)/build-switch/romfs/game.love"

	${DEVKITPRO}/tools/bin/nacptool --create "$(TITLE)" "$(GAME_AUTHOR)" "$(GAME_VERSION)" $(TEMP)/build-switch/$(TITLE).nacp
	${DEVKITPRO}/tools/bin/elf2nro $(RESOURCES)/switch/love.elf $(OUT)/switch/$(TITLE).nro --nacp=$(TEMP)/build-switch/$(TITLE).nacp --romfsdir=$(TEMP)/build-switch/romfs

	@rm -rf $(TEMP)
	@cd $(OUT)/switch; zip -9 -r ../release/${TITLE}-switch.zip .

switch-full: resources-switch switch

clean:
	@rm -rf $(OUT)
	@rm -rf $(RESOURCES)
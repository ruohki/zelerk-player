APP_NAME    := zelerK
BUNDLE_ID   := com.zelerk.app
VERSION     := 1.0.0
BUILD_DIR   := .build/release
APP_BUNDLE  := $(APP_NAME).app
DMG_NAME    := $(APP_NAME)-Installer

# Parse version components
VERSION_MAJOR := $(word 1,$(subst ., ,$(VERSION)))
VERSION_MINOR := $(word 2,$(subst ., ,$(VERSION)))
VERSION_PATCH := $(word 3,$(subst ., ,$(VERSION)))

define INFO_PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>$(APP_NAME)</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>$(BUNDLE_ID)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(APP_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(VERSION)</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>12.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSSupportsAutomaticTermination</key>
	<true/>
	<key>NSSupportsSuddenTermination</key>
	<true/>
</dict>
</plist>
endef
export INFO_PLIST

.PHONY: build app dmg install clean version bump-patch bump-minor bump-major release-patch release-minor release-major

build:
	swift build -c release

app: build
	@echo "Creating app bundle..."
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp "$(BUILD_DIR)/$(APP_NAME)" "$(APP_BUNDLE)/Contents/MacOS/"
	@echo "$$INFO_PLIST" > "$(APP_BUNDLE)/Contents/Info.plist"
	@echo -n "APPL????" > "$(APP_BUNDLE)/Contents/PkgInfo"
	@if [ -f "Resources/AppIcon.icns" ]; then \
		cp "Resources/AppIcon.icns" "$(APP_BUNDLE)/Contents/Resources/"; \
		echo "Added app icon"; \
	fi
	@echo ""
	@echo "Built $(APP_BUNDLE) (v$(VERSION))"
	@echo "To install: make install"
	@echo "To run: open $(APP_BUNDLE)"

dmg: app
	@echo "Creating DMG installer..."
	@rm -rf dmg_contents
	@mkdir -p dmg_contents
	@cp -R "$(APP_BUNDLE)" dmg_contents/
	@ln -s /Applications dmg_contents/Applications
	@rm -f "$(DMG_NAME).dmg"
	hdiutil create -volname "$(APP_NAME)" -srcfolder dmg_contents -ov -format UDZO "$(DMG_NAME).dmg"
	@rm -rf dmg_contents
	@echo ""
	@echo "Created $(DMG_NAME).dmg (v$(VERSION))"

install: app
	cp -R "$(APP_BUNDLE)" /Applications/
	@echo "Installed $(APP_BUNDLE) to /Applications"

clean:
	@rm -rf .build
	@rm -rf $(APP_NAME).app
	@rm -rf Zelerk.app
	@rm -f $(APP_NAME)-Installer.dmg
	@rm -f Zelerk-Installer.dmg
	@rm -rf dmg_contents
	@echo "Clean complete"

version:
	@echo $(VERSION)

bump-patch:
	@NEW_VERSION="$(VERSION_MAJOR).$(VERSION_MINOR).$(shell echo $$(($(VERSION_PATCH) + 1)))"; \
	sed -i '' "s/^VERSION     := .*/VERSION     := $$NEW_VERSION/" Makefile; \
	echo "Bumped version to $$NEW_VERSION"

bump-minor:
	@NEW_VERSION="$(VERSION_MAJOR).$(shell echo $$(($(VERSION_MINOR) + 1))).0"; \
	sed -i '' "s/^VERSION     := .*/VERSION     := $$NEW_VERSION/" Makefile; \
	echo "Bumped version to $$NEW_VERSION"

bump-major:
	@NEW_VERSION="$(shell echo $$(($(VERSION_MAJOR) + 1))).0.0"; \
	sed -i '' "s/^VERSION     := .*/VERSION     := $$NEW_VERSION/" Makefile; \
	echo "Bumped version to $$NEW_VERSION"

release-patch: bump-patch
	@VERSION=$$(grep '^VERSION' Makefile | head -1 | awk '{print $$3}'); \
	git add Makefile; \
	git commit -S -m "Release v$$VERSION"; \
	git tag -s "v$$VERSION" -m "Release v$$VERSION"; \
	echo ""; \
	echo "Created release v$$VERSION"; \
	echo "Run 'git push && git push --tags' to publish"

release-minor: bump-minor
	@VERSION=$$(grep '^VERSION' Makefile | head -1 | awk '{print $$3}'); \
	git add Makefile; \
	git commit -S -m "Release v$$VERSION"; \
	git tag -s "v$$VERSION" -m "Release v$$VERSION"; \
	echo ""; \
	echo "Created release v$$VERSION"; \
	echo "Run 'git push && git push --tags' to publish"

release-major: bump-major
	@VERSION=$$(grep '^VERSION' Makefile | head -1 | awk '{print $$3}'); \
	git add Makefile; \
	git commit -S -m "Release v$$VERSION"; \
	git tag -s "v$$VERSION" -m "Release v$$VERSION"; \
	echo ""; \
	echo "Created release v$$VERSION"; \
	echo "Run 'git push && git push --tags' to publish"

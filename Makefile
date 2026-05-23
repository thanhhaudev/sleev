# sleev — developer Makefile
#
# Convenience wrapper around xcodegen + xcodebuild + swiftlint/swiftformat.
# All targets run from the repo root and assume tooling installed via:
#   brew install xcodegen swiftlint swiftformat

SCHEME := Sleev
CONFIG := Debug
DESTINATION := platform=macOS
APP_NAME := Sleev.app
BUILD_PATTERN := $(HOME)/Library/Developer/Xcode/DerivedData/Sleev-*/Build/Products/$(CONFIG)
APP := $(shell find $(BUILD_PATTERN) -name $(APP_NAME) -type d 2>/dev/null | head -1)

.PHONY: help generate build test lint format lint-fix app-icon \
        preview-onboarding preview-statusbar \
        install uninstall run clean ci pr-checks dmg all

help:
	@echo "sleev — developer targets"
	@echo ""
	@echo "  make generate            xcodegen generate (produces Sleev.xcodeproj)"
	@echo "  make build               xcodebuild build (Debug)"
	@echo "  make test                xcodebuild test (3 unit tests)"
	@echo "  make lint                swiftlint --strict + swiftformat --lint"
	@echo "  make format              swiftformat (in-place rewrites)"
	@echo "  make app-icon            regenerate the app icon assets"
	@echo "  make ci                  generate + lint + build + test (mirrors GitHub Actions)"
	@echo "  make dmg                 archive Release + package build/Sleev-<version>.dmg"
	@echo ""
	@echo "  make preview-onboarding  launch Sleev.app --preview-onboarding"
	@echo "  make preview-statusbar   launch Sleev.app --preview-statusbar"
	@echo "  make run                 launch Sleev.app (real flow — needs install)"
	@echo ""
	@echo "  make install             copy build product to /Applications/Sleev.app"
	@echo "  make uninstall           remove /Applications/Sleev.app + bootout launchd agent"
	@echo "  make clean               remove DerivedData and Sleev.xcodeproj"
	@echo ""
	@echo "  make pr-checks           gh pr checks 1 (status of open PR)"

generate:
	xcodegen generate

build: generate
	xcodebuild -scheme $(SCHEME) -configuration $(CONFIG) -destination '$(DESTINATION)' -allowProvisioningUpdates build

test: generate
	xcodebuild -scheme $(SCHEME) -configuration $(CONFIG) -destination '$(DESTINATION)' -allowProvisioningUpdates test

lint:
	swiftlint --strict
	swiftformat --lint .

format:
	swiftformat .

app-icon:
	swift Tools/generate-app-icon.swift

ci: lint generate build test
	@echo "✓ Full CI pipeline passed locally"

# Package a distributable disk image from a Release archive.
# Not notarized — the README documents the first-launch Gatekeeper bypass.
dmg: generate
	@set -e; \
	VERSION=$$(grep 'MARKETING_VERSION:' project.yml | head -1 | sed -E 's/.*"([^"]+)".*/\1/'); \
	echo "Packaging sleev $$VERSION..."; \
	rm -rf build/Sleev.xcarchive build/dmg-staging "build/Sleev-$$VERSION.dmg"; \
	mkdir -p build/dmg-staging; \
	xcodebuild archive \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination 'generic/platform=macOS' \
		-archivePath build/Sleev.xcarchive \
		-allowProvisioningUpdates; \
	cp -R "build/Sleev.xcarchive/Products/Applications/$(APP_NAME)" build/dmg-staging/; \
	echo "Verifying code signature structure..."; \
	codesign --verify --deep --strict --verbose=2 "build/dmg-staging/$(APP_NAME)"; \
	ln -s /Applications build/dmg-staging/Applications; \
	hdiutil create -volname "sleev" -srcfolder build/dmg-staging -ov -format UDZO "build/Sleev-$$VERSION.dmg"; \
	rm -rf build/dmg-staging build/Sleev.xcarchive; \
	echo "✓ build/Sleev-$$VERSION.dmg"

# Preview modes — run the freshly built binary directly (no install needed).
# Kills any existing Sleev preview process first so you don't end up with
# duplicate menubar items.
preview-onboarding: build
	@pkill -x Sleev 2>/dev/null || true
	@APP=$$(find $(BUILD_PATTERN) -name $(APP_NAME) -type d | head -1); \
	echo "Launching $$APP/Contents/MacOS/Sleev --preview-onboarding"; \
	"$$APP/Contents/MacOS/Sleev" --preview-onboarding

preview-statusbar: build
	@pkill -x Sleev 2>/dev/null || true
	@APP=$$(find $(BUILD_PATTERN) -name $(APP_NAME) -type d | head -1); \
	echo "Launching $$APP/Contents/MacOS/Sleev --preview-statusbar"; \
	"$$APP/Contents/MacOS/Sleev" --preview-statusbar

# Real flow — needs the app installed in /Applications because SMAppService.agent
# only honors plists embedded in apps living in a launchd-trusted location.
run: install
	open /Applications/$(APP_NAME)

install: build
	@APP=$$(find $(BUILD_PATTERN) -name $(APP_NAME) -type d | head -1); \
	echo "Installing $$APP -> /Applications/$(APP_NAME)"; \
	launchctl bootout gui/$$(id -u)/com.thanhhaudev.sleev.Sleev.Agent 2>/dev/null || true; \
	pkill -x Sleev 2>/dev/null || true; \
	pkill -x SleevAgent 2>/dev/null || true; \
	rm -rf /Applications/$(APP_NAME); \
	cp -R "$$APP" /Applications/$(APP_NAME)

uninstall:
	launchctl bootout gui/$$(id -u)/com.thanhhaudev.sleev.Sleev.Agent 2>/dev/null || true
	pkill -x Sleev 2>/dev/null || true
	pkill -x SleevAgent 2>/dev/null || true
	rm -rf /Applications/$(APP_NAME)

clean:
	rm -rf Sleev.xcodeproj
	rm -rf $(HOME)/Library/Developer/Xcode/DerivedData/Sleev-*

pr-checks:
	gh pr checks 1

all: ci

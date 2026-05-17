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

.PHONY: help generate build test lint format lint-fix \
        preview-onboarding preview-statusbar \
        install uninstall run clean ci pr-checks all

help:
	@echo "sleev — developer targets"
	@echo ""
	@echo "  make generate            xcodegen generate (produces Sleev.xcodeproj)"
	@echo "  make build               xcodebuild build (Debug)"
	@echo "  make test                xcodebuild test (3 unit tests)"
	@echo "  make lint                swiftlint --strict + swiftformat --lint"
	@echo "  make format              swiftformat (in-place rewrites)"
	@echo "  make ci                  generate + lint + build + test (mirrors GitHub Actions)"
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
	xcodebuild -scheme $(SCHEME) -configuration $(CONFIG) -destination '$(DESTINATION)' build

test: generate
	xcodebuild -scheme $(SCHEME) -configuration $(CONFIG) -destination '$(DESTINATION)' test

lint:
	swiftlint --strict
	swiftformat --lint .

format:
	swiftformat .

ci: lint generate build test
	@echo "✓ Full CI pipeline passed locally"

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
	launchctl bootout gui/$$(id -u)/dev.sleev.Sleev.Agent 2>/dev/null || true; \
	pkill -x Sleev 2>/dev/null || true; \
	pkill -x SleevAgent 2>/dev/null || true; \
	rm -rf /Applications/$(APP_NAME); \
	cp -R "$$APP" /Applications/$(APP_NAME)

uninstall:
	launchctl bootout gui/$$(id -u)/dev.sleev.Sleev.Agent 2>/dev/null || true
	pkill -x Sleev 2>/dev/null || true
	pkill -x SleevAgent 2>/dev/null || true
	rm -rf /Applications/$(APP_NAME)

clean:
	rm -rf Sleev.xcodeproj
	rm -rf $(HOME)/Library/Developer/Xcode/DerivedData/Sleev-*

pr-checks:
	gh pr checks 1

all: ci

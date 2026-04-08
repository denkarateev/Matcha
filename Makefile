backend-setup:
	cd backend && python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'

backend-test:
	cd backend && . .venv/bin/activate && pytest

backend-run:
	cd backend && . .venv/bin/activate && uvicorn app.main:app --reload

ios-project:
	cd ios && xcodegen generate

ios-build:
	cd ios && xcodegen generate && xcodebuild -project MATCHA.xcodeproj -scheme MATCHA -destination 'generic/platform=iOS Simulator' build

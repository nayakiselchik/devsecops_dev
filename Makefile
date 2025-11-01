.PHONY: install build clean sbom scan sign

APP=41_scan_stream_default.py
DIST_DIR=dist
ART_DIR=artifacts

install:
	pip install -r requirements.txt

build:
	@echo "Installing PyInstaller..."
	pip install pyinstaller >/dev/null 2>&1
	@echo "Creating directories..."
	mkdir -p $(DIST_DIR) $(ART_DIR)
	@echo "Building binary..."
	pyinstaller --onefile $(APP) --name 41_scan_stream_default
	@echo "Creating artifact archive..."
	zip -j $(ART_DIR)/artifact.zip $(APP) dist/41_scan_stream_default* || true
	@echo "Build complete!"

sbom:
	@echo "Generating SBOM..."
	which syft >/dev/null && syft packages dir:. -o spdx-json > sbom.spdx.json || echo "Syft not installed, skipping SPDX SBOM"
	which syft >/dev/null && syft packages dir:. -o cyclonedx-json > sbom.cyclonedx.json || echo "Syft not installed, skipping CycloneDX SBOM"

scan:
	@echo "Scanning for vulnerabilities..."
	which grype >/dev/null && grype sbom:./sbom.spdx.json -o json > vulnerabilities.json || echo "Grype not installed, skipping scan"

sign:
	@echo "Signing artifacts..."
	COSIGN_EXPERIMENTAL=1 cosign sign-blob --yes --output-signature artifacts/artifact.zip.sig --output-certificate artifacts/artifact.zip.pem artifacts/artifact.zip || echo "Cosign not installed, skipping signing"

clean:
	@echo "Cleaning build artifacts..."
	rm -rf build/ dist/ *.spec __pycache__/ $(ART_DIR)/ sbom*.json vulnerabilities.json

run:
	python $(APP)

help:
	@echo "Available targets:"
	@echo "  make install  - Install Python dependencies"
	@echo "  make build    - Build pseudo-binary with PyInstaller"
	@echo "  make sbom     - Generate SBOM (requires syft)"
	@echo "  make scan     - Scan SBOM for vulnerabilities (requires grype)"
	@echo "  make sign     - Sign artifacts with Cosign"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make run      - Run the Python script"

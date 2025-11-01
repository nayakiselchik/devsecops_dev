.PHONY: install build clean sbom scan sign

APP=41_scan_stream_default.py
DIST_DIR=dist
ART_DIR=artifacts

install:
	pip install -r requirements.txt

fetch:
	bash fetch_source.sh

build: fetch
	pip install pyinstaller >/dev/null
	mkdir -p $(DIST_DIR) $(ART_DIR)
	pyinstaller --onefile $(APP) --name scan_stream
	# Зібрати артефакт коду (джерела + бінарник)
	zip -j $(ART_DIR)/artifact.zip $(APP) dist/scan_stream* || true

sbom:
	# Локально: якщо syft встановлено, згенерувати SBOM
	which syft >/dev/null && syft packages dir:. -o spdx-json > sbom.spdx.json || echo "Install syft to generate SBOM"
	which syft >/dev/null && syft packages dir:. -o cyclonedx-json > sbom.cyclonedx.json || true

scan:
	# Локально: якщо grype встановлено, просканувати SBOM
	which grype >/dev/null && grype sbom:./sbom.spdx.json -o json > vulnerabilities.json || echo "Install grype to scan SBOM"

sign:
	# Локально: якщо cosign встановлено, підписати артефакт
	COSIGN_EXPERIMENTAL=1 cosign sign-blob --yes --output-signature artifacts/artifact.zip.sig --output-certificate artifacts/artifact.zip.pem artifacts/artifact.zip || echo "Install cosign to sign"

clean:
	rm -rf build/ dist/ *.spec __pycache__/ $(ART_DIR)/ sbom*.json vulnerabilities.json

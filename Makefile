name: Build, Sign and Release

on:
  push:
    branches:
      - main
      - stage
      - dev
    tags:
      - 'v*.*.*'
  pull_request:
    branches: [ main, stage ]

permissions:
  contents: write
  packages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.10'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pyinstaller cyclonedx-bom

    - name: Build pseudo-binary
      run: make build

    - name: Generate SBOM
      run: |
        cyclonedx-py requirements -o sbom.json
        echo "SBOM generated successfully!"
        ls -lh sbom.json

    - name: Install Grype
      run: |
        curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

    - name: Scan SBOM with Grype
      run: |
        echo "Scanning SBOM for vulnerabilities..."
        grype sbom:sbom.json -o table || true

    - name: Install Cosign
      if: startsWith(github.ref, 'refs/tags/')
      uses: sigstore/cosign-installer@v3.4.0

    - name: Sign artifacts with Cosign
      if: startsWith(github.ref, 'refs/tags/')
      run: |
        echo "Signing artifacts with Cosign..."
        cosign sign-blob --yes --bundle dist/41_scan_stream_default.cosign-bundle dist/41_scan_stream_default
        cosign sign-blob --yes --bundle sbom.cosign-bundle sbom.json
        echo "Signing complete!"

    - name: Create checksums
      if: startsWith(github.ref, 'refs/tags/')
      run: |
        echo "Creating checksums..."
        cd dist
        sha256sum 41_scan_stream_default > checksums.txt
        cd ..
        sha256sum sbom.json >> dist/checksums.txt
        cat dist/checksums.txt

    - name: Upload artifacts
      uses: actions/upload-artifact@v4
      with:
        name: release-artifacts
        path: |
          dist/
          sbom.json
          *.cosign-bundle

  release:
    needs: build
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')
    permissions:
      contents: write

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Download artifacts
      uses: actions/download-artifact@v4
      with:
        name: release-artifacts
        path: ./artifacts

    - name: Display downloaded artifacts
      run: |
        echo "Downloaded artifacts:"
        ls -R ./artifacts

    - name: Create Release
      uses: softprops/action-gh-release@v1
      with:
        tag_name: ${{ github.ref_name }}
        files: |
          artifacts/dist/41_scan_stream_default
          artifacts/dist/checksums.txt
          artifacts/sbom.json
          artifacts/*.cosign-bundle
        body: |
          Release ${{ github.ref_name }}

          Artifacts included:
          - Binary: 41_scan_stream_default
          - SBOM: sbom.json (CycloneDX format)
          - Signatures: Cosign signature bundles
          - Checksums: SHA256 checksums

          Verification:
          - Verify checksums: sha256sum -c checksums.txt
          - Verify Cosign signature with the .cosign-bundle files
        generate_release_notes: true

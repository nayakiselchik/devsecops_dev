# technical specification: repository structure and implementation Guide

## overview
create a secure Python application repository with CI/CD pipeline, branch protection, and security scanning.

**Source Code:** `41_scan_stream_default.py` from `https://github.com/savostyanenko/example_of_vulnerable_code_2`

---

## 1. final repository structure

```
repository-root/
├── 41_scan_stream_default.py
├── README.md
├── requirements.txt
├── Makefile
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── SBOM files
└── Cosign signatures
```

---

## 2. required files

### 2.1 main application

**File:** `41_scan_stream_default.py`

**Method:** Copy from source repository
```bash
curl -O https://raw.githubusercontent.com/savostyanenko/example_of_vulnerable_code_2/main/41_scan_stream_default.py
```

---

### 2.2 dependencies

**File:** `requirements.txt`

**Purpose:** List of all Python libraries used in the script. Critical for reproducible builds.

**Tool:** `pip freeze`

**Method:**
```bash
python -m venv venv
source venv/bin/activate
pip install <required_packages>
pip freeze > requirements.txt
```

**Important:** Only include dependencies actually used in the script. Review and remove unnecessary packages.

---

### 2.3 docs

**File:** `README.md`

**Must Include:**
1. Project description
2. Installation instructions
3. Usage instructions
4. Build instructions (Makefile)
5. Branch strategy (dev, stage, main)
6. Merge request workflow
7. Security information (Cosign, SBOM)
8. Current version

**Method:** Create manually using Markdown

---

### 2.4 build script

**File:** `Makefile`

**Purpose:** Automate building "pseudo-binary" package

**Must Include:**
- `install` target: Install dependencies
- `build` target: Create distributable package
- `clean` target: Remove build artifacts

**Example:**
```makefile
.PHONY: install build clean

install:

	pip install -r requirements.txt

build:
	pyinstaller --onefile 41_scan_stream_default.py

clean:
	rm -rf build/ dist/ *.spec __pycache__/
```

---

### 2.5 CI/CD pipeline

**File:** `.github/workflows/ci-cd.yml`

**Must Include:**
1. Trigger on merge to `main`
2. Build using Makefile
3. Scorecard security scan
4. SBOM generation (Syft)
5. SBOM vulnerability scan (Grype)
6. Artifact signing (Cosign)
7. Release creation (v1.0.0)
8. Artifact upload

---

## 3. repository configuration

### 3.1 users

**Requirement:** 4 users total
- **1 Maintainer:** Can push to `main` branch
- **3 Contributors:** Can only create merge requests

**Method:** Settings → Collaborators → Add users with appropriate permissions

---

### 3.2 branches

**Three branches required:**

1. **`main`** - Production code
   - Protected: Requires pull request reviews
   - Only 1 user can push directly
   - Status checks must pass

2. **`stage`** - Pre-production testing
   - Receives code from `dev` for final testing

3. **`dev`** - Active development
   - All feature development happens here

**Branch Protection for `main`:**
- Require pull request reviews before merging
- Require status checks to pass
- Require branches to be up to date
- Restrict push access to 1 designated user

**Create branches:**
```bash
git checkout -b dev
git push origin dev

git checkout -b stage
git push origin stage

git checkout -b main
git push origin main
```

---

### 3.3 merge request workflow

**Rule:** Code reaches `main` ONLY through merge requests

**Flow:**
1. Feature branch → `dev` (via merge request)
2. `dev` → `stage` (via merge request)
3. `stage` → `main` (via merge request)
4. CI/CD triggers on merge to `main`

---

## 4. security tools

### 4.1 cosign - artifact signing

**Purpose:** Cryptographically sign build artifacts

**Installation:**
```bash
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
mv cosign-linux-amd64 /usr/local/bin/cosign
chmod +x /usr/local/bin/cosign
```

**Usage:**
```bash
cosign generate-key-pair
cosign sign-blob --key cosign.key artifact.zip > artifact.sig
cosign verify-blob --key cosign.pub --signature artifact.sig artifact.zip
```

---

### 4.2 SBOM generation

**Purpose:** Create Software Bill of Materials

**Installation:**
```bash
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
```

**Usage:**
```bash
syft packages dir:. -o spdx-json > sbom.spdx.json
syft packages dir:. -o cyclonedx-json > sbom.cyclonedx.json
```

---

### 4.3 grype - vulnerability scanning

**Purpose:** Scan SBOM for security vulnerabilities

**Installation:**
```bash
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

**Usage:**
```bash
grype sbom:./sbom.spdx.json
grype sbom:./sbom.spdx.json -o json > vulnerabilities.json
```

---

### 4.4 scorecard - security

**Purpose:** Assess repository security best practices

**Installation:**
```bash
go install github.com/ossf/scorecard/v4/cmd/scorecard@latest
```

**Usage:**
```bash
scorecard --repo=github.com/<username>/<repo-name>
scorecard --repo=github.com/<username>/<repo-name> --format=json > scorecard-results.json
```

---

## 5. release process

### Version 1.0.0 Release

**Release Must Contain:**
1. Built artifact (pseudo-binary)
2. Cosign signature file
3. SBOM file
4. Grype scan results
5. Release notes

**Method:**
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

GitHub Actions will automatically build, sign, and create the release.

---

## 6. development workflow

1. **Setup:** Create repo, add users, create branches, configure protection
2. **Dependencies:** Generate `requirements.txt` using `pip freeze`
3. **Documentation:** Create `README.md` with algorithm description
4. **Build:** Create `Makefile` for build automation
5. **CI/CD:** Configure GitHub Actions workflow
6. **Security:** Run Scorecard and Grype scans
7. **Release:** Merge to `main` triggers automated release v1.0.0

---


## 7. key Rules

**For Developers:**
- Never commit directly to `main`
- Always use pull requests
- Test locally before pushing
- Keep dependencies minimal

**For DevOps:**
- Store Cosign keys in GitHub Secrets
- Monitor CI/CD pipeline
- Ensure all security checks pass


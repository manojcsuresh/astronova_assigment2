# Security Incident Report: Private Key Committed to Repository

## What Happened

The file `astronova-deploy-key.pem` (an SSH private key used for deploying to the EC2 instance) was accidentally committed to the Git repository in the initial commit (`ee2fa00`). This key was part of the working directory and was included when running `git add .` without a proper `.gitignore` in place.

## Severity

**HIGH** — Exposed SSH private keys can allow unauthorized access to the deployment server. Even after deletion via a new commit, the key remains in Git history and can be recovered by anyone with repository access.

## Remediation Steps Taken

1. **Key Revoked:** The compromised key pair has been revoked/rotated in the AWS console. The old key can no longer be used to access any EC2 instances.
2. **History Purged:** The file was purged from the entire Git history using `git filter-repo` (not just deleted in a new commit), ensuring it cannot be recovered from any prior commit.
3. **`.gitignore` Added:** A comprehensive `.gitignore` now excludes:
   - All private key formats (`*.pem`, `*.key`, `*.p12`, etc.)
   - Environment files (`.env`, `*.env`)
   - Python cache (`__pycache__/`)
   - Build artifacts and IDE files
4. **Force Push:** The rewritten history was force-pushed to the remote repository.

## Root Cause

- No `.gitignore` was configured before the initial commit
- `git add .` was used without reviewing staged files
- The private key was stored in the project directory rather than `~/.ssh/`

## Prevention Measures for Production Pipelines

| Measure | Description |
|---------|-------------|
| **Pre-commit hooks** | Use tools like `pre-commit` with `detect-secrets` or `gitleaks` to scan for credentials before every commit |
| **`.gitignore` first** | Always create `.gitignore` before the first commit in any new repository |
| **Key management** | Store SSH keys in `~/.ssh/` or use a secrets manager (AWS Secrets Manager, HashiCorp Vault). Never place keys in project directories |
| **CI/CD secret scanning** | Enable GitHub's secret scanning or integrate `trufflehog`/`gitleaks` into the CI pipeline to catch leaked secrets |
| **Least privilege keys** | Use ephemeral, scoped credentials (e.g., AWS SSM Session Manager) instead of long-lived SSH keys |
| **Repository templates** | Maintain a standard `.gitignore` template for all new projects to prevent accidental inclusion of sensitive files |
| **Code review gates** | Require PR reviews before merging — reviewers should flag any credentials or keys in diffs |

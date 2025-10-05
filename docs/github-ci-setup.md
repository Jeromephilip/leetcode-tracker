# GitHub CI/CD Setup Guide

This guide explains how to set up comprehensive CI/CD workflows for your Rails application with GitHub Actions and branch protection rules.

## Current CI Workflow Features

The enhanced CI workflow (`/.github/workflows/ci.yml`) includes:

### 🔒 Security Checks
- **Brakeman Security Scan**: Scans for common Rails security vulnerabilities
- **Dependency Audit**: Checks for vulnerable dependencies using `bundle audit`
- **Outdated Dependencies**: Identifies outdated gems using `bundle outdated`

### 🎨 Code Quality Checks
- **RuboCop Linting**: Enforces consistent Ruby code style using Rails Omakase configuration
- **Style Enforcement**: Fails on style violations to maintain code quality

### 🧪 Testing
- **Full Test Suite**: Runs all Rails tests with PostgreSQL database
- **Database Setup**: Automatically prepares test database
- **Parallel Testing**: Uses Rails' built-in parallel testing capabilities

### 🏗️ Build Verification
- **Asset Precompilation**: Verifies production assets can be built
- **Application Boot**: Ensures the application can start successfully

### ⚡ Performance Optimizations
- **Concurrency Control**: Cancels previous runs when new commits are pushed
- **Caching**: Uses Bundler cache for faster dependency installation
- **Parallel Jobs**: Runs security, lint, and dependency checks in parallel

## Setting Up Branch Protection Rules

### 1. Navigate to Repository Settings
1. Go to your GitHub repository
2. Click on **Settings** tab
3. Click on **Branches** in the left sidebar

### 2. Add Branch Protection Rule for `main`
1. Click **Add rule**
2. In **Branch name pattern**, enter: `main`
3. Configure the following settings:

#### Required Status Checks
- ✅ **Require status checks to pass before merging**
- ✅ **Require branches to be up to date before merging**
- Select these required status checks:
  - `Security Scan`
  - `Lint & Style Check`
  - `Dependency Check`
  - `Test Suite`
  - `Build Check`
  - `CI Success`

#### Additional Protection Rules
- ✅ **Require pull request reviews before merging**
  - Set **Required number of reviewers**: 1 (or more based on team size)
  - ✅ **Dismiss stale PR approvals when new commits are pushed**
  - ✅ **Require review from code owners** (if you have a CODEOWNERS file)

- ✅ **Require conversation resolution before merging**

- ✅ **Require signed commits** (optional but recommended)

- ✅ **Require linear history** (optional, prevents merge commits)

- ✅ **Include administrators** (applies rules to admins too)

- ✅ **Restrict pushes that create files** (optional)

### 3. Add Branch Protection Rule for `develop` (if using GitFlow)
Repeat the same process for the `develop` branch with similar settings.

## Required Status Checks Explained

| Check | Purpose | Failure Impact |
|-------|---------|----------------|
| **Security Scan** | Detects security vulnerabilities | Blocks merge if vulnerabilities found |
| **Lint & Style Check** | Enforces code style consistency | Blocks merge if style violations exist |
| **Dependency Check** | Ensures dependencies are secure and up-to-date | Blocks merge if vulnerabilities or outdated deps |
| **Test Suite** | Validates all tests pass | Blocks merge if any test fails |
| **Build Check** | Verifies application can build and boot | Blocks merge if build fails |
| **CI Success** | Overall status check | Blocks merge if any previous check failed |

## Workflow Triggers

The CI workflow runs on:
- **Pull Requests** targeting `main` or `develop` branches
- **Pushes** to `main` or `develop` branches
- **Concurrency Control**: Automatically cancels previous runs when new commits are pushed

## Local Development Workflow

### Before Creating a PR
1. **Run linting locally**:
   ```bash
   bin/rubocop
   ```

2. **Run security scan**:
   ```bash
   bin/brakeman
   ```

3. **Check dependencies**:
   ```bash
   bundle audit
   bundle outdated
   ```

4. **Run tests**:
   ```bash
   bin/rails test
   ```

5. **Verify build**:
   ```bash
   bin/rails assets:precompile RAILS_ENV=production
   ```

### Creating a Pull Request
1. Create a feature branch from `main` or `develop`
2. Make your changes
3. Run local checks (see above)
4. Push your branch
5. Create a pull request using the provided template
6. Wait for all CI checks to pass
7. Request code review
8. Merge after approval and passing checks

## Troubleshooting Common Issues

### CI Failures

#### Security Scan Failures
- Review Brakeman warnings and fix security issues
- Update vulnerable dependencies
- Consider false positives and add exceptions if needed

#### Linting Failures
- Run `bin/rubocop -a` to auto-fix issues
- Review and fix remaining violations manually
- Update `.rubocop.yml` if rule changes are needed

#### Test Failures
- Run tests locally to reproduce issues
- Fix failing tests or update test expectations
- Ensure test database is properly set up

#### Dependency Check Failures
- Update vulnerable dependencies: `bundle update <gem-name>`
- Review outdated dependencies and update as needed
- Consider security implications of updates

### Branch Protection Issues

#### "Required status checks are pending"
- Wait for all CI checks to complete
- Ensure all required checks are enabled in branch protection rules
- Check that workflow files are in the correct location

#### "Required review from code owners"
- Add a `CODEOWNERS` file to specify code owners
- Ensure code owners are available for review
- Consider adding more reviewers if needed

## Additional Recommendations

### 1. Add Code Coverage
Consider adding code coverage reporting:
```yaml
- name: Generate coverage report
  run: |
    gem install simplecov
    COVERAGE=true bin/rails test
```

### 2. Add Performance Testing
For performance-critical applications:
```yaml
- name: Performance tests
  run: bin/rails test:system
```

### 3. Add Database Migrations Check
```yaml
- name: Check for pending migrations
  run: bin/rails db:migrate:status
```

### 4. Add Environment-Specific Checks
Consider adding environment-specific validation for staging/production configurations.

## Monitoring and Maintenance

### Regular Tasks
- Review and update dependencies monthly
- Monitor CI performance and optimize as needed
- Update GitHub Actions versions quarterly
- Review and update branch protection rules as team grows

### Metrics to Track
- CI run times
- Failure rates by check type
- Time to merge PRs
- Code review coverage

This setup ensures code quality, security, and reliability while maintaining efficient development workflows.

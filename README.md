# GitHub Project Builder - Test Data and Script Guide

This guide explains how to use the `create-github-project.sh` script to automatically create a GitHub repository, project, and import test issues with custom fields from a CSV file.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Test Data Description](#test-data-description)
- [CSV File Format](#csv-file-format)
- [Running the Script](#running-the-script)
- [Troubleshooting](#troubleshooting)
- [How It Works](#how-it-works)
- [Field Type Examples](#field-type-examples)

## Overview

This script demonstrates GitHub Projects v2 capabilities by:
- Creating a new GitHub repository
- Setting up a GitHub Project with 5 different custom field types
- Importing 30 test issues from a CSV file
- Automatically mapping CSV columns to project fields

The script showcases all major GitHub Project field types: Single Select, Number, Date, and Text fields.

## Prerequisites

### Required Software
1. **GitHub CLI (gh)** - Install from https://cli.github.com/
2. **Python 3** - Required for CSV parsing and API calls
3. **Bash shell** - WSL on Windows, or native Linux/Mac terminal

### GitHub Setup
1. **Authentication**: Authenticate GitHub CLI with proper scopes:
   ```bash
   gh auth login
   ```
   Select the following permissions when prompted:
   - `repo` (Full control of repositories)
   - `project` (Full control of projects)
   - `read:org` (Read org and team membership - if using organization projects)

2. **Account Type**: Ensure you have either:
   - A personal GitHub account (for user-level projects)
   - Write access to an organization (for org-level projects)

## Configuration

Before running the script, update these variables at the top of `create-github-project.sh`:

```bash
# Configuration Variables (modify these as needed)
REPO_NAME="test-project-demo"           # Repository name (must be unique)
PROJECT_NAME="Project Management Board"  # Project display name
CSV_FILE="test-issues.csv"              # Path to CSV file with test data
PROJECT_SCOPE="user"                    # "user" for personal, "org" for organization
ORG_NAME=""                             # Organization name (required if PROJECT_SCOPE="org")
```

### Configuration Examples

**Personal Project:**
```bash
PROJECT_SCOPE="user"
ORG_NAME=""  # Leave empty for personal projects
```

**Organization Project:**
```bash
PROJECT_SCOPE="org"
ORG_NAME="my-organization"  # Your GitHub organization name
```

## Test Data Description

The provided test data (`test-issues.csv`) contains 30 realistic software development issues covering various aspects of a typical project:

### Issue Categories
- **Authentication & Security** (6 issues): OAuth setup, security audits, permissions
- **Frontend Development** (6 issues): Dashboard, responsive design, UI/UX
- **Backend Development** (7 issues): API development, caching, error handling
- **Database & Infrastructure** (5 issues): Migrations, indexing, backups
- **DevOps & Testing** (6 issues): CI/CD, monitoring, load testing, test coverage

### Custom Fields Demonstrated

The test data includes 5 custom fields that showcase different GitHub Project field types:

1. **Priority** (Single Select)
   - Options: High, Medium, Low
   - Distribution: 11 High, 13 Medium, 6 Low priority issues

2. **Status** (Single Select)
   - Options: Todo, In Progress, Done, Blocked
   - Distribution: 21 Todo, 9 In Progress items

3. **EstimatedHours** (Number)
   - Range: 3-40 hours
   - Represents development effort estimation

4. **DueDate** (Date)
   - Range: August 28, 2025 to September 30, 2025
   - ISO format (YYYY-MM-DD)

5. **Team** (Single Select)
   - Options: Frontend, Backend, API, Database, Documentation, Security, DevOps, Testing
   - Maps issues to responsible teams

## CSV File Format

The CSV file (`test-issues.csv`) uses the following structure:

```csv
Title,Description,Priority,Status,EstimatedHours,DueDate,Team
```

### Example Rows:
```csv
"Setup authentication system","Implement OAuth2 authentication with social login providers","High","Todo",16,"2025-09-15","Backend"
"Create user dashboard","Design and implement main user dashboard with widgets","Medium","In Progress",24,"2025-09-10","Frontend"
"Database migration script","Create migration scripts for v2.0 database schema changes","High","Todo",8,"2025-09-05","Database"
```

### Column Specifications:
- **Title**: Issue title (text, max 256 characters recommended)
- **Description**: Detailed issue description (text, can be multiline)
- **Priority**: Must be one of: `High`, `Medium`, `Low`
- **Status**: Must be one of: `Todo`, `In Progress`, `Done`, `Blocked`
- **EstimatedHours**: Numeric value (integer or decimal)
- **DueDate**: Date in ISO format `YYYY-MM-DD`
- **Team**: Must be one of: `Frontend`, `Backend`, `API`, `Database`, `Documentation`, `Security`, `DevOps`, `Testing`

## Running the Script

### Step 1: Prepare the Files

1. Save the test data CSV:
   ```bash
   # Create test-issues.csv with the provided content
   nano test-issues.csv
   # Paste the CSV content and save
   ```

2. Save the script:
   ```bash
   # Create the script file
   nano create-github-project.sh
   # Paste the script content and save
   ```

### Step 2: Make the Script Executable
```bash
chmod +x create-github-project.sh
```

### Step 3: Configure Variables
Edit the script to set your desired repository and project names:
```bash
nano create-github-project.sh
# Update REPO_NAME, PROJECT_NAME, and PROJECT_SCOPE as needed
```

### Step 4: Run the Script
```bash
./create-github-project.sh
```

### Expected Output
```
Starting GitHub Project Setup...
Repository: test-project-demo
Project: Project Management Board
Scope: user
Creating repository...
Creating project and importing issues...
Creating project: Project Management Board
Project created with number: 42
Creating field: Priority (SINGLE_SELECT)
Creating field: Status (SINGLE_SELECT)
Creating field: EstimatedHours (NUMBER)
Creating field: DueDate (DATE)
Creating field: Team (SINGLE_SELECT)
Importing issues...
Processing issue 1/30: Setup authentication system
Processing issue 2/30: Create user dashboard
...
✅ Successfully created project and imported 30 issues!
=========================================
Import complete.
=========================================
Project: https://github.com/users/yourusername/projects/42
Repository: https://github.com/yourusername/test-project-demo
=========================================
```

## Troubleshooting

### Common Issues and Solutions

#### 1. "GitHub CLI (gh) is not installed"
Install GitHub CLI:
```bash
# On Ubuntu/Debian/WSL:
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# On macOS:
brew install gh

# On Windows (native):
winget install --id GitHub.cli
```

#### 2. "Not authenticated with GitHub CLI"
Authenticate with GitHub:
```bash
gh auth login
# Follow the prompts to authenticate via browser or token
```

#### 3. "Repository already exists"
The script checks for existing repositories. Either:
- Delete the existing repository: `gh repo delete REPO_NAME --confirm`
- Choose a different `REPO_NAME` in the script configuration

#### 4. "Python 3 is not installed"
Install Python 3:
```bash
# On Ubuntu/Debian/WSL:
sudo apt-get update
sudo apt-get install python3

# On macOS:
brew install python3

# On Windows:
# Download from python.org or use:
winget install Python.Python.3
```

#### 5. "CSV file not found"
Ensure the CSV file exists and the path is correct:
```bash
# Check if file exists
ls -la test-issues.csv

# Verify the CSV_FILE variable in the script matches your file location
```

#### 6. "Permission denied" when running script
Make the script executable:
```bash
chmod +x create-github-project.sh
```

#### 7. Windows Line Endings Issue (WSL)
If you created the files in Windows, convert line endings:
```bash
# Install dos2unix if needed
sudo apt-get install dos2unix

# Convert the files
dos2unix create-github-project.sh
dos2unix test-issues.csv
```

### Debugging Tips

1. **Enable verbose output**: Add debugging to see each command:
   ```bash
   # Run with bash debugging
   bash -x create-github-project.sh
   ```

2. **Test with fewer issues**: Create a smaller CSV with 2-3 rows for testing:
   ```csv
   Title,Description,Priority,Status,EstimatedHours,DueDate,Team
   "Test Issue 1","Description 1","High","Todo",8,"2025-09-01","Backend"
   "Test Issue 2","Description 2","Low","Todo",4,"2025-09-02","Frontend"
   ```

3. **Check GitHub API status**: If experiencing errors, verify GitHub is operational:
   - Visit: https://www.githubstatus.com/

4. **Verify rate limits**: Check your API rate limit:
   ```bash
   gh api rate_limit
   ```

## How It Works

### Script Architecture

The script operates in three main phases:

#### Phase 1: Validation and Setup
1. Checks all prerequisites (gh CLI, Python 3, authentication)
2. Validates configuration variables
3. Verifies repository doesn't already exist
4. Creates the new repository

#### Phase 2: Project Creation (Python)
1. Creates a new GitHub Project v2
2. Dynamically creates custom fields based on CSV headers
3. Configures field types and options

#### Phase 3: Issue Import (Python)
1. Reads the CSV file
2. For each data row:
   - Creates an issue in the repository
   - Adds the issue to the project
   - Sets all custom field values
3. Applies rate limiting to avoid API limits

### Field Type Mapping

The script automatically creates appropriate field types:

| CSV Column | GitHub Field Type | Options/Format |
|------------|------------------|----------------|
| Priority | SINGLE_SELECT | High, Medium, Low |
| Status | SINGLE_SELECT | Todo, In Progress, Done, Blocked |
| EstimatedHours | NUMBER | Numeric values |
| DueDate | DATE | ISO date format |
| Team | SINGLE_SELECT | 8 team options |

### API Interactions

The script uses GitHub CLI commands that translate to GraphQL API calls:
- `gh repo create` - Creates repository via REST API
- `gh project create` - Creates project via GraphQL
- `gh project field-create` - Adds custom fields via GraphQL
- `gh issue create` - Creates issues via REST API
- `gh project item-add` - Links issues to project via GraphQL
- `gh project item-edit` - Sets field values via GraphQL

## Field Type Examples

### Single Select Fields
Used for: Priority, Status, Team
```python
create_custom_field(project_number, "Priority", "SINGLE_SELECT", ["High", "Medium", "Low"])
```

### Number Fields
Used for: EstimatedHours
```python
create_custom_field(project_number, "EstimatedHours", "NUMBER")
```

### Date Fields
Used for: DueDate
```python
create_custom_field(project_number, "DueDate", "DATE")
```

### Text Fields (not used in demo)
Could be added for free-form text:
```python
create_custom_field(project_number, "Notes", "TEXT")
```

## Advanced Usage

### Customizing Field Types

To add more field types, modify the `field_definitions` dictionary in the Python section:

```python
field_definitions = {
    'YourFieldName': {
        'type': 'FIELD_TYPE',  # SINGLE_SELECT, NUMBER, DATE, TEXT
        'options': ['Option1', 'Option2']  # Only for SINGLE_SELECT
    }
}
```

### Changing Repository Settings

Modify the repository creation command:
```bash
# For private repository:
gh repo create "$REPO_NAME" --private --description "Your description"

# With .gitignore template:
gh repo create "$REPO_NAME" --public --gitignore Python --description "Your description"
```

### Bulk Import Considerations

For large imports (>100 issues):
- Increase sleep timers to avoid rate limits
- Consider batching imports
- Monitor API rate limits with `gh api rate_limit`

## Additional Notes

- **Idempotency**: The script is not idempotent - running it twice will fail as the repository will already exist
- **Field Limitations**: GitHub Projects has limits on the number of custom fields (approx. 20)
- **Option Limits**: Single select fields can have up to 50 options
- **Project Visibility**: Projects inherit visibility from their scope (user/org)
- **Issue Order**: Issues are imported in CSV order but may appear differently in the project view

## Support

If you encounter issues:
1. Check the error message carefully - the script includes detailed error reporting
2. Verify all prerequisites are installed and up to date
3. Ensure your GitHub account has appropriate permissions
4. Check GitHub API status: https://www.githubstatus.com/
5. Review the GitHub CLI documentation: https://cli.github.com/manual/

## License

This script and test data are provided as examples for learning GitHub Projects automation.
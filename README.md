# GitHub Project Builder

A comprehensive Bash script with embedded Python for creating GitHub repositories, projects with custom fields, and importing issues from CSV files.

## Features

- **Repository Management**
  - Creates new GitHub repositories or uses existing ones
  - Supports both personal and organization repositories
  - Automatic conflict detection and resolution options

- **Project Management**
  - Creates GitHub Projects (v2) with custom fields
  - Detects and handles existing projects
  - Supports multiple field types (Single Select, Number, Date, Text)
  - Automatic field type detection and mapping

- **CSV Import**
  - Bulk import issues from CSV files
  - Maps CSV columns to GitHub Project custom fields
  - Preserves field relationships and data types
  - Handles special characters and formatting

- **Advanced Field Handling**
  - Automatic detection of field types even when API returns generic types
  - Proper handling of NUMBER and DATE fields with correct CLI flags
  - Single Select fields with predefined options
  - Field name conflict resolution (e.g., Status → WorkflowState)

## Prerequisites

1. **GitHub CLI (gh)**: Install from https://cli.github.com/
2. **Python 3**: Required for CSV processing and API interactions
3. **GitHub Authentication**: Run `gh auth login` before using the script

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/github-project-builder.git
cd github-project-builder
```

2. Make the script executable:
```bash
chmod +x create-github-project-v4.sh
```

## Configuration

Edit the configuration variables at the top of the script:

```bash
REPO_NAME="test-project-demo"           # Repository name
PROJECT_NAME="Project Management Board"  # Project name
CSV_FILE="test-issues.csv"              # Path to CSV file
PROJECT_SCOPE="user"                    # "user" or "org"
ORG_NAME=""                             # Required if PROJECT_SCOPE="org"
```

## CSV Format

Your CSV file should have the following structure:

```csv
Title,Description,Priority,Status,EstimatedHours,DueDate,Team
"API endpoint refactoring","Refactor REST API endpoints for better performance","High","Todo",16,2025-09-01,"Backend"
"Create user dashboard","Design and implement user dashboard","Medium","In Progress",24,2025-09-10,"Frontend"
```

### Supported Field Types

- **Title**: Issue title (required)
- **Description**: Issue description (required)
- **Priority**: Single select (High, Medium, Low)
- **Status**: Single select (Todo, In Progress, Done, Blocked) - mapped to WorkflowState
- **EstimatedHours**: Number field
- **DueDate**: Date field (YYYY-MM-DD format)
- **Team**: Single select (Frontend, Backend, API, Database, etc.)

## Usage

### Basic Usage (Personal Repository)

```bash
./create-github-project-v4.sh
```

### Organization Repository

```bash
# Edit the script to set:
PROJECT_SCOPE="org"
ORG_NAME="your-org-name"

./create-github-project-v4.sh
```

## Key Features Explained

### 1. Intelligent Conflict Resolution

The script detects existing repositories and projects, offering options to:
- Use existing resources
- Create new ones with different names
- Cancel the operation

### 2. Field Type Detection

The script includes advanced logic to detect field types even when GitHub's API returns generic types:

```python
# Known field type mappings for fallback
known_types = {
    'EstimatedHours': 'NUMBER',
    'DueDate': 'DATE',
    'Priority': 'SINGLE_SELECT',
    'WorkflowState': 'SINGLE_SELECT',
    'Team': 'SINGLE_SELECT'
}
```

### 3. Proper Field Updates

Different field types are handled with appropriate GitHub CLI flags:
- `--number` for NUMBER fields
- `--date` for DATE fields
- `--single-select-option-id` for SINGLE_SELECT fields
- `--text` for TEXT fields

### 4. Reserved Field Name Handling

The script automatically handles GitHub's reserved field names:
- Renames "Status" to "WorkflowState" to avoid conflicts
- Skips creation of built-in fields like Title and Description

### 5. Debug Mode

The script includes debug output for the first 2 issues to help troubleshoot field updates:

```python
debug_mode = (i <= 2)  # Debug first 2 issues
```

## Advanced Techniques

### GraphQL API Integration (Optional)

The script can be extended with GraphQL mutations for more reliable field updates:

```python
def update_field_via_graphql(project_id, item_id, field_id, value, field_type):
    """Update a field using GraphQL API directly."""
    # GraphQL mutation for NUMBER fields
    mutation = f'''
    mutation {{
      updateProjectV2ItemFieldValue(input: {{
        projectId: "{project_id}"
        itemId: "{item_id}"
        fieldId: "{field_id}"
        value: {{ number: {value} }}
      }}) {{
        projectV2Item {{ id }}
      }}
    }}
    '''
```

### Rate Limiting

Built-in delays prevent hitting GitHub's rate limits:
```python
time.sleep(1)  # Rate limiting between operations
```

### Error Handling

Comprehensive error handling with colored output:
- 🔴 Red: Critical errors
- 🟡 Yellow: Warnings and prompts
- 🟢 Green: Success messages
- 🔵 Blue: Information
- 🟣 Magenta: Debug information

## Troubleshooting

### NUMBER and DATE Fields Not Updating

If NUMBER or DATE fields aren't updating:
1. Check the debug output to verify field type detection
2. Ensure dates are in YYYY-MM-DD format
3. Verify numbers are valid (integers or floats)

### Field Not Found Errors

This usually means:
1. The field name in CSV doesn't match the project field
2. The field hasn't been created yet
3. There's a conflict with reserved field names

### Authentication Issues

```bash
# Check authentication status
gh auth status

# Re-authenticate if needed
gh auth login
```

## Script Versions

- **v1**: Basic repository and project creation
- **v2**: Added CSV import functionality
- **v3**: Enhanced conflict resolution and field mapping
- **v4**: Advanced field type detection and proper update handling

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

MIT License - feel free to use and modify for your needs.

## Acknowledgments

This script was developed through iterative improvements to handle the complexities of GitHub's Project V2 API and provide a reliable way to bulk import issues with custom fields.
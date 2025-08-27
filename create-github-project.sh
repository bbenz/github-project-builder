#!/bin/bash

# ========================================
# GitHub Project and Repository Creator
# ========================================

# Configuration Variables (modify these as needed)
REPO_NAME="test-project-demo"                    # Repository name
PROJECT_NAME="Project Management Board"          # Project name
CSV_FILE="test-issues.csv"                      # Path to CSV file
PROJECT_SCOPE="user"                            # "user" for personal, "org" for organization
ORG_NAME=""                                      # Organization name (required if PROJECT_SCOPE="org")

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ========================================
# Error Handling and Prerequisites Check
# ========================================

set -e  # Exit on error

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to prompt for yes/no
prompt_yes_no() {
    local prompt=$1
    local response
    while true; do
        read -p "$prompt (y/n): " response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    print_message "$RED" "Error: GitHub CLI (gh) is not installed."
    print_message "$YELLOW" "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    print_message "$RED" "Error: Python 3 is not installed."
    exit 1
fi

# Check if user is authenticated with gh
if ! gh auth status &> /dev/null; then
    print_message "$RED" "Error: Not authenticated with GitHub CLI."
    print_message "$YELLOW" "Please run: gh auth login"
    exit 1
fi

# Check if CSV file exists
if [ ! -f "$CSV_FILE" ]; then
    print_message "$RED" "Error: CSV file '$CSV_FILE' not found."
    exit 1
fi

# Validate PROJECT_SCOPE
if [ "$PROJECT_SCOPE" != "user" ] && [ "$PROJECT_SCOPE" != "org" ]; then
    print_message "$RED" "Error: PROJECT_SCOPE must be 'user' or 'org'"
    exit 1
fi

# Check organization name if scope is org
if [ "$PROJECT_SCOPE" = "org" ] && [ -z "$ORG_NAME" ]; then
    print_message "$RED" "Error: ORG_NAME must be set when PROJECT_SCOPE is 'org'"
    exit 1
fi

# ========================================
# Main Script
# ========================================

print_message "$GREEN" "Starting GitHub Project Setup..."
print_message "$YELLOW" "Repository: $REPO_NAME"
print_message "$YELLOW" "Project: $PROJECT_NAME"
print_message "$YELLOW" "Scope: $PROJECT_SCOPE"

# Get current authenticated user
CURRENT_USER=$(gh api user --jq .login)

# Determine owner based on scope
if [ "$PROJECT_SCOPE" = "org" ]; then
    REPO_OWNER="$ORG_NAME"
    PROJECT_OWNER="$ORG_NAME"
    REPO_PATH="$ORG_NAME/$REPO_NAME"
else
    REPO_OWNER="$CURRENT_USER"
    PROJECT_OWNER="$CURRENT_USER"
    REPO_PATH="$CURRENT_USER/$REPO_NAME"
fi

# ========================================
# Check for Existing Repository
# ========================================

REPO_EXISTS=false
if gh repo view "$REPO_PATH" &> /dev/null; then
    REPO_EXISTS=true
    print_message "$YELLOW" "⚠️  Warning: Repository '$REPO_PATH' already exists."
    
    # Get repo details
    REPO_URL=$(gh repo view "$REPO_PATH" --json url --jq .url)
    print_message "$BLUE" "   Repository URL: $REPO_URL"
    
    if ! prompt_yes_no "Do you want to use this existing repository?"; then
        print_message "$RED" "Cancelled by user."
        exit 1
    fi
    print_message "$GREEN" "Using existing repository..."
else
    print_message "$GREEN" "✓ Repository '$REPO_PATH' does not exist. Will create it."
fi

# ========================================
# Check for Existing Projects
# ========================================

print_message "$BLUE" "Checking for existing projects..."

# Get list of existing projects with better error handling
if [ "$PROJECT_SCOPE" = "org" ]; then
    EXISTING_PROJECTS=$(gh project list --owner "$ORG_NAME" --limit 100 --format json 2>/dev/null || echo "[]")
else
    EXISTING_PROJECTS=$(gh project list --limit 100 --format json 2>/dev/null || echo "[]")
fi

# Check if a project with the same name exists - Improved Python code
PROJECT_CHECK=$(echo "$EXISTING_PROJECTS" | python3 -c "
import json
import sys

try:
    raw_data = sys.stdin.read().strip()
    
    # Handle empty or invalid input
    if not raw_data:
        print('false')
        print('')
        sys.exit(0)
    
    data = json.loads(raw_data)
    project_name = '$PROJECT_NAME'
    
    # Handle different response formats from gh CLI
    projects_list = []
    
    if isinstance(data, list):
        projects_list = data
    elif isinstance(data, dict):
        # Check for 'projects' key
        if 'projects' in data:
            projects_list = data['projects']
        else:
            # Might be a single project
            projects_list = [data]
    
    # Search for matching project
    for project in projects_list:
        if isinstance(project, dict):
            # Check both 'title' and 'name' fields
            title = project.get('title', '')
            name = project.get('name', '')
            
            if title == project_name or name == project_name:
                print('true')
                print(project.get('number', ''))
                sys.exit(0)
    
    print('false')
    print('')
    
except json.JSONDecodeError as e:
    print('false')
    print('')
except Exception as e:
    print('false')
    print('')
")

PROJECT_EXISTS_FLAG=$(echo "$PROJECT_CHECK" | head -1)
EXISTING_PROJECT_NUMBER=$(echo "$PROJECT_CHECK" | tail -1 | grep -E '^[0-9]+$' || echo "")

if [ "$PROJECT_EXISTS_FLAG" = "true" ] && [ -n "$EXISTING_PROJECT_NUMBER" ]; then
    print_message "$YELLOW" "⚠️  Warning: Project '$PROJECT_NAME' already exists (Project #$EXISTING_PROJECT_NUMBER)."
    
    if [ "$PROJECT_SCOPE" = "org" ]; then
        PROJECT_URL="https://github.com/orgs/$ORG_NAME/projects/$EXISTING_PROJECT_NUMBER"
    else
        PROJECT_URL="https://github.com/users/$CURRENT_USER/projects/$EXISTING_PROJECT_NUMBER"
    fi
    print_message "$BLUE" "   Project URL: $PROJECT_URL"
    
    print_message "$YELLOW" "Options:"
    print_message "$YELLOW" "  1. Use existing project (will add new issues to it)"
    print_message "$YELLOW" "  2. Create a new project with a different name"
    print_message "$YELLOW" "  3. Cancel operation"
    
    while true; do
        read -p "Choose an option (1/2/3): " choice
        case $choice in
            1)
                print_message "$GREEN" "Using existing project..."
                USE_EXISTING_PROJECT=true
                PROJECT_NUMBER=$EXISTING_PROJECT_NUMBER
                break
                ;;
            2)
                read -p "Enter new project name: " NEW_PROJECT_NAME
                PROJECT_NAME="$NEW_PROJECT_NAME"
                print_message "$GREEN" "Creating new project: $PROJECT_NAME"
                USE_EXISTING_PROJECT=false
                break
                ;;
            3)
                print_message "$RED" "Cancelled by user."
                exit 1
                ;;
            *)
                echo "Please enter 1, 2, or 3."
                ;;
        esac
    done
else
    print_message "$GREEN" "✓ Project '$PROJECT_NAME' does not exist. Will create it."
    USE_EXISTING_PROJECT=false
fi

# ========================================
# Summary and Confirmation
# ========================================

print_message "$BLUE" ""
print_message "$BLUE" "========================================="
print_message "$BLUE" "Setup Summary:"
print_message "$BLUE" "========================================="
if [ "$REPO_EXISTS" = true ]; then
    print_message "$YELLOW" "Repository: Use existing '$REPO_PATH'"
else
    print_message "$GREEN" "Repository: Create new '$REPO_PATH'"
fi

if [ "$USE_EXISTING_PROJECT" = true ]; then
    print_message "$YELLOW" "Project: Use existing '$PROJECT_NAME' (#$PROJECT_NUMBER)"
else
    print_message "$GREEN" "Project: Create new '$PROJECT_NAME'"
fi

print_message "$BLUE" "CSV File: $CSV_FILE"
print_message "$BLUE" "Scope: $PROJECT_SCOPE"
if [ "$PROJECT_SCOPE" = "org" ]; then
    print_message "$BLUE" "Organization: $ORG_NAME"
else
    print_message "$BLUE" "User: $CURRENT_USER"
fi
print_message "$BLUE" "========================================="

if ! prompt_yes_no "Do you want to proceed with this configuration?"; then
    print_message "$RED" "Cancelled by user."
    exit 1
fi

# ========================================
# Create Repository (if needed)
# ========================================

if [ "$REPO_EXISTS" = false ]; then
    print_message "$GREEN" "Creating repository..."
    if [ "$PROJECT_SCOPE" = "org" ]; then
        gh repo create "$ORG_NAME/$REPO_NAME" --public --description "Test project with custom fields"
    else
        gh repo create "$REPO_NAME" --public --description "Test project with custom fields"
    fi
    sleep 2  # Give GitHub a moment to process
fi

# ========================================
# Export all variables for Python script
# ========================================

export REPO_NAME
export REPO_OWNER
export PROJECT_OWNER
export PROJECT_NAME
export CSV_FILE
export PROJECT_SCOPE
export ORG_NAME
export PROJECT_NUMBER="${PROJECT_NUMBER:-}"
export USE_EXISTING_PROJECT="${USE_EXISTING_PROJECT:-false}"

# ========================================
# Create project and process CSV
# ========================================

print_message "$GREEN" "Processing project and importing issues..."

python3 << 'EOF'
import csv
import json
import subprocess
import sys
import time
import re
from datetime import datetime
import os

# Configuration from shell variables
repo_name = os.environ.get('REPO_NAME', 'test-project-demo')
repo_owner = os.environ.get('REPO_OWNER', '')
project_owner = os.environ.get('PROJECT_OWNER', '')
project_name = os.environ.get('PROJECT_NAME', 'Project Management Board')
csv_file = os.environ.get('CSV_FILE', 'test-issues.csv')
project_scope = os.environ.get('PROJECT_SCOPE', 'user')
org_name = os.environ.get('ORG_NAME', '')
use_existing_project = os.environ.get('USE_EXISTING_PROJECT', 'false') == 'true'
existing_project_number = os.environ.get('PROJECT_NUMBER', '')

# Validate critical variables
if not project_owner:
    print("\033[0;31mError: PROJECT_OWNER is not set!\033[0m")
    sys.exit(1)

if not repo_owner:
    print("\033[0;31mError: REPO_OWNER is not set!\033[0m")
    sys.exit(1)

def run_gh_command(command, debug=False):
    """Execute a gh CLI command and return the output."""
    try:
        if debug:
            print(f"  \033[0;35mDEBUG: Running: {command}\033[0m")
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
        output = result.stdout.strip()
        if debug and output:
            print(f"  \033[0;35mDEBUG: Output: {output[:500]}...\033[0m")
        return output
    except subprocess.CalledProcessError as e:
        print(f"\033[0;31mError executing command: {command}\033[0m")
        print(f"\033[0;31mStderr: {e.stderr}\033[0m")
        print(f"\033[0;31mStdout: {e.stdout}\033[0m")
        sys.exit(1)

def run_gh_command_no_fail(command, debug=False):
    """Execute a gh CLI command and return the output without failing."""
    try:
        if debug:
            print(f"  \033[0;35mDEBUG: Running: {command}\033[0m")
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        output = result.stdout.strip()
        
        if result.returncode == 0:
            if debug and output:
                print(f"  \033[0;35mDEBUG: Success!\033[0m")
            return output
        else:
            if debug:
                print(f"  \033[0;35mDEBUG: Failed with code {result.returncode}\033[0m")
                print(f"  \033[0;35mDEBUG: Stderr: {result.stderr}\033[0m")
            return None
    except Exception as e:
        if debug:
            print(f"  \033[0;35mDEBUG: Exception: {e}\033[0m")
        return None

def get_project_id(project_number):
    """Get the project ID from the project number."""
    cmd = f'gh project view {project_number} --owner "{project_owner}" --format json'
    result = run_gh_command(cmd)
    project_data = json.loads(result)
    return project_data.get('id')

def create_project():
    """Create a new GitHub project."""
    print(f"\033[0;32mCreating project: {project_name}\033[0m")
    
    # Always provide owner explicitly for non-interactive mode
    cmd = f'gh project create --owner "{project_owner}" --title "{project_name}" --format json'
    
    result = run_gh_command(cmd)
    project_data = json.loads(result)
    return project_data['number'], project_data.get('id')

def get_field_mapping(project_number):
    """Get mapping of field names to their GraphQL IDs."""
    try:
        cmd = f'gh project field-list {project_number} --owner "{project_owner}" --format json'
        result = run_gh_command(cmd)
        
        # Parse the result
        data = json.loads(result) if result else {}
        
        field_mapping = {}
        
        # Handle different response formats
        fields = []
        if isinstance(data, dict):
            # Check for different possible keys
            if 'fields' in data:
                fields = data['fields']
            elif 'items' in data:
                fields = data['items']
            else:
                # Might be the fields directly
                fields = [data]
        elif isinstance(data, list):
            fields = data
        
        print(f"\033[0;33mFound {len(fields)} fields in the project\033[0m")
        
        # Known field type mappings based on field names (fallback)
        known_types = {
            'EstimatedHours': 'NUMBER',
            'DueDate': 'DATE',
            'Priority': 'SINGLE_SELECT',
            'WorkflowState': 'SINGLE_SELECT',
            'Team': 'SINGLE_SELECT'
        }
        
        for field in fields:
            if isinstance(field, dict):
                name = field.get('name', '')
                field_id = field.get('id', '')
                
                if name and field_id:
                    # For single select fields, get the options
                    options = []
                    if 'options' in field and isinstance(field.get('options'), list):
                        for opt in field['options']:
                            if isinstance(opt, dict):
                                options.append({
                                    'name': opt.get('name', ''),
                                    'id': opt.get('id', '')
                                })
                    
                    # Get field type - first check dataType, then type, then use known types
                    field_type = field.get('dataType', field.get('type', ''))
                    
                    # Determine the actual type based on various conditions
                    actual_type = None
                    
                    # Check if it's a single select field
                    if 'SINGLESELECTFIELD' in field_type.upper():
                        actual_type = 'SINGLE_SELECT'
                    # Check if we know what type this field should be by name
                    elif name in known_types:
                        actual_type = known_types[name]
                    # If it's a generic ProjectV2Field and we don't know the type, default to TEXT
                    elif 'PROJECTV2FIELD' in field_type.upper():
                        actual_type = known_types.get(name, 'TEXT')
                    # Use the field type as-is if it's something else
                    else:
                        actual_type = field_type.upper()
                    
                    field_mapping[name] = {
                        'id': field_id,
                        'type': actual_type,
                        'original_type': field_type,  # Keep original for debugging
                        'options': options
                    }
                    
                    # Show field details
                    print(f"  • {name}: Type={actual_type}, ID={field_id[:12]}...")
                    if actual_type != field_type.upper():
                        print(f"    (Original type: {field_type}, Using: {actual_type})")
                    if options:
                        print(f"    Options: {', '.join([o['name'] for o in options[:5]])}" + 
                              (" ..." if len(options) > 5 else ""))
        
        return field_mapping
    except Exception as e:
        print(f"\033[0;33mWarning: Could not get field mapping: {e}\033[0m")
        import traceback
        traceback.print_exc()
        return {}

def check_existing_fields(project_number):
    """Check which custom fields already exist in the project."""
    field_mapping = get_field_mapping(project_number)
    return {name: info for name, info in field_mapping.items()}

def create_custom_field(project_number, field_name, field_type, options=None, existing_fields=None):
    """Create a custom field in the project if it doesn't already exist."""
    
    # Check if field already exists
    if existing_fields and field_name in existing_fields:
        print(f"\033[0;33mField '{field_name}' already exists, skipping...\033[0m")
        return True
    
    # GitHub Projects reserved field names (these are built-in)
    reserved_fields = ['Title', 'Assignees', 'Status', 'Labels', 'Linked pull requests', 
                      'Reviewers', 'Repository', 'Milestone', 'Iteration', 'Tracks', 
                      'Tracked by', 'Reason', 'Text', 'Number', 'Date']
    
    if field_name in reserved_fields:
        print(f"\033[0;33mSkipping reserved field name '{field_name}'. Using built-in field.\033[0m")
        return False
    
    print(f"\033[0;32mCreating field: {field_name} ({field_type})\033[0m")
    
    owner_flag = f'--owner "{project_owner}"'
    
    if field_type == "SINGLE_SELECT" and options:
        # Create single select field with options
        options_str = ','.join([f'"{opt}"' for opt in options])
        cmd = f'gh project field-create {project_number} {owner_flag} --name "{field_name}" --data-type "{field_type}" --single-select-options {options_str}'
    elif field_type == "NUMBER":
        cmd = f'gh project field-create {project_number} {owner_flag} --name "{field_name}" --data-type "{field_type}"'
    elif field_type == "DATE":
        cmd = f'gh project field-create {project_number} {owner_flag} --name "{field_name}" --data-type "{field_type}"'
    elif field_type == "TEXT":
        cmd = f'gh project field-create {project_number} {owner_flag} --name "{field_name}" --data-type "{field_type}"'
    else:
        return False
    
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        time.sleep(1)  # Rate limiting
        return True
    except subprocess.CalledProcessError as e:
        # Check if it's because the field name is reserved or already taken
        if "reserved value" in str(e.stderr) or "already been taken" in str(e.stderr):
            print(f"\033[0;33mField '{field_name}' is reserved or already exists. Will attempt to use it as-is.\033[0m")
            return False
        else:
            print(f"\033[0;33mWarning: Could not create field '{field_name}': {e.stderr}\033[0m")
            return False

def create_issue(repo_owner, repo_name, title, body):
    """Create an issue in the repository."""
    # gh issue create doesn't support --format json, it returns the URL directly
    cmd = f'gh issue create --repo "{repo_owner}/{repo_name}" --title "{title}" --body "{body}"'
    
    output = run_gh_command(cmd)
    
    # Parse issue number from output like "https://github.com/owner/repo/issues/123"
    match = re.search(r'/issues/(\d+)', output)
    if match:
        return int(match.group(1))
    else:
        # Try to find just the number in the output
        match = re.search(r'#(\d+)', output)
        if match:
            return int(match.group(1))
        else:
            print(f"\033[0;31mError: Could not extract issue number from output: {output}\033[0m")
            sys.exit(1)

def add_issue_to_project(project_number, repo_owner, repo_name, issue_number):
    """Add an issue to the project."""
    owner_flag = f'--owner "{project_owner}"'
    cmd = f'gh project item-add {project_number} {owner_flag} --url "https://github.com/{repo_owner}/{repo_name}/issues/{issue_number}" --format json'
    
    result = run_gh_command(cmd)
    return json.loads(result)['id']

def get_option_id(field_info, value):
    """Get the option ID for a single select field value."""
    if 'options' in field_info and field_info['options']:
        for option in field_info['options']:
            if isinstance(option, dict):
                # Case-insensitive comparison and strip whitespace
                if option.get('name', '').strip().lower() == value.strip().lower():
                    return option.get('id')
    return None

def update_project_item_field(project_id, item_id, field_name, value, field_mapping, issue_title="", debug=False):
    """Update a custom field value for a project item."""
    
    # Get the field ID from the mapping
    if field_name not in field_mapping:
        print(f"  \033[0;33m⚠ Field '{field_name}' not found in project\033[0m")
        if debug:
            print(f"    Available fields: {list(field_mapping.keys())}")
        return False
    
    field_info = field_mapping[field_name]
    field_id = field_info['id']
    field_type = field_info.get('type', '').upper()
    original_type = field_info.get('original_type', '')
    
    # Strip whitespace from value
    value = str(value).strip()
    
    if debug:
        print(f"  \033[0;34mDEBUG: Updating {field_name}:\033[0m")
        print(f"    Field ID: {field_id}")
        print(f"    Field Type: {field_type}")
        print(f"    Original Type: {original_type}")
        print(f"    Value: '{value}'")
    
    try:
        # Build the appropriate command based on the determined field type
        if 'SINGLE_SELECT' in field_type:
            # For single select, we need to find the option ID
            option_id = get_option_id(field_info, value)
            if option_id:
                cmd = f'gh project item-edit --project-id "{project_id}" --id "{item_id}" --field-id "{field_id}" --single-select-option-id "{option_id}"'
                result = run_gh_command_no_fail(cmd, debug=debug)
                if result is not None:
                    print(f"  ✓ {field_name}: {value}")
                    return True
                else:
                    print(f"  ✗ {field_name}: Failed to update")
            else:
                print(f"  ✗ {field_name}: Option '{value}' not found")
                if debug and field_info.get('options'):
                    print(f"    Available: {', '.join([o['name'] for o in field_info['options']])}")
                    
        elif field_type == 'NUMBER':
            # For number fields, use --number flag
            try:
                num_value = float(value)
                cmd = f'gh project item-edit --project-id "{project_id}" --id "{item_id}" --field-id "{field_id}" --number {num_value}'
                result = run_gh_command_no_fail(cmd, debug=debug)
                if result is not None:
                    print(f"  ✓ {field_name}: {num_value}")
                    return True
                else:
                    print(f"  ✗ {field_name}: Failed to update number field")
                        
            except ValueError:
                print(f"  ✗ {field_name}: Invalid number '{value}'")
                
        elif field_type == 'DATE':
            # For date fields, ensure proper format
            try:
                # Ensure date is in YYYY-MM-DD format
                from datetime import datetime
                date_obj = datetime.strptime(value, "%Y-%m-%d")
                iso_date = date_obj.strftime("%Y-%m-%d")
                
                cmd = f'gh project item-edit --project-id "{project_id}" --id "{item_id}" --field-id "{field_id}" --date "{iso_date}"'
                result = run_gh_command_no_fail(cmd, debug=debug)
                if result is not None:
                    print(f"  ✓ {field_name}: {iso_date}")
                    return True
                else:
                    print(f"  ✗ {field_name}: Failed to update date field")
                        
            except ValueError as e:
                print(f"  ✗ {field_name}: Invalid date format '{value}' - {e}")
                    
        elif field_type == 'TEXT':
            # For text fields, use --text flag
            value_escaped = value.replace('"', '\\"')
            cmd = f'gh project item-edit --project-id "{project_id}" --id "{item_id}" --field-id "{field_id}" --text "{value_escaped}"'
            result = run_gh_command_no_fail(cmd, debug=debug)
            if result is not None:
                print(f"  ✓ {field_name}: {value}")
                return True
            else:
                print(f"  ✗ {field_name}: Failed to update text field")
        else:
            # Unknown field type
            print(f"  ✗ {field_name}: Unknown field type '{field_type}'")
            if debug:
                print(f"    Attempting as text field...")
                value_escaped = value.replace('"', '\\"')
                cmd = f'gh project item-edit --project-id "{project_id}" --id "{item_id}" --field-id "{field_id}" --text "{value_escaped}"'
                result = run_gh_command_no_fail(cmd, debug=True)
        
        return False
        
    except Exception as e:
        print(f"  ✗ {field_name}: Exception - {str(e)}")
        if debug:
            import traceback
            traceback.print_exc()
        return False

def main():
    """Main function to orchestrate the project creation and issue import."""
    
    # Use existing project or create new one
    project_id = None
    if use_existing_project and existing_project_number:
        project_number = int(existing_project_number)
        print(f"\033[0;32mUsing existing project #{project_number}\033[0m")
        # Get the project ID for the existing project
        project_id = get_project_id(project_number)
    else:
        project_number, project_id = create_project()
        print(f"\033[0;32mProject created with number: {project_number}\033[0m")
    
    if not project_id:
        print("\033[0;31mError: Could not get project ID\033[0m")
        sys.exit(1)
    
    print(f"Project ID: {project_id}")
    
    # Save project number to file for shell script to read
    with open('/tmp/project_number.txt', 'w') as f:
        f.write(str(project_number))
    
    # Check existing fields
    print("\n\033[0;32mChecking existing fields...\033[0m")
    existing_fields = check_existing_fields(project_number)
    
    # Read CSV file
    with open(csv_file, 'r', encoding='utf-8') as file:
        csv_reader = csv.DictReader(file)
        headers = csv_reader.fieldnames
        
        # Define field types and options for each custom field
        # Note: "Status" is renamed to "WorkflowState" to avoid conflict with reserved field
        field_definitions = {
            'Priority': {
                'type': 'SINGLE_SELECT',
                'options': ['High', 'Medium', 'Low']
            },
            'WorkflowState': {  # Renamed from 'Status' to avoid conflict
                'type': 'SINGLE_SELECT',
                'options': ['Todo', 'In Progress', 'Done', 'Blocked']
            },
            'EstimatedHours': {
                'type': 'NUMBER'
            },
            'DueDate': {
                'type': 'DATE'
            },
            'Team': {
                'type': 'SINGLE_SELECT',
                'options': ['Frontend', 'Backend', 'API', 'Database', 'Documentation', 'Security', 'DevOps', 'Testing']
            }
        }
        
        # Create custom fields (skip Title and Description as they're built-in)
        print("\n\033[0;32mCreating/verifying custom fields...\033[0m")
        for field_name in headers:
            if field_name not in ['Title', 'Description']:
                # Map CSV "Status" column to "WorkflowState" field
                field_to_create = 'WorkflowState' if field_name == 'Status' else field_name
                
                if field_to_create in field_definitions:
                    field_def = field_definitions[field_to_create]
                    create_custom_field(
                        project_number,
                        field_to_create,
                        field_def['type'],
                        field_def.get('options'),
                        existing_fields
                    )
        
        # Get the current field mapping with IDs after all fields are created
        print("\n\033[0;32mLoading field mapping...\033[0m")
        time.sleep(3)  # Give GitHub more time to process
        field_mapping = get_field_mapping(project_number)
        
        # Debug: Show what we got
        print(f"\n\033[0;36mField mapping summary:\033[0m")
        for fname, finfo in field_mapping.items():
            if fname in ['EstimatedHours', 'DueDate', 'Priority', 'WorkflowState', 'Team']:
                print(f"  {fname}: Type={finfo['type']}, Original={finfo.get('original_type', 'N/A')}")
        
        # Reset file pointer to read data rows
        file.seek(0)
        next(csv_reader)  # Skip header row
        
        # Create issues and add to project
        print(f"\n\033[0;32mImporting issues...\033[0m")
        print("=" * 50)
        
        issue_count = 0
        for i, row in enumerate(csv_reader, 1):
            print(f"\n\033[0;33m[Issue {i}] {row['Title']}\033[0m")
            
            # Create issue
            issue_number = create_issue(
                repo_owner,
                repo_name,
                row['Title'],
                row['Description']
            )
            print(f"  ✓ Created issue #{issue_number}")
            
            # Add issue to project
            item_id = add_issue_to_project(project_number, repo_owner, repo_name, issue_number)
            print(f"  ✓ Added to project (ID: {item_id[:12]}...)")
            
            # Update custom fields - enable debug for first 2 issues
            debug_mode = (i <= 2)  # Debug first 2 issues
            
            print(f"  \033[0;36mUpdating fields:\033[0m")
            
            # Process fields in a specific order for debugging
            field_order = ['Priority', 'WorkflowState', 'Team', 'EstimatedHours', 'DueDate']
            
            for field_name in field_order:
                csv_field = 'Status' if field_name == 'WorkflowState' else field_name
                if csv_field in row and row[csv_field]:
                    update_project_item_field(
                        project_id, 
                        item_id, 
                        field_name, 
                        row[csv_field], 
                        field_mapping,
                        issue_title=row['Title'],
                        debug=debug_mode
                    )
            
            issue_count = i
            time.sleep(1)  # Rate limiting
    
    print("\n" + "=" * 50)
    print(f"\033[0;32m✅ Successfully imported {issue_count} issues!\033[0m")

if __name__ == "__main__":
    main()
EOF

# Read the project number that was saved by Python
if [ -f /tmp/project_number.txt ]; then
    PROJECT_NUMBER=$(cat /tmp/project_number.txt)
    rm /tmp/project_number.txt
fi

# Display completion messages with URLs
print_message "$GREEN" "========================================="
print_message "$GREEN" "Import complete!"
print_message "$GREEN" "========================================="

if [ "$PROJECT_SCOPE" = "org" ]; then
    print_message "$YELLOW" "Project: https://github.com/orgs/$ORG_NAME/projects/$PROJECT_NUMBER"
    print_message "$YELLOW" "Repository: https://github.com/$ORG_NAME/$REPO_NAME"
else
    print_message "$YELLOW" "Project: https://github.com/users/$REPO_OWNER/projects/$PROJECT_NUMBER"
    print_message "$YELLOW" "Repository: https://github.com/$REPO_OWNER/$REPO_NAME"
fi

print_message "$GREEN" "========================================="
print_message "$YELLOW" "Note: The 'Status' field from CSV has been mapped to 'WorkflowState'"
print_message "$YELLOW" "to avoid conflict with GitHub's built-in Status field."
print_message "$GREEN" "========================================="
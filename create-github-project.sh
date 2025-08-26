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

# Check if repository already exists
if [ "$PROJECT_SCOPE" = "org" ]; then
    if gh repo view "$ORG_NAME/$REPO_NAME" &> /dev/null; then
        print_message "$RED" "Error: Repository '$ORG_NAME/$REPO_NAME' already exists."
        exit 1
    fi
else
    CURRENT_USER=$(gh api user --jq .login)
    if gh repo view "$CURRENT_USER/$REPO_NAME" &> /dev/null; then
        print_message "$RED" "Error: Repository '$CURRENT_USER/$REPO_NAME' already exists."
        exit 1
    fi
fi

# Create repository
print_message "$GREEN" "Creating repository..."
if [ "$PROJECT_SCOPE" = "org" ]; then
    gh repo create "$ORG_NAME/$REPO_NAME" --public --description "Test project with custom fields"
    REPO_OWNER="$ORG_NAME"
else
    gh repo create "$REPO_NAME" --public --description "Test project with custom fields"
    REPO_OWNER=$(gh api user --jq .login)
fi

sleep 2  # Give GitHub a moment to process

# Store PROJECT_NUMBER for use at the end
export PROJECT_NUMBER=""

# Create project and process CSV using embedded Python
print_message "$GREEN" "Creating project and importing issues..."

python3 << 'EOF'
import csv
import json
import subprocess
import sys
import time
from datetime import datetime

# Configuration from shell variables
import os
repo_name = os.environ.get('REPO_NAME', 'test-project-demo')
repo_owner = os.environ.get('REPO_OWNER', '')
project_name = os.environ.get('PROJECT_NAME', 'Project Management Board')
csv_file = os.environ.get('CSV_FILE', 'test-issues.csv')
project_scope = os.environ.get('PROJECT_SCOPE', 'user')
org_name = os.environ.get('ORG_NAME', '')

def run_gh_command(command):
    """Execute a gh CLI command and return the output."""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"\033[0;31mError executing command: {command}\033[0m")
        print(f"\033[0;31mError: {e.stderr}\033[0m")
        sys.exit(1)

def create_project():
    """Create a new GitHub project."""
    print(f"\033[0;32mCreating project: {project_name}\033[0m")
    
    if project_scope == "org":
        cmd = f'gh project create --owner "{org_name}" --title "{project_name}" --format json'
    else:
        cmd = f'gh project create --title "{project_name}" --format json'
    
    result = run_gh_command(cmd)
    project_data = json.loads(result)
    return project_data['number']

def get_project_id(project_number):
    """Get the project ID from project number."""
    if project_scope == "org":
        cmd = f'gh project view {project_number} --owner "{org_name}" --format json'
    else:
        cmd = f'gh project view {project_number} --format json'
    
    result = run_gh_command(cmd)
    project_data = json.loads(result)
    return project_data['id']

def create_custom_field(project_number, field_name, field_type, options=None):
    """Create a custom field in the project."""
    print(f"\033[0;32mCreating field: {field_name} ({field_type})\033[0m")
    
    owner_flag = f'--owner "{org_name}"' if project_scope == "org" else ""
    
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
        return None
    
    run_gh_command(cmd)
    time.sleep(1)  # Rate limiting

def create_issue(repo_owner, repo_name, title, body):
    """Create an issue in the repository."""
    cmd = f'gh issue create --repo "{repo_owner}/{repo_name}" --title "{title}" --body "{body}" --format json'
    result = run_gh_command(cmd)
    issue_data = json.loads(result)
    return issue_data['number']

def add_issue_to_project(project_number, repo_owner, repo_name, issue_number):
    """Add an issue to the project."""
    owner_flag = f'--owner "{org_name}"' if project_scope == "org" else ""
    cmd = f'gh project item-add {project_number} {owner_flag} --url "https://github.com/{repo_owner}/{repo_name}/issues/{issue_number}"'
    result = run_gh_command(cmd)
    return json.loads(result)['id']

def update_project_item_field(project_number, item_id, field_name, value):
    """Update a custom field value for a project item."""
    owner_flag = f'--owner "{org_name}"' if project_scope == "org" else ""
    
    # Escape special characters in value
    value = str(value).replace('"', '\\"')
    
    cmd = f'gh project item-edit {project_number} {owner_flag} --id "{item_id}" --field-id "{field_name}" --text "{value}"'
    run_gh_command(cmd)

def main():
    """Main function to orchestrate the project creation and issue import."""
    
    # Create the project
    project_number = create_project()
    print(f"\033[0;32mProject created with number: {project_number}\033[0m")
    
    # Save project number to file for shell script to read
    with open('/tmp/project_number.txt', 'w') as f:
        f.write(str(project_number))
    
    # Read CSV file
    with open(csv_file, 'r', encoding='utf-8') as file:
        csv_reader = csv.DictReader(file)
        headers = csv_reader.fieldnames
        
        # Define field types and options for each custom field
        field_definitions = {
            'Priority': {
                'type': 'SINGLE_SELECT',
                'options': ['High', 'Medium', 'Low']
            },
            'Status': {
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
        for field_name in headers:
            if field_name not in ['Title', 'Description']:
                if field_name in field_definitions:
                    field_def = field_definitions[field_name]
                    create_custom_field(
                        project_number,
                        field_name,
                        field_def['type'],
                        field_def.get('options')
                    )
        
        # Reset file pointer to read data rows
        file.seek(0)
        next(csv_reader)  # Skip header row
        
        # Create issues and add to project
        print(f"\033[0;32mImporting issues...\033[0m")
        for i, row in enumerate(csv_reader, 1):
            print(f"\033[0;33mProcessing issue {i}/30: {row['Title']}\033[0m")
            
            # Create issue
            issue_number = create_issue(
                repo_owner,
                repo_name,
                row['Title'],
                row['Description']
            )
            
            # Add issue to project
            item_id = add_issue_to_project(project_number, repo_owner, repo_name, issue_number)
            
            # Update custom fields
            for field_name in headers:
                if field_name not in ['Title', 'Description'] and row.get(field_name):
                    update_project_item_field(project_number, item_id, field_name, row[field_name])
            
            time.sleep(1)  # Rate limiting
    
    print(f"\033[0;32m✅ Successfully created project and imported {i} issues!\033[0m")

if __name__ == "__main__":
    main()
EOF

export REPO_NAME
export REPO_OWNER
export PROJECT_NAME
export CSV_FILE
export PROJECT_SCOPE
export ORG_NAME

# Read the project number that was saved by Python
if [ -f /tmp/project_number.txt ]; then
    PROJECT_NUMBER=$(cat /tmp/project_number.txt)
    rm /tmp/project_number.txt
fi

# Display completion messages with URLs
print_message "$GREEN" "========================================="
print_message "$GREEN" "Import complete."
print_message "$GREEN" "========================================="

if [ "$PROJECT_SCOPE" = "org" ]; then
    print_message "$YELLOW" "Project: https://github.com/orgs/$ORG_NAME/projects/$PROJECT_NUMBER"
    print_message "$YELLOW" "Repository: https://github.com/$ORG_NAME/$REPO_NAME"
else
    print_message "$YELLOW" "Project: https://github.com/users/$REPO_OWNER/projects/$PROJECT_NUMBER"
    print_message "$YELLOW" "Repository: https://github.com/$REPO_OWNER/$REPO_NAME"
fi

print_message "$GREEN" "========================================="
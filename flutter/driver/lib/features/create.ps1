# create_project_structure.ps1
# run this first
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Create main feature directory
mkdir "feature_name"

# Create domain structure
mkdir "feature_name\domain"
mkdir "feature_name\domain\entities"
mkdir "feature_name\domain\repositories"
mkdir "feature_name\domain\usecases"

# Create data structure
mkdir "feature_name\data"
mkdir "feature_name\data\datasource"
mkdir "feature_name\data\models"
mkdir "feature_name\data\repositories"

# Create presentation structure
mkdir "feature_name\presentation"
mkdir "feature_name\presentation\notifiers"
mkdir "feature_name\presentation\providers"
mkdir "feature_name\presentation\screens"
mkdir "feature_name\presentation\widgets"

Write-Host "Directory structure created successfully under 'feature_name'"
# Create a directory for the logs if it doesn't already exist
$logDir = "C:\Windows\Logs\FixPDFMakerAddin"
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}

# Start logging
Start-Transcript -Path "$logDir\FixPDFMakerAddin_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"

# Define the possible paths to the PDFMaker directory
$possiblePaths = @(
    "c:\Program Files\Adobe\Acrobat DC\PDFMaker",
    "c:\Program Files (x86)\Adobe\Acrobat 2020\PDFMaker"
)

$pdfMakerPath = $null

# Check which PDFMaker directory exists
foreach ($path in $possiblePaths) {
    if (Test-Path -Path $path) {
        $pdfMakerPath = $path
        Write-Host "Found PDFMaker directory at: $pdfMakerPath"
        break
    }
}

# If no path was found, exit the script
if ($null -eq $pdfMakerPath) {
    Write-Host "No PDFMaker directory was found in the specified locations. Skipping the rest of the script."
    Stop-Transcript
    Exit 0
}

Write-Host "Proceeding with script..."

# Close all Microsoft Office applications
$officeApps = @("winword", "excel", "powerpnt", "outlook")
Write-Host "Checking for running Office applications..."
foreach ($app in $officeApps) {
    $processes = Get-Process -Name $app -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "Closing $app..."
        Stop-Process -Name $app -Force
    } else {
        Write-Host "$app is not running."
    }
}
Write-Host "All running Office applications have been closed."

# Change to the relevant directory
Set-Location -Path $pdfMakerPath

# Define the language-independent SID for the "SYSTEM" account
$systemSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")

# --- SCRIPT LOGIC START ---

# Function to process the folder permissions
function Set-FolderPermissions {
    param (
        [string]$FolderName
    )

    Write-Host "Processing folder: $FolderName"
    
    # 1. Force ownership with takeown.exe (for the Administrators group)
    Write-Host "Taking ownership of $FolderName..."
    takeown.exe /F $FolderName /R /A /D Y
    
    # 2. Reset permissions with icacls to a clean, inherited state
    Write-Host "Resetting permissions for $FolderName..."
    icacls.exe $FolderName /t /q /c /reset
    
    # 3. Remove all old rules and apply the new, final permissions
    $acl = Get-Acl -Path $FolderName
    # Disable inheritance and remove existing rules
    $acl.SetAccessRuleProtection($true, $false) 
    # Add the new rule for SYSTEM only
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($systemSID, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    
    # Apply the cleaned-up Access Control List (ACL)
    Set-Acl -Path $FolderName -AclObject $acl
    Write-Host "Permissions for $FolderName have been set successfully."
}

# Process both target folders
Set-FolderPermissions -FolderName "Office"
Set-FolderPermissions -FolderName "Mail"

# --- SCRIPT LOGIC END ---

Write-Host "Script completed successfully."
Stop-Transcript
Exit 0
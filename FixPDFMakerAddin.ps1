# Create a directory for the logs if it doesn't already exist
$logDir = "C:\Windows\Logs\FixPDFMakerAddin"
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}

# Start logging
Start-Transcript -Path "$logDir\FixPDFMakerAddin_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"

# --- Start of Modifications ---

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
        Write-Host "Found Adobe PDFMaker directory at: $pdfMakerPath"
        break
    }
}

# If no path was found, exit the script
if ($null -eq $pdfMakerPath) {
    Write-Host "No Adobe PDFMaker directory was found in the specified locations. Skipping the rest of the script."
    Stop-Transcript
    Exit 0
}

# --- End of Modifications ---

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

# Change to relevant directory using the full command
Set-Location -Path $pdfMakerPath

### OFFICE SUBFOLDER
# Fix any broken permissions
icacls Office /t /q /c /reset

# Recursively change owner first before we remove all permissions
$path = "Office"
$owner = "Administrators"

# Get ACL and set the owner for the current item
$ACL = Get-Acl -Path $path
$User = New-Object System.Security.Principal.Ntaccount($owner)
$ACL.SetOwner($User)
Set-Acl -Path $path -AclObject $ACL

# If the item is a directory, recurse into its contents
if ((Get-Item $path).PSIsContainer) {
    Get-ChildItem -Path $path -Recurse | ForEach-Object {
        try {
            # Apply ownership to each item
            $itemACL = Get-Acl -Path $_.FullName
            $itemACL.SetOwner($User)
            Set-Acl -Path $_.FullName -AclObject $itemACL
        } catch {
            Write-Host "Failed to set owner on $_.FullName: $_" -ForegroundColor Red
        }
    }
}

# Now add SYSTEM as only user that can read/write
$ACL = Get-ACL -Path "Office"
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($AccessRule)
$ACL | Set-Acl -Path "Office"

# Remove all permissions and inheritance from folder
$ACL = Get-Acl -Path "Office"
$ACL.SetAccessRuleProtection($true, $false)
$ACL | Set-Acl -Path "Office"

### MAIL SUBFOLDER
# Fix any broken permissions
icacls Mail /t /q /c /reset

# Recursively change owner first before we remove all permissions
$path = "Mail"
$owner = "Administrators"

# Get ACL and set the owner for the current item
$ACL = Get-Acl -Path $path
$User = New-Object System.Security.Principal.Ntaccount($owner)
$ACL.SetOwner($User)
Set-Acl -Path $path -AclObject $ACL

# If the item is a directory, recurse into its contents
if ((Get-Item $path).PSIsContainer) {
    Get-ChildItem -Path $path -Recurse | ForEach-Object {
        try {
            # Apply ownership to each item
            $itemACL = Get-Acl -Path $_.FullName
            $itemACL.SetOwner($User)
            Set-Acl -Path $_.FullName -AclObject $itemACL
        } catch {
            Write-Host "Failed to set owner on $_.FullName: $_" -ForegroundColor Red
        }
    }
}

# Now add SYSTEM as only user that can read/write
$ACL = Get-ACL -Path "Mail"
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($AccessRule)
$ACL | Set-Acl -Path "Mail"

# Remove all permissions and inheritance from folder
$ACL = Get-Acl -Path "Mail"
$ACL.SetAccessRuleProtection($true, $false)
$ACL | Set-Acl -Path "Mail"

Write-Host "ok"
Stop-Transcript
Exit 0
# Create a directory for the logs if it doesn't already exist
Set-LocationogDir = "C:\Windows\Logs\FixPDFMakerAddin"
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}

# Start logging
Start-Transcript -Path "$logDir\FixPDFMakerAddin_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"

# Define the path to the PDFMaker directory
$pdfMakerPath = "c:\Program Files\Adobe\Acrobat DC\PDFMaker"

# Check if the PDFMaker directory exists
if (-not (Test-Path -Path $pdfMakerPath)) {
    Write-Host "The Adobe PDFMaker directory was not found. Skipping the rest of the script."
    Stop-Transcript
    Exit 0
}

Write-Host "Adobe PDFMaker directory found. Proceeding with script..."

# --- Start of Modifications ---

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

# --- End of Modifications ---

# Change to relevant directory
Set-Location $pdfMakerPath

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
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$ACL.SetAccessRule($AccessRule)
$ACL | Set-Acl -Path "Office"

# Remove all permissions and inheritance from folder
$ACL = Get-Acl -Path "Office"
$ACL.SetAccessRuleProtection($true,$false)
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
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$ACL.SetAccessRule($AccessRule)
$ACL | Set-Acl -Path "Mail"

# Remove all permissions and inheritance from folder
$ACL = Get-Acl -Path "Mail"
$ACL.SetAccessRuleProtection($true,$false)
$ACL | Set-Acl -Path "Mail"

Write-Host "ok"
Stop-Transcript
Exit 0

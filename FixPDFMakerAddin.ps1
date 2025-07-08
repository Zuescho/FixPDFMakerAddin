# Verzeichnis für die Protokolle erstellen, falls es nicht existiert
$logDir = "C:\Windows\Logs\FixPDFMakerAddin"
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}

# Protokollierung starten
Start-Transcript -Path "$logDir\FixPDFMakerAddin_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"

# Mögliche Pfade zum PDFMaker-Verzeichnis definieren
$possiblePaths = @(
    "c:\Program Files\Adobe\Acrobat DC\PDFMaker",
    "c:\Program Files (x86)\Adobe\Acrobat 2020\PDFMaker"
)

$pdfMakerPath = $null

# Prüfen, welches PDFMaker-Verzeichnis existiert
foreach ($path in $possiblePaths) {
    if (Test-Path -Path $path) {
        $pdfMakerPath = $path
        Write-Host "PDFMaker-Verzeichnis gefunden unter: $pdfMakerPath"
        break
    }
}

# Wenn kein Pfad gefunden wurde, Skript beenden
if ($null -eq $pdfMakerPath) {
    Write-Host "Kein PDFMaker-Verzeichnis an den angegebenen Orten gefunden. Skript wird übersprungen."
    Stop-Transcript
    Exit 0
}

Write-Host "Fahre mit dem Skript fort..."

# Alle Microsoft Office-Anwendungen schließen
$officeApps = @("winword", "excel", "powerpnt", "outlook")
Write-Host "Prüfe auf laufende Office-Anwendungen..."
foreach ($app in $officeApps) {
    $processes = Get-Process -Name $app -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "Schließe $app..."
        Stop-Process -Name $app -Force
    } else {
        Write-Host "$app wird nicht ausgeführt."
    }
}
Write-Host "Alle laufenden Office-Anwendungen wurden geschlossen."

# Zum relevanten Verzeichnis wechseln
Set-Location -Path $pdfMakerPath

# Definiere die sprachunabhängige SID für "SYSTEM"
$systemSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")

### --- ANPASSUNGEN START ---

# Funktion zur Verarbeitung der Ordnerberechtigungen
function Set-FolderPermissions {
    param (
        [string]$FolderName
    )

    Write-Host "Verarbeite Ordner: $FolderName"
    
    # 1. Besitz mit takeown.exe erzwingen (für Administratoren)
    Write-Host "Übernehme Besitz von $FolderName..."
    takeown.exe /F $FolderName /R /A /D J
    
    # 2. Berechtigungen mit icacls zurücksetzen
    Write-Host "Setze Berechtigungen für $FolderName zurück..."
    icacls.exe $FolderName /t /q /c /reset
    
    # 3. Alle Berechtigungen außer für SYSTEM entfernen
    $acl = Get-Acl -Path $FolderName
    # Vererbung deaktivieren und vorhandene Regeln entfernen
    $acl.SetAccessRuleProtection($true, $false) 
    # Neue Regel nur für SYSTEM hinzufügen
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($systemSID, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($accessRule)
    
    # Bereinigte ACL anwenden
    Set-Acl -Path $FolderName -AclObject $acl
    Write-Host "Berechtigungen für $FolderName erfolgreich gesetzt."
}

# Verarbeite beide Ordner
Set-FolderPermissions -FolderName "Office"
Set-FolderPermissions -FolderName "Mail"

### --- ANPASSUNGEN ENDE ---

Write-Host "Skript erfolgreich abgeschlossen."
Stop-Transcript
Exit 0
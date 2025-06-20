# Migrate-UserData-OneDriveAware.ps1

function Get-LocalUserProfiles {
    Get-ChildItem "C:\Users" -Directory |
        Where-Object { $_.Name -notin @("Default", "Default User", "Public", "All Users") } |
        Select-Object -ExpandProperty Name
}

$userProfiles = Get-LocalUserProfiles
if ($userProfiles.Count -lt 2) {
    Write-Host "⚠️ Not enough user profiles found for migration. Exiting." -ForegroundColor Red
    exit
}

Write-Host "`nAvailable User Profiles:" -ForegroundColor Cyan
for ($i = 0; $i -lt $userProfiles.Count; $i++) {
    Write-Host "[$i] $($userProfiles[$i])"
}

$srcIndex = Read-Host "`nEnter number for the **SOURCE** user (copy from)"
$sourceUser = $userProfiles[$srcIndex]

$dstIndex = Read-Host "`nEnter number for the **DESTINATION** user (copy to)"
$destUser = $userProfiles[$dstIndex]

Write-Host "`nMigrating data from '$sourceUser' to '$destUser'..." -ForegroundColor Green
Start-Sleep -Seconds 2

# Folders to migrate
$folders = @("Desktop", "Documents", "Downloads", "Pictures", "Music", "Videos")

foreach ($folder in $folders) {
    # Prefer OneDrive folder if it exists
    $oneDriveSrc = "C:\Users\$sourceUser\OneDrive\$folder"
    $defaultSrc = "C:\Users\$sourceUser\$folder"
    $src = if (Test-Path $oneDriveSrc) { $oneDriveSrc } else { $defaultSrc }
    $dst = "C:\Users\$destUser\$folder"

    if (Test-Path $src) {
        Write-Host "`nCopying: $folder from $src" -ForegroundColor Yellow
        robocopy $src $dst /E /COPY:DAT /DCOPY:T /R:2 /W:5

        Write-Host "Setting permissions for $destUser on $folder..." -ForegroundColor Blue
        icacls $dst /grant "${destUser}:(OI)(CI)F" /T | Out-Null
    } else {
        Write-Host "Skipping $folder (not found)." -ForegroundColor DarkGray
    }
}

Write-Host "`nMigration complete!" -ForegroundColor Green

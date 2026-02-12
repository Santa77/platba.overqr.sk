param (
    [Parameter(Mandatory=$true)]
    [string]$NewVersion
)

# Kontrola formátu verzie
if ($NewVersion -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "CHYBA: Neplatný formát verzie. Použite X.Y.Z formát (napr. 1.0.5)" -ForegroundColor Red
    exit 1
}

$today = Get-Date -Format 'yyyy-MM-dd'

# Zobraziť začiatočnú správu
Write-Host "===== Aktualizácia verzie aplikácie LeQR.SK =====" -ForegroundColor Cyan
Write-Host "Nová verzia: $NewVersion ($today)" -ForegroundColor Yellow
Write-Host ""

# Pripraviť záložnú kópiu (rolling – vždy len 1 priečinok)
$backupFolder = ".\version_backup"
$filesToBackup = @("version.json", "sw.js", "index.html", "sitemap.xml")

if (Test-Path $backupFolder) {
    Remove-Item -Path $backupFolder -Recurse -Force
}
New-Item -Path $backupFolder -ItemType Directory | Out-Null
Write-Host "Vytvorený záložný adresár: $backupFolder" -ForegroundColor Gray

foreach ($file in $filesToBackup) {
    if (Test-Path $file) {
        Copy-Item $file -Destination $backupFolder
        Write-Host "  Záloha: $file" -ForegroundColor Gray
    }
}

# Počítadlo zmien
$changesTotal = 0

# === Pomocná funkcia na regex replace s počítaním ===
function Update-FileContent {
    param(
        [string]$FilePath,
        [string]$Pattern,
        [string]$Replacement,
        [string]$Description
    )
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $newContent = $content -replace $Pattern, $Replacement
    if ($newContent -ne $content) {
        Set-Content -Path $FilePath -Value $newContent -Encoding UTF8 -NoNewline
        Write-Host "   [OK] $Description" -ForegroundColor Green
        $script:changesTotal++
        return $true
    } else {
        Write-Host "   [--] $Description (bez zmeny)" -ForegroundColor Yellow
        return $false
    }
}

# 1. version.json
Write-Host "`n1. Aktualizácia version.json" -ForegroundColor Cyan
$versionJsonPath = ".\version.json"
if (Test-Path $versionJsonPath) {
    try {
        $json = Get-Content -Raw -Path $versionJsonPath | ConvertFrom-Json
        $oldVersion = $json.version
        Write-Host "   Aktualna verzia: $oldVersion -> $NewVersion" -ForegroundColor Gray
        
        $json.version = $NewVersion
        $json.releaseDate = $today
        $json.notes = "Aktualizácia na verziu $NewVersion z $today"
        
        $jsonString = $json | ConvertTo-Json -Depth 10
        Set-Content -Path $versionJsonPath -Value $jsonString -Encoding UTF8
        Write-Host "   [OK] version, releaseDate, notes" -ForegroundColor Green
        $changesTotal++
    } catch {
        Write-Host "   CHYBA: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   CHYBA: Súbor neexistuje!" -ForegroundColor Red
}

# 2. sw.js – APP_VERSION
Write-Host "`n2. Aktualizácia sw.js" -ForegroundColor Cyan
if (Test-Path ".\sw.js") {
    Update-FileContent -FilePath ".\sw.js" `
        -Pattern "const APP_VERSION = '[0-9]+\.[0-9]+\.[0-9]+';" `
        -Replacement "const APP_VERSION = '$NewVersion';" `
        -Description "APP_VERSION"
} else {
    Write-Host "   CHYBA: Súbor neexistuje!" -ForegroundColor Red
}

# 3. index.html – všetky výskyty verzie
Write-Host "`n3. Aktualizácia index.html" -ForegroundColor Cyan
$indexPath = ".\index.html"
if (Test-Path $indexPath) {
    # manifest link cache-bust
    Update-FileContent -FilePath $indexPath `
        -Pattern 'manifest\.json\?v=[0-9]+\.[0-9]+\.[0-9]+' `
        -Replacement "manifest.json?v=$NewVersion" `
        -Description "manifest.json?v= cache-bust"

    # SW registrácia cache-bust
    Update-FileContent -FilePath $indexPath `
        -Pattern "sw\.js\?v=[0-9]+\.[0-9]+\.[0-9]+" `
        -Replacement "sw.js?v=$NewVersion" `
        -Description "sw.js?v= cache-bust"

    # APP_VERSION konštanta
    Update-FileContent -FilePath $indexPath `
        -Pattern "const APP_VERSION = '[0-9]+\.[0-9]+\.[0-9]+';" `
        -Replacement "const APP_VERSION = '$NewVersion';" `
        -Description "APP_VERSION konštanta"

    # CSS obrázok cache-bust (pay-bottom-dark.png?v=)
    Update-FileContent -FilePath $indexPath `
        -Pattern "pay-bottom-dark\.png\?v=[0-9]+\.[0-9]+\.[0-9]+" `
        -Replacement "pay-bottom-dark.png?v=$NewVersion" `
        -Description "pay-bottom-dark.png?v= cache-bust"

    # JSON-LD softwareVersion
    Update-FileContent -FilePath $indexPath `
        -Pattern '"softwareVersion"\s*:\s*"[0-9]+\.[0-9]+\.[0-9]+"' `
        -Replacement "`"softwareVersion`": `"$NewVersion`"" `
        -Description "JSON-LD softwareVersion"

    # About modal fallback verzia
    Update-FileContent -FilePath $indexPath `
        -Pattern "\|\| '[0-9]+\.[0-9]+\.[0-9]+'" `
        -Replacement "|| '$NewVersion'" `
        -Description "About modal fallback verzia"
} else {
    Write-Host "   CHYBA: Súbor neexistuje!" -ForegroundColor Red
}

# 4. sitemap.xml – lastmod dátum
Write-Host "`n4. Aktualizácia sitemap.xml" -ForegroundColor Cyan
if (Test-Path ".\sitemap.xml") {
    Update-FileContent -FilePath ".\sitemap.xml" `
        -Pattern '<lastmod>[0-9]{4}-[0-9]{2}-[0-9]{2}</lastmod>' `
        -Replacement "<lastmod>$today</lastmod>" `
        -Description "lastmod dátum"
} else {
    Write-Host "   CHYBA: Súbor neexistuje!" -ForegroundColor Red
}

# Zobraziť súhrn
Write-Host "`n===== SÚHRN =====" -ForegroundColor Cyan
Write-Host "Verzia: $NewVersion | Dátum: $today | Zmien: $changesTotal" -ForegroundColor Green
Write-Host "`nAktualizované súbory:" -ForegroundColor Gray
Write-Host "  version.json, sw.js, index.html, sitemap.xml" -ForegroundColor Gray
Write-Host "`nĎalšie kroky:" -ForegroundColor Yellow
Write-Host "  git add -A" -ForegroundColor Gray
Write-Host "  git commit -m `"v$NewVersion`"" -ForegroundColor Gray
Write-Host "  git tag -a v$NewVersion -m `"Verzia $NewVersion`"" -ForegroundColor Gray
Write-Host "  git push && git push --tags" -ForegroundColor Gray
Write-Host "`n===== HOTOVO! =====" -ForegroundColor Cyan

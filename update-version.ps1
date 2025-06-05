param (
    [Parameter(Mandatory=$true)]
    [string]$NewVersion
)

# Kontrola formátu verzie
if ($NewVersion -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "CHYBA: Neplatný formát verzie. Použite X.Y.Z formát (napr. 1.0.5)" -ForegroundColor Red
    exit 1
}

# Zobraziť začiatočnú správu
Write-Host "===== Aktualizácia verzie aplikácie OverQR =====" -ForegroundColor Cyan
Write-Host "Nová verzia: $NewVersion" -ForegroundColor Yellow
Write-Host ""

# Pripraviť záložnú kópiu súborov pred zmenou
$backupFolder = ".\version_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$filesToBackup = @("version.json", "sw.js", "manifest.json", "index.html")

if (!(Test-Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory | Out-Null
    Write-Host "Vytvorený záložný adresár: $backupFolder" -ForegroundColor Gray
    
    foreach ($file in $filesToBackup) {
        if (Test-Path $file) {
            Copy-Item $file -Destination $backupFolder
            Write-Host "Záloha: $file" -ForegroundColor Gray
        }
    }
}

# 1. Aktualizovať version.json (hlavný zdroj verzie)
Write-Host "`n1. Aktualizácia version.json" -ForegroundColor Cyan
$versionJsonPath = ".\version.json"
if (Test-Path $versionJsonPath) {
    try {
        # Načítať JSON ako objekt a aktualizovať hodnoty
        $json = Get-Content -Raw -Path $versionJsonPath | ConvertFrom-Json
        $oldVersion = $json.version
        Write-Host "   • Aktuálna verzia: $oldVersion" -ForegroundColor Gray
        Write-Host "   • Nová verzia: $NewVersion" -ForegroundColor Yellow
        
        $json.version = $NewVersion
        # Aktualizácia releaseDate na dnešný dátum
        $json.releaseDate = Get-Date -Format 'yyyy-MM-dd'
        # Aktualizácia vlastnosti notes (nie note)
        $json.notes = "Aktualizácia na verziu $NewVersion z $(Get-Date -Format 'yyyy-MM-dd')"
        
        # Konvertovať späť na JSON a zapísať späť do súboru s rovnakým formátovaním
        $jsonString = $json | ConvertTo-Json -Depth 10
        Set-Content -Path $versionJsonPath -Value $jsonString -Encoding UTF8
        
        Write-Host "AKTUALIZOVANÉ: version.json" -ForegroundColor Green
    } catch {
        Write-Host "CHYBA pri aktualizácii version.json: $_" -ForegroundColor Red
    }
} else {
    Write-Host "CHYBA: Súbor version.json neexistuje!" -ForegroundColor Red
}

# 2. Aktualizovať sw.js - konštanta APP_VERSION
Write-Host "`n2. Aktualizácia sw.js" -ForegroundColor Cyan
$swJsPath = ".\sw.js"
if (Test-Path $swJsPath) {
    try {
        $content = Get-Content -Path $swJsPath -Raw -Encoding UTF8
        $oldContent = $content
        $pattern = "const APP_VERSION = '[0-9]+\.[0-9]+\.[0-9]+';"
        $replacement = "const APP_VERSION = '$NewVersion';"
        $content = $content -replace $pattern, $replacement
        
        if ($content -ne $oldContent) {
            Set-Content -Path $swJsPath -Value $content -Encoding UTF8
            Write-Host "AKTUALIZOVANÉ: sw.js - konštanta APP_VERSION" -ForegroundColor Green
        } else {
            Write-Host "PRESKOČENÉ: sw.js - nenájdená konštanta APP_VERSION alebo už aktuálna" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "CHYBA pri aktualizácii sw.js: $_" -ForegroundColor Red
    }
} else {
    Write-Host "CHYBA: Súbor sw.js neexistuje!" -ForegroundColor Red
}

# 3. Aktualizovať manifest.json
Write-Host "`n3. Aktualizácia manifest.json" -ForegroundColor Cyan
$manifestJsonPath = ".\manifest.json"
if (Test-Path $manifestJsonPath) {
    try {
        $content = Get-Content -Path $manifestJsonPath -Raw -Encoding UTF8
        $oldContent = $content
        
        # Aktualizácia verzie
        $pattern1 = '"version"\s*:\s*"[0-9]+\.[0-9]+\.[0-9]+"'
        $replacement1 = '"version": "' + $NewVersion + '"'
        $content = $content -replace $pattern1, $replacement1
        
        # Aktualizácia start_url
        $pattern2 = '"start_url"\s*:\s*"index\.html\?v=[0-9]+\.[0-9]+\.[0-9]+"'
        $replacement2 = '"start_url": "index.html?v=' + $NewVersion + '"'
        $content = $content -replace $pattern2, $replacement2
        
        # Aktualizácia url v shortcuts
        $pattern3 = '"url"\s*:\s*"index\.html\?v=[0-9]+\.[0-9]+\.[0-9]+"'
        $replacement3 = '"url": "index.html?v=' + $NewVersion + '"'
        $content = $content -replace $pattern3, $replacement3
        
        if ($content -ne $oldContent) {
            Set-Content -Path $manifestJsonPath -Value $content -Encoding UTF8
            Write-Host "AKTUALIZOVANÉ: manifest.json" -ForegroundColor Green
        } else {
            Write-Host "PRESKOČENÉ: manifest.json - nenájdené všetky patterny alebo už aktuálne" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "CHYBA pri aktualizácii manifest.json: $_" -ForegroundColor Red
    }
} else {
    Write-Host "CHYBA: Súbor manifest.json neexistuje!" -ForegroundColor Red
}

# 4. Aktualizovať index.html
Write-Host "`n4. Aktualizácia index.html" -ForegroundColor Cyan
$indexHtmlPath = ".\index.html"
if (Test-Path $indexHtmlPath) {
    try {
        $content = Get-Content -Path $indexHtmlPath -Raw -Encoding UTF8
        $oldContent = $content
        
        # Aktualizácia linku na manifest
        $pattern1 = '<link rel="manifest" href="manifest\.json\?v=[0-9]+\.[0-9]+\.[0-9]+">'
        $replacement1 = '<link rel="manifest" href="manifest.json?v=' + $NewVersion + '">'
        $content = $content -replace $pattern1, $replacement1
        
        # Aktualizácia service worker registrácie
        $pattern2 = "navigator\.serviceWorker\.register\('sw\.js\?v=[0-9]+\.[0-9]+\.[0-9]+'\)"
        $replacement2 = "navigator.serviceWorker.register('sw.js?v=$NewVersion')"
        $content = $content -replace $pattern2, $replacement2
        
        # Aktualizácia konštanty APP_VERSION
        $pattern3 = "const APP_VERSION = '[0-9]+\.[0-9]+\.[0-9]+';"
        $replacement3 = "const APP_VERSION = '$NewVersion';"
        $content = $content -replace $pattern3, $replacement3
        
        if ($content -ne $oldContent) {
            Set-Content -Path $indexHtmlPath -Value $content -Encoding UTF8
            Write-Host "AKTUALIZOVANÉ: index.html" -ForegroundColor Green
        } else {
            Write-Host "PRESKOČENÉ: index.html - nenájdené všetky patterny alebo už aktuálne" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "CHYBA pri aktualizácii index.html: $_" -ForegroundColor Red
    }
} else {
    Write-Host "CHYBA: Súbor index.html neexistuje!" -ForegroundColor Red
}

# Zobraziť súhrn
Write-Host "`n===== SÚHRN AKTUALIZÁCIE =====" -ForegroundColor Cyan
Write-Host "Verzia aplikácie bola aktualizovaná na $NewVersion" -ForegroundColor Green
Write-Host "`nNebudnite urobiť git commit, tag a push zmien!" -ForegroundColor Yellow
Write-Host "git add version.json sw.js manifest.json index.html" -ForegroundColor Gray
Write-Host "git commit -m `"Aktualizácia verzie na $NewVersion`"" -ForegroundColor Gray
Write-Host "git tag -a v$NewVersion -m `"Verzia $NewVersion`"" -ForegroundColor Gray
Write-Host "git push" -ForegroundColor Gray
Write-Host "git push --tags" -ForegroundColor Gray
Write-Host "`n===== HOTOVO! =====" -ForegroundColor Cyan

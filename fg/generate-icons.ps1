$svgPath = "logo.svg"
$iconsDir = "icons"

# Veľkosti ikon pre PWA
$sizes = @(72, 96, 128, 144, 152, 192, 384, 512)

# Vytvorenie priečinku pre ikony, ak neexistuje
if (-not (Test-Path $iconsDir)) {
    New-Item -ItemType Directory -Path $iconsDir | Out-Null
    Write-Host "Vytvorený priečinok $iconsDir"
}

# Generovanie PWA ikon
foreach ($size in $sizes) {
    $outputPath = "$iconsDir\icon-${size}x$size.png"
    magick convert -background none -density 1200 -resize ${size}x$size $svgPath $outputPath
    if (Test-Path $outputPath) {
        Write-Host "Vygenerovaná ikona: $outputPath"
    }
    else {
        Write-Host "Chyba pri generovaní ikony: $outputPath" -ForegroundColor Red
    }
}

# Generovanie favicon.ico (16x16, 32x32, 48x48)
$faviconPath = "favicon.ico"
magick convert -background none -density 1200 -resize 16x16 $svgPath "$iconsDir\favicon-16.png"
magick convert -background none -density 1200 -resize 32x32 $svgPath "$iconsDir\favicon-32.png"
magick convert -background none -density 1200 -resize 48x48 $svgPath "$iconsDir\favicon-48.png"
magick convert "$iconsDir\favicon-16.png" "$iconsDir\favicon-32.png" "$iconsDir\favicon-48.png" $faviconPath
if (Test-Path $faviconPath) {
    Write-Host "Vygenerovaný favicon: $faviconPath" -ForegroundColor Green
}

# Generovanie apple-touch-icon (špeciálne pre iOS)
$appleTouchIconPath = "apple-touch-icon.png"
magick convert -background '#FFFFFF' -flatten -density 1200 -resize 180x180 $svgPath $appleTouchIconPath
if (Test-Path $appleTouchIconPath) {
    Write-Host "Vygenerovaná apple-touch-icon: $appleTouchIconPath" -ForegroundColor Green
}

Write-Host "Generovanie ikon dokončené!" -ForegroundColor Green

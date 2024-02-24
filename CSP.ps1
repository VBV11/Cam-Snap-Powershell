# Trap ongevangen uitzonderingen om te voorkomen dat het script automatisch sluit
trap {
    Write-Host "Er is een fout opgetreden:`n$($_.Exception.Message)"
    Write-Host "Druk op een toets om door te gaan..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# Start de Camera app
Start-Process "microsoft.windows.camera:" -WindowStyle Maximized -ErrorAction Stop

# Wacht een paar seconden om de Camera app te starten
Start-Sleep -Seconds 5

# Simuleer een toetsaanslag om een foto te maken
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("{Enter}")

# Wacht een paar seconden om de foto te nemen
Start-Sleep -Seconds 5

# BeÃ«indig de Camera app
Get-Process "WindowsCamera" | Stop-Process -Force

# Wacht even om ervoor te zorgen dat de app correct wordt gesloten
Start-Sleep -Seconds 2

# Nieuwe Camera Roll-pad
$cameraRollPath = "C:\Users\BOLE130709\Pictures\Camera Roll"

# Zoek de nieuwste foto in de Camera Roll-map
$latestPhoto = Get-ChildItem $cameraRollPath | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Als er geen foto wordt gevonden, meld een fout en stop het script
if (-not $latestPhoto) {
    throw "Kan geen foto vinden in de Camera Roll-map."
}

# Definieer de map voor het opslaan van de foto (bureaublad)
$desktopPath = [Environment]::GetFolderPath("Desktop")

# Genereer een bestandsnaam voor de foto op het bureaublad
$fileName = "photo_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".jpg"

# Verplaats de foto naar het bureaublad
Move-Item $latestPhoto.FullName -Destination (Join-Path -Path $desktopPath -ChildPath $fileName) -Force -ErrorAction Stop

# Script voor het instellen van de achtergrond
$code = @'
using System.Runtime.InteropServices; 
namespace Win32 { 
    
    public class Wallpaper { 
        [DllImport("user32.dll", CharSet=CharSet.Auto)] 
        static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni); 
         
        public static void SetWallpaper(string thePath) { 
            SystemParametersInfo(20, 0, thePath, 3); 
        }
    }
}
'@

# Toevoegen van de .NET-type definitie
Add-Type $code 

# Pad voor de tijdelijke afbeelding die wordt gebruikt voor de achtergrond
$imagePath = "$env:TEMP\image.jpg"

# Kopieer de foto naar de tijdelijke map
Copy-Item (Join-Path -Path $desktopPath -ChildPath $fileName) -Destination $imagePath -Force -ErrorAction Stop

# Instellen van de achtergrond met de foto
[Win32.Wallpaper]::SetWallpaper($imagePath)
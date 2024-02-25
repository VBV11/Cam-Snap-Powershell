# Trap unhandled exceptions to prevent the script from automatically closing
trap {
    Write-Host "An error occurred:`n$($_.Exception.Message)"
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# Function to set the camera roll path
function Set-CameraRollPath {
    param (
        [string]$newPath
    )

    # Setting the new camera roll path
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{AB5FB87B-7CE2-4F83-915D-550846C9537B}" -Value $newPath

    # Refresh the shell
    $null = (New-Object -ComObject Shell.Application).NameSpace(0).Self.InvokeVerb("Ref&resh")
}

# New path for the camera roll (change this to your desired location)
$newCameraRollPath = "$env:userprofile\Pictures\CameraRoll"

# Check if the new path exists, if not, create it
if (-not (Test-Path -Path $newCameraRollPath)) {
    New-Item -ItemType Directory -Path $newCameraRollPath
}

# Set the new camera roll path
Set-CameraRollPath -newPath $newCameraRollPath

# Start the Camera app
Start-Process "microsoft.windows.camera:" -WindowStyle Maximized -ErrorAction Stop

# Wait a few seconds to start the Camera app
Start-Sleep -Seconds 5

# Simulate a keypress to take a photo
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("{Enter}")

# Wait a few seconds to take the photo
Start-Sleep -Seconds 5

# Close the Camera app
Get-Process "WindowsCamera" | Stop-Process -Force

# Wait a bit to ensure the app closes properly
Start-Sleep -Seconds 2

# New Camera Roll path
$cameraRollPath = $newCameraRollPath

# Find the latest photo in the Camera Roll folder
$latestPhoto = Get-ChildItem $cameraRollPath | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# If no photo is found, report an error and stop the script
if (-not $latestPhoto) {
    throw "Unable to find a photo in the Camera Roll folder."
}

# Define the folder to save the photo (Desktop)
$desktopPath = [Environment]::GetFolderPath("Desktop")

# Generate a filename for the photo on the desktop
$fileName = "photo_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".jpg"

# Move the photo to the desktop
Move-Item $latestPhoto.FullName -Destination (Join-Path -Path $desktopPath -ChildPath $fileName) -Force -ErrorAction Stop

# Script for setting the wallpaper
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

# Add the .NET type definition
Add-Type $code 

# Path for the temporary image used for the wallpaper
$imagePath = "$env:TEMP\image.jpg"

# Copy the photo to the temporary folder
Copy-Item (Join-Path -Path $desktopPath -ChildPath $fileName) -Destination $imagePath -Force -ErrorAction Stop

# Set the wallpaper with the photo
[Win32.Wallpaper]::SetWallpaper($imagePath)

# Cam Snap Powershell
This script automates the process of capturing a photo using the Windows Camera app, saving it to the Camera Roll folder, and setting it as the desktop wallpaper.

# Prerequisites
+ Windows operating system.
+ Windows Camera app installed.
+ PowerShell scripting environment.
# Instructions
Download the Script: Download the CSP.ps1 script to your local machine.

Run the Script: Right-click on the script file and select "Run with PowerShell" to execute the script. Alternatively, you can open PowerShell, navigate to the directory where the script is located, and run it using the command .\CSP.ps1.

Follow On-Screen Prompts: The script will start the Windows Camera app, take a photo, save it to the Camera Roll folder, and set it as the desktop wallpaper. Follow any on-screen prompts if necessary.

Review Output: After execution, check your desktop background to verify that the new photo has been set as the wallpaper.

# Notes
Ensure that the Windows Camera app is properly installed and functional before running the script.
Make sure to grant necessary permissions for the script to access system folders and execute commands.
Customize the script variables such as $newCameraRollPath to specify your desired location for the Camera Roll folder.
This script may need to be run with administrative privileges depending on system configurations.
Troubleshooting
Error Handling: If any errors occur during execution, the script will display error messages and prompt you to press any key to continue. Review the error messages to troubleshoot issues.
Permissions: Ensure that the user running the script has necessary permissions to access system folders and execute PowerShell commands.
Camera App Issues: If the Windows Camera app does not function as expected, troubleshoot any app-related issues separately.
File Operations: If the script fails during file operations (copying photos, setting wallpaper), ensure that the specified paths are correct and accessible.
Disclaimer
This script is provided as-is without any warranty. Use it at your own risk. The author is not responsible for any damages caused by the use or misuse of this script.

# Author
This script was authored by VBV11.

# The script in pieces

## Trap unhandled exceptions to prevent the script from automatically closing
trap {
    Write-Host "An error occurred:`n$($_.Exception.Message)"
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

## Function to set the camera roll path
function Set-CameraRollPath {
    param (
        [string]$newPath
    )

    # Setting the new camera roll path
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{AB5FB87B-7CE2-4F83-915D-550846C9537B}" -Value $newPath

    # Refresh the shell
    $null = (New-Object -ComObject Shell.Application).NameSpace(0).Self.InvokeVerb("Ref&resh")
}

## New path for the camera roll (change this to your desired location)
`$newCameraRollPath = "$env:userprofile\Pictures\CameraRoll"`

# Check if the new path exists, if not, create it
`if (-not (Test-Path -Path $newCameraRollPath)) {
    New-Item -ItemType Directory -Path $newCameraRollPath
}`

## Set the new camera roll path
`Set-CameraRollPath -newPath $newCameraRollPath`

## Start the Camera app
`Start-Process "microsoft.windows.camera:" -WindowStyle Maximized -ErrorAction Stop`

## Wait a few seconds to start the Camera app
Start-Sleep -Seconds 5

## Simulate a keypress to take a photo
`Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("{Enter}")`

## Wait a few seconds to take the photo
`Start-Sleep -Seconds 5`

## Close the Camera app
`Get-Process "WindowsCamera" | Stop-Process -Force`

## Wait a bit to ensure the app closes properly
`Start-Sleep -Seconds 2`

## New Camera Roll path
`$cameraRollPath = $newCameraRollPath`

## Find the latest photo in the Camera Roll folder
`$latestPhoto = Get-ChildItem $cameraRollPath | Sort-Object LastWriteTime -Descending | Select-Object -First 1`

## If no photo is found, report an error and stop the script
`if (-not $latestPhoto) {
    throw "Unable to find a photo in the Camera Roll folder."
}`

## Define the folder to save the photo (Desktop)
`$desktopPath = [Environment]::GetFolderPath("Desktop")`

## Generate a filename for the photo on the desktop
`$fileName = "photo_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".jpg"`

## Move the photo to the desktop
`Move-Item $latestPhoto.FullName -Destination (Join-Path -Path $desktopPath -ChildPath $fileName) -Force -ErrorAction Stop`

## Script for setting the wallpaper
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

## Add the .NET type definition
`Add-Type $code `

## Path for the temporary image used for the wallpaper
`$imagePath = "$env:TEMP\image.jpg"`

## Copy the photo to the temporary folder
`Copy-Item (Join-Path -Path $desktopPath -ChildPath $fileName) -Destination $imagePath -Force -ErrorAction Stop`

## Set the wallpaper with the photo
`[Win32.Wallpaper]::SetWallpaper($imagePath)`

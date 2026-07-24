# Strips the alpha channel from the App Store screenshots (App Store Connect
# rejects PNGs with transparency). Rewrites each file as 24-bit RGB in place.
Add-Type -AssemblyName System.Drawing

Get-ChildItem "$PSScriptRoot\appstore\*.png", "$PSScriptRoot\appstore_ipad\*.png" | ForEach-Object {
    $img = [System.Drawing.Bitmap]::FromFile($_.FullName)
    $flat = New-Object System.Drawing.Bitmap($img.Width, $img.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $gfx = [System.Drawing.Graphics]::FromImage($flat)
    $gfx.Clear([System.Drawing.Color]::White)
    $gfx.DrawImage($img, 0, 0, $img.Width, $img.Height)
    $gfx.Dispose(); $img.Dispose()
    $tmp = "$($_.FullName).tmp"
    $flat.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
    $flat.Dispose()
    Move-Item -Force $tmp $_.FullName
    Write-Output "$($_.Name): flattened to 24bpp"
}

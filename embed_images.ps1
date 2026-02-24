$basePath = "c:\Users\79514\Desktop\Antigravity\Life_Strategy\Portfolio\02_Legal_RAG"
$htmlFile = Join-Path $basePath "HR_RAG_antigravity.html"

Write-Host "Reading HTML file..."
$htmlContent = [System.IO.File]::ReadAllText($htmlFile, [System.Text.Encoding]::UTF8)

$images = @(
    "1_botfather..jpg",
    "Gorq-1.jpg",
    "Groq_2.jpg",
    "Groq_3.jpg",
    "OpenRouter-1.jpg",
    "OpenRouter-2.jpg",
    "OpenRouter-3.jpg",
    "Screenshot_2.jpg",
    "Zarub_1.jpg"
)

foreach ($img in $images) {
    $imgPath = Join-Path $basePath $img
    if (Test-Path $imgPath) {
        Write-Host "Embedding $img..."
        $bytes = [System.IO.File]::ReadAllBytes($imgPath)
        $b64 = [System.Convert]::ToBase64String($bytes)
        
        $mime = "image/jpeg"
        if ($img.ToLower().EndsWith(".png")) { $mime = "image/png" }
        
        $dataUri = "data:$mime;base64,$b64"
        
        # Exact string replacement for src="filename.jpg"
        $searchStr = 'src="' + $img + '"'
        $replaceStr = 'src="' + $dataUri + '"'
        
        if ($htmlContent.Contains($searchStr)) {
            $htmlContent = $htmlContent.Replace($searchStr, $replaceStr)
            Write-Host "  -> Success"
        } else {
            Write-Host "  -> Warning: Tag not found in HTML"
        }
    } else {
        Write-Host "  -> Error: Image not found: $imgPath"
    }
}

Write-Host "Saving HTML file..."
[System.IO.File]::WriteAllText($htmlFile, $htmlContent, [System.Text.Encoding]::UTF8)
Write-Host "Done! Images embedded."

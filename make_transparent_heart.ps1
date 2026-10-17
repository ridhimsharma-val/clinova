Add-Type -AssemblyName System.Drawing

function Remove-Checkerboard($inputPath, $outputPath) {
    $src = [System.Drawing.Bitmap]::FromFile($inputPath)
    $out = New-Object System.Drawing.Bitmap($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    
    # We do a flood-fill or BFS from the corners to find all checkerboard background pixels.
    # Pixels outside the green heart border are transparent.
    # The heart border is dark forest green (R < 100, G > 70, B > 50).
    $visited = New-Object 'bool[,]' $src.Width, $src.Height
    $queue = New-Object System.Collections.Generic.Queue[System.Drawing.Point]
    
    # Push all 4 borders to queue
    for ($x = 0; $x -lt $src.Width; $x++) {
        $queue.Enqueue((New-Object System.Drawing.Point($x, 0)))
        $queue.Enqueue((New-Object System.Drawing.Point($x, ($src.Height - 1))))
        $visited[$x, 0] = $true
        $visited[$x, ($src.Height - 1)] = $true
    }
    for ($y = 0; $y -lt $src.Height; $y++) {
        $queue.Enqueue((New-Object System.Drawing.Point(0, $y)))
        $queue.Enqueue((New-Object System.Drawing.Point(($src.Width - 1), $y)))
        $visited[0, $y] = $true
        $visited[($src.Width - 1), $y] = $true
    }

    # BFS: expand through all background pixels (white/gray/checkerboard) until reaching the dark green heart border
    while ($queue.Count -gt 0) {
        $pt = $queue.Dequeue()
        $px = $pt.X
        $py = $pt.Y
        
        # Out pixel is transparent
        $out.SetPixel($px, $py, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        
        $neighbors = @(
            (New-Object System.Drawing.Point(($px + 1), $py)),
            (New-Object System.Drawing.Point(($px - 1), $py)),
            (New-Object System.Drawing.Point($px, ($py + 1))),
            (New-Object System.Drawing.Point($px, ($py - 1)))
        )
        
        foreach ($n in $neighbors) {
            if ($n.X -ge 0 -and $n.X -lt $src.Width -and $n.Y -ge 0 -and $n.Y -lt $src.Height) {
                if (-not $visited[$n.X, $n.Y]) {
                    $c = $src.GetPixel($n.X, $n.Y)
                    # Check if pixel is background (checkerboard/white/gray/diffuse shadow)
                    # The heart outer stroke is dark forest green: R < 70, G between 60 and 150, B < 90
                    # Checkerboard has R > 170, G > 170, B > 170
                    $isBackground = ($c.R -gt 150 -and $c.G -gt 150 -and $c.B -gt 150)
                    if ($isBackground) {
                        $visited[$n.X, $n.Y] = $true
                        $queue.Enqueue($n)
                    }
                }
            }
        }
    }
    
    # Fill remaining unvisited pixels directly from source
    for ($y = 0; $y -lt $src.Height; $y++) {
        for ($x = 0; $x -lt $src.Width; $x++) {
            if (-not $visited[$x, $y]) {
                $out.SetPixel($x, $y, $src.GetPixel($x, $y))
            }
        }
    }
    
    $out.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $src.Dispose()
    $out.Dispose()
    Write-Output "Transparent heart created at $outputPath"
}

Remove-Checkerboard 'C:\flutter\projects\Clinova\assets\images\heart.png' 'C:\flutter\projects\Clinova\assets\images\heart_clean.png'

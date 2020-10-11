$script:header = @{"Authorization" = "token $($env:GITHUB_TOKEN)" }

function Export-Gist {
    param(
        $Description = 'Uploaded via PowerShell',
        [Switch]$AsSeparateGists,
        [Switch]$DoNotLaunchBrowser,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias ('FullName')]
        $Path
    )

    Begin {
        if (!(test-path env:github_token)) {
            throw "env:github_token not set. You need to set it to a GitHub PAT - https://github.com/settings/tokens"
        }

        $targetFiles = @()

        $gist = @{
            'description' = $Description
            'public'      = $false
            'files'       = @{}
        }
    }
                    
    Process {
        $targetFiles += $Path
    }
    
    End {
        if (!$AsSeparateGists) {
            $gist.files = @{}
            foreach ($file in $targetFiles) {
                Write-Progress -Activity "Export Gist" -Status "Processing file $file"

                $leaf = Split-Path -Leaf $file                 
                $content = Get-Content -Raw $file
                $gist.files["$leaf"] = @{'content' = $content.ToString() }
            }

            Invoke-SendGist $gist -DoNotLaunchBrowser:$DoNotLaunchBrowser
        }
        else {
            foreach ($file in $targetFiles) {               
                Write-Progress -Activity "Export Gist" -Status "Processing file $file"
                
                $leaf = Split-Path -Leaf $file                 
                $content = Get-Content -Raw $file
                $gist.files = @{}

                $gist.files["$leaf"] = @{'content' = $content.ToString() }
         
                Invoke-SendGist $gist -DoNotLaunchBrowser:$DoNotLaunchBrowser
            }
        }
    }
}

function Invoke-SendGist {
    param(
        [hashtable]$TargetGist,
        [Switch]$DoNotLaunchBrowser
    )

    try {
        $Error.Clear()
        $gist = $TargetGist | ConvertTo-Json
        $result = Invoke-RestMethod -Method Post -Uri 'https://api.github.com/gists' -Headers $Header -Body $gist

        $result.html_url
        if ($DoNotLaunchBrowser) {
        }
        else {
            Start-Process $result.html_url
        }
    }
    catch {
        [PSCustomObject][Ordered]@{
            Error = $_.ErrorDetails.Message | ConvertFrom-Json | ForEach-Object message        
            Gist  = $gist | ConvertFrom-Json
        }
    }
}
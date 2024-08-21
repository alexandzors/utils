# This script monitors a url attached to a local cloudflare tunnel service on Windows. If it gets anything but a status 200 (OK) it restarts the local cloudflared service.
# Its best to have this run via task scheduler on Windows startup with admin priviledges and no logon.

# vars
$url = "https://url-to-monitor-cf-tunnel.com"
$serviceName = "cloudflared"
$logFile = "/dir/to/log.log"
$maxLogSizeMB = 5
$maxLogFiles = 3
$sleepint = 30

# check website status
function Check-WebsiteStatus {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
        return $response.StatusCode
    } catch {
        return $null
    }
}

# log messages with timestamps
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logMessage
    Rotate-Log
}

# rotate logs
function Rotate-Log {
    $logSizeMB = (Get-Item $logFile).Length / 1MB
    if ($logSizeMB -ge $maxLogSizeMB) {
        for ($i = $maxLogFiles - 1; $i -ge 1; $i--) {
            $oldLog = "$logFile.$i"
            $newLog = "$logFile." + ($i + 1)
            if (Test-Path $oldLog) {
                Rename-Item -Path $oldLog -NewName $newLog -Force
            }
        }
        Rename-Item -Path $logFile -NewName "$logFile.1" -Force
        New-Item -Path $logFile -ItemType File
    }
}

# restart the service
function Restart-ServiceIfNeeded {
    $statusCode = Check-WebsiteStatus
    if ($statusCode -ne 200) {
        Write-Log "Website is down or returning unexpected status ($statusCode). Restarting $serviceName service..."
        Restart-Service -Name $serviceName
    } else {
        Write-Log "Website is up and running. Status code: $statusCode"
    }
}

# main loop
while ($true) {
    Restart-ServiceIfNeeded
    Start-Sleep -Seconds $sleepint
}

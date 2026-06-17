param(
    [int]$IntervalSeconds = 15,
    [int]$HttpPort = 8001,
    [int]$WebSocketPort = 6505,
    [string]$ProjectRoot = "E:\pengfei"
)

$ErrorActionPreference = "Continue"

$startScript = Join-Path $ProjectRoot "tools\Start-GodotMcpHttp.ps1"
$watchLog = Join-Path $env:TEMP "godot_mcp_pro_watchdog.log"

function Write-WatchLog {
    param([string]$Message)
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $watchLog -Value "[$stamp] $Message"
}

function Get-McpHttpProcess {
    Get-CimInstance Win32_Process |
        Where-Object {
            $_.Name -eq "node.exe" -and
            $_.CommandLine -like "*D:/godot-mcp-pro/server/build/index.js*" -and
            $_.CommandLine -like "*--http*" -and
            $_.CommandLine -like "*--http-port $HttpPort*"
        }
}

function Test-PortOwnedByProcess {
    param(
        [int]$Port,
        [int]$ProcessId
    )

    $conn = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalPort -eq $Port -and $_.OwningProcess -eq $ProcessId } |
        Select-Object -First 1
    return $null -ne $conn
}

Write-WatchLog "Watchdog started. HTTP=$HttpPort WS=$WebSocketPort interval=${IntervalSeconds}s"

while ($true) {
    try {
        $process = Get-McpHttpProcess | Select-Object -First 1
        $healthy = $false

        if ($process) {
            $hasHttp = Test-PortOwnedByProcess -Port $HttpPort -ProcessId $process.ProcessId
            $hasWs = Test-PortOwnedByProcess -Port $WebSocketPort -ProcessId $process.ProcessId
            $healthy = $hasHttp -and $hasWs
        }

        if (-not $healthy) {
            $pidText = if ($process) { [string]$process.ProcessId } else { "none" }
            Write-WatchLog "MCP unhealthy. Existing PID=$pidText. Restarting..."
            powershell.exe -NoProfile -ExecutionPolicy Bypass -File $startScript -HttpPort $HttpPort -WebSocketPort $WebSocketPort |
                ForEach-Object { Write-WatchLog $_ }
        }
    }
    catch {
        Write-WatchLog "Watchdog error: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds $IntervalSeconds
}

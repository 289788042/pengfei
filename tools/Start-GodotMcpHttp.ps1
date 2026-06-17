param(
    [int]$HttpPort = 8001,
    [int]$WebSocketPort = 6505,
    [string]$NodePath = "D:\Node\node.exe",
    [string]$ServerPath = "D:/godot-mcp-pro/server/build/index.js"
)

$ErrorActionPreference = "Stop"

function Get-McpHttpProcess {
    Get-CimInstance Win32_Process |
        Where-Object {
            $_.Name -eq "node.exe" -and
            $_.CommandLine -like "*$ServerPath*" -and
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

$outLog = Join-Path $env:TEMP "godot_mcp_pro_http.out.log"
$errLog = Join-Path $env:TEMP "godot_mcp_pro_http.err.log"
$process = Get-McpHttpProcess | Select-Object -First 1

if ($process) {
    $hasHttp = Test-PortOwnedByProcess -Port $HttpPort -ProcessId $process.ProcessId
    $hasWs = Test-PortOwnedByProcess -Port $WebSocketPort -ProcessId $process.ProcessId
    if ($hasHttp -and $hasWs) {
        Write-Output "Godot MCP HTTP server already healthy. PID=$($process.ProcessId)"
        exit 0
    }

    Write-Output "Stopping unhealthy Godot MCP HTTP server. PID=$($process.ProcessId)"
    Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

$args = @($ServerPath, "--http", "--http-port", [string]$HttpPort)
$started = Start-Process -FilePath $NodePath `
    -ArgumentList $args `
    -WindowStyle Hidden `
    -PassThru `
    -RedirectStandardOutput $outLog `
    -RedirectStandardError $errLog

Start-Sleep -Seconds 5

$hasHttp = Test-PortOwnedByProcess -Port $HttpPort -ProcessId $started.Id
$hasWs = Test-PortOwnedByProcess -Port $WebSocketPort -ProcessId $started.Id

if (-not ($hasHttp -and $hasWs)) {
    throw "Godot MCP HTTP server failed to bind required ports. PID=$($started.Id), HTTP=$hasHttp, WS=$hasWs"
}

Write-Output "Started Godot MCP HTTP server. PID=$($started.Id), HTTP=$HttpPort, WS=$WebSocketPort"

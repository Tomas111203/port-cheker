<#
.SYNOPSIS
    Verifica si un puerto esta abierto o cerrado en un host dado.
.DESCRIPTION
    Script para ejecutar directamente en Windows 11 (fuera de Docker).
.PARAMETER Puerto
    Numero de puerto (1-65535).
.PARAMETER Host
    Host o IP a verificar. Por defecto: 127.0.0.1
.PARAMETER Timeout
    Timeout en milisegundos. Por defecto: 3000
.EXAMPLE
    .\Check-Port.ps1 -Puerto 8080
    .\Check-Port.ps1 -Puerto 443 -Host google.com
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateRange(1,65535)]
    [int]$Puerto,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$HostDestino = "127.0.0.1",

    [Parameter(Mandatory=$false)]
    [int]$Timeout = 3000
)

Write-Host "[*] Verificando puerto $Puerto en $HostDestino (timeout ${Timeout}ms)..." -ForegroundColor Cyan

try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connect   = $tcpClient.BeginConnect($HostDestino, $Puerto, $null, $null)
    $wait      = $connect.AsyncWaitHandle.WaitOne($Timeout, $false)

    if (-not $wait) {
        $tcpClient.Close()
        Write-Host "[X] El puerto $Puerto esta CERRADO en $HostDestino (timeout)" -ForegroundColor Red
        exit 1
    }
    else {
        $tcpClient.EndConnect($connect)
        $tcpClient.Close()
        Write-Host "[OK] El puerto $Puerto esta ABIERTO en $HostDestino" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Host "[X] El puerto $Puerto esta CERRADO en $HostDestino" -ForegroundColor Red
    Write-Host "    Detalle: $($_.Exception.Message)" -ForegroundColor DarkGray
    exit 1
}
# ==========================================
# 网络配置固定工具（终极稳定版 · Metric 优选 + 网关显示优化）
# 自动选 Metric 最小网关，Metric 空值隐藏，去掉多余符号
# ==========================================

# ---------- 自动提权 ----------
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---------- UI ----------
function Show-Header {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   网络配置固定工具（终极稳定版）" -ForegroundColor White
    Write-Host "   自动选 Metric 最小网关 → 固定 IP / DHCP" -ForegroundColor DarkGray
    Write-Host "==========================================" -ForegroundColor Cyan
}

# ---------- 选择适配器 ----------
function Select-Adapter {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    if (-not $adapters) {
        Write-Host "[错误] 未检测到已连接的网络适配器。" -ForegroundColor Red
        return $null
    }

    $map = @{}
    $i = 0
    foreach ($a in $adapters) {
        $i++
        $map[$i] = $a
        Write-Host "$i. $($a.Name) [$($a.InterfaceDescription)]"
    }

    $sel = Read-Host "`n请选择适配器编号"
    if ($sel -notmatch '^\d+$' -or -not $map.ContainsKey([int]$sel)) {
        Write-Host "选择无效。" -ForegroundColor Yellow
        return $null
    }

    return $map[[int]$sel].Name
}

# ---------- 显示当前状态 ----------
function Show-AdapterStatus($alias) {
    $ipif = Get-NetIPInterface -InterfaceAlias $alias -AddressFamily IPv4
    $cfg  = Get-NetIPConfiguration -InterfaceAlias $alias

    $mode = if ($ipif.Dhcp -eq "Enabled") { "DHCP 动态" } else { "固定 IP" }

    Write-Host "`n当前适配器: $alias" -ForegroundColor Cyan
    Write-Host "IP 模式 : $mode"

    if ($cfg.IPv4Address) {
        Write-Host "IP 地址 : $($cfg.IPv4Address.IPAddress)"
        
        # ⚡ 网关显示优化：Metric 空值隐藏，数组 -join 输出，无 + 号
        $gws = $cfg.IPv4DefaultGateway | ForEach-Object {
            if ($_.Metric) { "$($_.NextHop) (Metric $($_.Metric))" } else { "$($_.NextHop)" }
        }
        $gwsStr = $gws -join ", "
        if ($gwsStr) {
            Write-Host "网关     : $gwsStr"
        } else { 
            Write-Host "网关     : 无" 
        }

        Write-Host "DNS      : $($cfg.DnsServer.ServerAddresses -join ', ')"
    }
}

# ---------- 固定 IP ----------
function Set-StaticIP($alias) {
    Show-Header
    Show-AdapterStatus $alias

    $cfg = Get-NetIPConfiguration -InterfaceAlias $alias
    $ipv4   = $cfg.IPv4Address.IPAddress
    $prefix = $cfg.IPv4Address.PrefixLength
    $dns    = $cfg.DnsServer.ServerAddresses

    # 自动选 Metric 最小网关
    $gws = $cfg.IPv4DefaultGateway | Sort-Object Metric | Select-Object -First 1
    $gw  = if ($gws) { $gws.NextHop } else { "" }

    if (-not $ipv4 -or $ipv4 -like "169.254.*") {
        Write-Host "`n检测到无效 IP，请手动输入：" -ForegroundColor Yellow
        $ipv4   = Read-Host "IP 地址"
        $gw     = Read-Host "网关地址"
        $prefix = 24
        $dns    = $gw
    }

    $confirm = Read-Host "`n确认将 [$alias] 固定为该配置? (y/n)"
    if ($confirm -ne "y") {
        Write-Host "已取消。" -ForegroundColor Yellow
        Read-Host "回车返回..."
        return
    }

    try {
        Write-Host "`n[1/5] 禁用 DHCP..." -ForegroundColor Yellow
        Set-NetIPInterface -InterfaceAlias $alias -Dhcp Disabled -ErrorAction Stop

        Write-Host "[2/5] 清理 IP / 路由残留..." -ForegroundColor Yellow
        Remove-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        Get-NetRoute -InterfaceAlias $alias -AddressFamily IPv4 -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
            Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

        Set-NetIPInterface -InterfaceAlias $alias -AutomaticMetric Disabled -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500

        Write-Host "[3/5] 写入静态 IP..." -ForegroundColor Yellow
        New-NetIPAddress `
            -InterfaceAlias $alias `
            -IPAddress $ipv4 `
            -PrefixLength $prefix `
            -AddressFamily IPv4 `
            -ErrorAction Stop | Out-Null

        Write-Host "[4/5] 重建默认路由 (Metric 最小)..." -ForegroundColor Yellow
        if ($gw) {
            New-NetRoute `
                -InterfaceAlias $alias `
                -DestinationPrefix "0.0.0.0/0" `
                -NextHop $gw `
                -RouteMetric 10 `
                -PolicyStore ActiveStore `
                -ErrorAction Stop | Out-Null
        }

        Write-Host "[5/5] 设置 DNS..." -ForegroundColor Yellow
        if ($dns) {
            Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses $dns -ErrorAction SilentlyContinue
        }

        Write-Host "`n[成功] 网络配置已固定 ✅" -ForegroundColor Green
    }
    catch {
        Write-Host "`n[失败] $($_.Exception.Message)" -ForegroundColor Red
    }

    Read-Host "回车返回..."
}

# ---------- 恢复 DHCP ----------
function Restore-Dhcp($alias) {
    Show-Header
    Show-AdapterStatus $alias

    $confirm = Read-Host "`n确认恢复 [$alias] 为 DHCP? (y/n)"
    if ($confirm -ne "y") {
        Write-Host "已取消。" -ForegroundColor Yellow
        Read-Host "回车返回..."
        return
    }

    Set-NetIPInterface -InterfaceAlias $alias -Dhcp Enabled -ErrorAction SilentlyContinue
    Set-NetIPInterface -InterfaceAlias $alias -AutomaticMetric Enabled -ErrorAction SilentlyContinue
    Set-DnsClientServerAddress -InterfaceAlias $alias -ResetServerAddresses -ErrorAction SilentlyContinue

    Write-Host "`n[成功] 已恢复 DHCP 自动获取 ✅" -ForegroundColor Green
    Read-Host "回车返回..."
}

# ---------- 主循环 ----------
do {
    Show-Header
    $alias = Select-Adapter
    if (-not $alias) { continue }

    Show-AdapterStatus $alias

    Write-Host "`n请选择操作：" -ForegroundColor Cyan
    Write-Host "1. 固定当前 IP"
    Write-Host "2. 切换为 DHCP"
    Write-Host "3. 重新选择网卡"
    Write-Host "4. 退出"

    $opt = Read-Host "`n输入编号"
    switch ($opt) {
        "1" { Set-StaticIP $alias }
        "2" { Restore-Dhcp $alias }
        "3" { continue }
        "4" { break }
    }
} while ($true)

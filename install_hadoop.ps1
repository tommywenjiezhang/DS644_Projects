# --- Define connection info
$key = ".\ds644.pem"
$master_host = "ubuntu@xxxxxxx.compute-1.amazonaws.com"

$sshOpts = @(
  "-i", $key,
  "-o","StrictHostKeyChecking=no",
  "-o","UserKnownHostsFile=/dev/null",
  "-o","BatchMode=yes",
  "-o","ConnectTimeout=10"
)

# --- Local script to upload
$localScript = ".\install_hadoop_265.sh"
if (-not (Test-Path $localScript)) {
  throw "Local script not found: $localScript"
}

# --- Build scp destination safely (avoid ':' variable parsing)
$dest = ("{0}:/tmp/install_hadoop_265.sh" -f $master_host)

Write-Host ("[scp] -> {0}" -f $dest)
& scp @sshOpts $localScript $dest
if ($LASTEXITCODE -ne 0) { throw "scp failed with code $LASTEXITCODE" }

# --- Remote one-liner: strip CR, chmod, run
# Use a *single-quoted* PS string and double the inner single-quotes.
$remoteCmd = 'tr -d ''\r'' < /tmp/install_hadoop_265.sh > /tmp/install_hadoop_265.sh.lf && mv /tmp/install_hadoop_265.sh.lf /tmp/install_hadoop_265.sh && chmod +x /tmp/install_hadoop_265.sh && /bin/sh /tmp/install_hadoop_265.sh'

Write-Host "[ssh] executing installer on master..."
# Pass the command as a single argument; no extra quoting gymnastics needed
& ssh @sshOpts $master_host $remoteCmd 2>&1 | ForEach-Object { Write-Host "[$master_host] $_" }

if ($LASTEXITCODE -eq 0) {
  Write-Host "[$master_host] SUCCESS" -ForegroundColor Green
} else {
  Write-Host "[$master_host] FAILED with code $LASTEXITCODE" -ForegroundColor Red
}

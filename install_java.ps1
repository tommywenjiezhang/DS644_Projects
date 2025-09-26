$key = ".\ds644.pem"
$hosts = @(
  "ubuntu@xxxxxxx.compute-1.amazonaws.com",
  "ubuntu@xxxxxxx.compute-1.amazonaws.com",
  "ubuntu@xxxxxxx.compute-1.amazonaws.com",
  "ubuntu@xxxxxxx.compute-1.amazonaws.com"
)

$sshOpts = @(
    "-i", $key,
    "-o","StrictHostKeyChecking=no",
    "-o","UserKnownHostsFile=/dev/null"
)

foreach ($h in $hosts) {
  Write-Host "=== [$h] Install OpenJDK 8 and set JAVA_HOME ==="
  $cmd = @"
sudo apt-get update -y &&
sudo apt-get install -y openjdk-8-jdk &&
cd /usr/lib/jvm &&
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bash_profile &&
echo 'export PATH=\$JAVA_HOME/bin:\$PATH' >> ~/.bash_profile &&
source ~/.bash_profile &&
java -version
"@
  & ssh @sshOpts $h $cmd 2>&1 | ForEach-Object { Write-Host "[$h] $_" }
  if ($LASTEXITCODE -eq 0) {
    Write-Host "[$h] SUCCESS" -ForegroundColor Green
  } else {
    Write-Host "[$h] FAILED with code $LASTEXITCODE" -ForegroundColor Red
  }
}

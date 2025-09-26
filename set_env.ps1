# --- Connection info
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
  "-o","UserKnownHostsFile=/dev/null",
  "-o","BatchMode=yes",
  "-o","ConnectTimeout=10"
)

# --- Build a POSIX /bin/sh script as LF-only to avoid CR issues
$lines = @(
  'f="$HOME/.bash_profile"',
  'touch "$f"',
  # strip any CRs from previous attempts (sed exists on Ubuntu)
  'if [ -f "$f" ]; then sed -i "s/\r$//" "$f" 2>/dev/null; fi',

  # Append only if missing (idempotent)
  'if ! grep -qxF ''export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64'' "$f"; then printf ''%s\n'' ''export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64'' >> "$f"; fi',
  'if ! grep -qxF ''export HADOOP_HOME=/home/ubuntu/hadoop-2.6.5'' "$f"; then printf ''%s\n'' ''export HADOOP_HOME=/home/ubuntu/hadoop-2.6.5'' >> "$f"; fi',
  'if ! grep -qxF ''export PATH=$JAVA_HOME/bin:$PATH'' "$f"; then printf ''%s\n'' ''export PATH=$JAVA_HOME/bin:$PATH'' >> "$f"; fi',
  'if ! grep -qxF ''export PATH=$PATH:$HADOOP_HOME/bin'' "$f"; then printf ''%s\n'' ''export PATH=$PATH:$HADOOP_HOME/bin'' >> "$f"; fi',
  'if ! grep -qxF ''export PATH=$PATH:$HADOOP_HOME/sbin'' "$f"; then printf ''%s\n'' ''export PATH=$PATH:$HADOOP_HOME/sbin'' >> "$f"; fi',
  'if ! grep -qxF ''export HADOOP_MAPRED_HOME=$HADOOP_HOME'' "$f"; then printf ''%s\n'' ''export HADOOP_MAPRED_HOME=$HADOOP_HOME'' >> "$f"; fi',
  'if ! grep -qxF ''export HADOOP_COMMON_HOME=$HADOOP_HOME'' "$f"; then printf ''%s\n'' ''export HADOOP_COMMON_HOME=$HADOOP_HOME'' >> "$f"; fi',
  'if ! grep -qxF ''export HADOOP_HDFS_HOME=$HADOOP_HOME'' "$f"; then printf ''%s\n'' ''export HADOOP_HDFS_HOME=$HADOOP_HOME'' >> "$f"; fi',
  'if ! grep -qxF ''export YARN_HOME=$HADOOP_HOME'' "$f"; then printf ''%s\n'' ''export YARN_HOME=$HADOOP_HOME'' >> "$f"; fi',

  # Apply for current session (no "|| true")
  '. "$f" >/dev/null 2>&1',

  # Verify
  'printf ''JAVA_HOME=%s\n'' "$JAVA_HOME"',
  'printf ''HADOOP_HOME=%s\n'' "$HADOOP_HOME"',
  'command -v java >/dev/null 2>&1 && java -version || printf ''java not found\n'''
)
$remote = [string]::Join("`n", $lines)

foreach ($h in $hosts) {
  Write-Host "=== [$h] Configuring Hadoop env vars ==="
  # Stream script via STDIN to /bin/sh (present on minimal images)
  $remote | & ssh @sshOpts $h "/bin/sh -s" 2>&1 | ForEach-Object { Write-Host "[$h] $_" }
  if ($LASTEXITCODE -eq 0) {
    Write-Host "[$h] SUCCESS" -ForegroundColor Green
  } else {
    Write-Host "[$h] FAILED with code $LASTEXITCODE" -ForegroundColor Red
  }
}

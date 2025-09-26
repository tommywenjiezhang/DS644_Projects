$key = "ds644.pem"

$hosts = @(
  "ubuntu@xxxxxxx.compute-1.amazonaws.com",
  "ubuntu@xxxxxxx.compute-1.amazonaws.com",
  "ubuntu@xxxxxxx.compute-1.amazonaws.com",
  "ubuntu@xxxxxxx.compute-1.amazonaws.com"
)

$hostsFile = @"
127.0.0.1 localhost
xxxxxxx master
xxxxxxx slave1
xxxxxxxslave2
xxxxxxx  slave3

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
"@

$sshCommon = @("-i", $key)

foreach ($h in $hosts) {
    Write-Host "=== [$h] Overwriting /etc/hosts ==="

    $remoteCmd = @"
sudo bash -c 'cat > /etc/hosts << "EOF"
$hostsFile
EOF
chmod 644 /etc/hosts
chown root:root /etc/hosts'
cat /etc/hosts
"@

    & ssh @sshCommon $h $remoteCmd
    if ($LASTEXITCODE -ne 0) { throw "ssh apply on $h failed with code $LASTEXITCODE" }
}

Write-Host "All hosts updated successfully."

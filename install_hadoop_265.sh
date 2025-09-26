#!/bin/sh
set -eu

# --- Variables
HADOOP_VER="2.6.5"
HADOOP_TGZ="hadoop-${HADOOP_VER}.tar.gz"
HADOOP_URL="https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VER}/${HADOOP_TGZ}"
HADOOP_HOME="$HOME/hadoop-${HADOOP_VER}"
JAVA_HOME_DIR="/usr/lib/jvm/java-8-openjdk-amd64"
DATA_BASE="$HOME/hadoop-${HADOOP_VER}"   # local data dirs (name/data)

export DEBIAN_FRONTEND=noninteractive

echo "[info] apt-get update & base packages"
sudo apt-get update -y
sudo apt-get install -y openjdk-8-jdk wget tar openssh-client

# --- Download/extract Hadoop if missing
if [ ! -d "$HADOOP_HOME" ]; then
  echo "[info] downloading Hadoop ${HADOOP_VER}"
  cd "$HOME"
  wget -q --show-progress "$HADOOP_URL" -o /dev/null -O "$HADOOP_TGZ"
  tar -xzf "$HADOOP_TGZ"
fi



# --- core-site.xml (localhost as requested)
cat > "$HADOOP_HOME/etc/hadoop/core-site.xml" <<EOF
<?xml version="1.0"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
  <property>
    <name>hadoop.tmp.dir</name>
    <value>${HADOOP_HOME}/tmp</value>
  </property>
</configuration>
EOF

# --- hdfs-site.xml
cat > "$HADOOP_HOME/etc/hadoop/hdfs-site.xml" <<EOF
<?xml version="1.0"?>
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>3</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file://${DATA_BASE}/dfs/name</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>file://${DATA_BASE}/dfs/data</value>
  </property>
</configuration>
EOF

# --- mapred-site.xml
cp "$HADOOP_HOME/etc/hadoop/mapred-site.xml.template" "$HADOOP_HOME/etc/hadoop/mapred-site.xml"
cat > "$HADOOP_HOME/etc/hadoop/mapred-site.xml" <<'EOF'
<?xml version="1.0"?>
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>
EOF

# --- yarn-site.xml (ORIGINAL localhost values)
cat > "$HADOOP_HOME/etc/hadoop/yarn-site.xml" <<'EOF'
<?xml version="1.0"?>
<configuration>
  <!-- NodeManager shuffle service -->
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
    <value>org.apache.hadoop.mapred.ShuffleHandler</value>
  </property>

  <!-- ResourceManager host -->
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>localhost</value>
  </property>

  <!-- Explicit ResourceManager addresses -->
  <property>
    <name>yarn.resourcemanager.address</name>
    <value>localhost:8032</value>
  </property>
  <property>
    <name>yarn.resourcemanager.scheduler.address</name>
    <value>localhost:8030</value>
  </property>
  <property>
    <name>yarn.resourcemanager.resource-tracker.address</name>
    <value>localhost:8035</value>
  </property>
  <property>
    <name>yarn.resourcemanager.admin.address</name>
    <value>localhost:8033</value>
  </property>
  <property>
    <name>yarn.resourcemanager.webapp.address</name>
    <value>localhost:8088</value>
  </property>
</configuration>
EOF

# --- Ensure JAVA_HOME in hadoop-env.sh (create if missing)
HENV="$HADOOP_HOME/etc/hadoop/hadoop-env.sh"
if [ ! -f "$HENV" ]; then
  touch "$HENV"
fi
# Replace or append JAVA_HOME
if grep -q '^export[[:space:]]\{1,\}JAVA_HOME' "$HENV"; then
  sed -i "s|^export[[:space:]]\{1,\}JAVA_HOME.*|export JAVA_HOME=${JAVA_HOME_DIR}|" "$HENV"
else
  printf '\nexport JAVA_HOME=%s\n' "$JAVA_HOME_DIR" >> "$HENV"
fi

# --- Persist user env (~/.bash_profile), idempotent
PROFILE="$HOME/.bash_profile"
touch "$PROFILE"
# Strip CR if any
sed -i 's/\r$//' "$PROFILE" 2>/dev/null || true

add_line() { grep -qxF "$1" "$PROFILE" || printf '%s\n' "$1" >> "$PROFILE"; }

add_line 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64'
add_line 'export HADOOP_HOME=$HOME/hadoop-2.6.5'
add_line 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop'
add_line 'export PATH=$JAVA_HOME/bin:$PATH'
add_line 'export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin'

# Apply to current session (if interactive shells source .bash_profile)
. "$PROFILE" >/dev/null 2>&1 || true

echo "JAVA_HOME=$JAVA_HOME"
echo "HADOOP_HOME=$HADOOP_HOME"
"$HADOOP_HOME/bin/hadoop" version || true
java -version || true

echo "[done] Hadoop ${HADOOP_VER} configured on master."

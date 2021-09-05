#!/bin/bash
set -e

apt-get install -y unzip

unzip -q -o /tmp/SecurityServer.zip -d /tmp/SecurityServer
mkdir -p /opt/securityserver/bin/key
mkdir -p /opt/securityserver/include
mkdir -p /opt/securityserver/lib

cp /tmp/SecurityServer/Software/Linux/x86-64/Administration/csadm /opt/securityserver/bin
cp /tmp/SecurityServer/Software/Linux/x86-64/Administration/p11tool2 /opt/securityserver/bin
cp /tmp/SecurityServer/Software/Linux/x86-64/Administration/key/* /opt/securityserver/bin/key
cp /tmp/SecurityServer/Software/Linux/x86-64/Crypto_APIs/PKCS11_R3/include/* /opt/securityserver/include
cp /tmp/SecurityServer/Software/Linux/x86-64/Crypto_APIs/PKCS11_R3/lib/* /opt/securityserver/lib
chmod 644 /opt/securityserver/lib/*
chmod 644 /opt/securityserver/include/*
chmod 555 /opt/securityserver/bin/csadm
chmod 555 /opt/securityserver/bin/p11tool2
chmod 444 /opt/securityserver/bin/key/*
ln -s /opt/securityserver/lib/libcs_pkcs11_R3.so /usr/lib/libcs_pkcs11_R3.so
ln -s /opt/securityserver/bin/csadm /usr/bin/csadm
ln -s /opt/securityserver/bin/p11tool2 /usr/bin/p11tool2

if [ "${HSM_DEVICE}" = "PCI" ]; then

#  sudo apt-get -y install build-essential linux-headers-$(uname -r)
  cd /tmp/securityserver-driver
  make
  sudo make install
#  sudo apt-get -y remove build-essential linux-headers-$(uname -r)

  cat > /etc/cs_pkcs11_R3.cfg <<EOF
[Global]
Logpath = /tmp

# Loglevel (0 = NONE; 1 = ERROR; 2 = WARNING; 3 = INFO; 4 = TRACE)
Logging = 1
# Maximum size of the logfile in bytes (file is rotated with a backupfile if full)
Logsize = 10mb

# Created/Generated keys are stored in an external or internal database
KeysExternal = false

# If true, every session establishs its own connection
SlotMultiSession = true

# Maximum number of slots that can be used
SlotCount = 10

# If true, leading zeroes of decryption operations will be kept
KeepLeadZeros = false

# Configures load balancing mode ( == 0 ) or failover mode ( > 0 )
# In failover mode, n specifies the interval in seconds after which a reconnection attempt to the failed CryptoServer is started.
FallbackInterval = 0

# Prevents expiring session after inactivity of 15 minutes
KeepAlive = true

# Timeout of the open connection command in ms
ConnectionTimeout = 60000

# Timeout of command execution in ms
CommandTimeout = 60000

[CryptoServer]
Device = /dev/cs2.0
EOF
else
  cat > /etc/cs_pkcs11_R3.cfg <<EOF
[Global]
Logpath = /tmp

# Loglevel (0 = NONE; 1 = ERROR; 2 = WARNING; 3 = INFO; 4 = TRACE)
Logging = 1
# Maximum size of the logfile in bytes (file is rotated with a backupfile if full)
Logsize = 10mb

# Created/Generated keys are stored in an external or internal database
KeysExternal = false

# If true, every session establishs its own connection
SlotMultiSession = true

# Maximum number of slots that can be used
SlotCount = 10

# If true, leading zeroes of decryption operations will be kept
KeepLeadZeros = false

# Configures load balancing mode ( == 0 ) or failover mode ( > 0 )
# In failover mode, n specifies the interval in seconds after which a reconnection attempt to the failed CryptoServer is started.
FallbackInterval = 0

# Prevents expiring session after inactivity of 15 minutes
KeepAlive = true

# Timeout of the open connection command in ms
ConnectionTimeout = 60000

# Timeout of command execution in ms
CommandTimeout = 60000

[CryptoServer]
Device = ${HSM_DEVICE}
EOF
fi

if [ "${HSM_SIMULATOR}" = "true" ]; then
  apt-get install -y libc6-i386 lib32gcc1
  mkdir -p /opt/securityserver-sim/service
  cp -r /tmp/SecurityServer/Software/Linux/Simulator/sim5_linux/* /opt/securityserver-sim
  chmod 644 /opt/securityserver-sim/ReadmeMBK.txt
  chmod 644 /opt/securityserver-sim/bin/cs_sim.ini
  chmod 755 /opt/securityserver-sim/bin/bl_sim5
  chmod 755 /opt/securityserver-sim/bin/cs_sim.sh
  chmod 755 /opt/securityserver-sim/bin/cs_multi.sh
  chmod -R 755 /opt/securityserver-sim/devices

  cat > /opt/securityserver-sim/service/hsm-simulator.service <<EOF
[Unit]
Description=HSM Simulator
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=utimaco
ExecStart=/opt/securityserver-sim/bin/cs_sim.sh

[Install]
WantedBy=multi-user.target
EOF

  useradd -M utimaco
  chown -R utimaco:utimaco /opt/securityserver-sim

  cp /opt/securityserver-sim/service/hsm-simulator.service /etc/systemd/system
  systemctl daemon-reload
  systemctl enable hsm-simulator
  systemctl start hsm-simulator
fi

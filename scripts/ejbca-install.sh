#!/bin/sh

if [ -z EJBCA_CESECORE_PASSWORD_ENCRYPTION_KEY ]; then
  export EJBCA_CESECORE_PASSWORD_ENCRYPTION_KEY="UnsecureEncryptionKeyStr"
fi
if [ -z EJBCA_CESECORE_CA_KEYSTOREPASS ]; then
  export EJBCA_CESECORE_CA_KEYSTOREPASS="ChangeMe"
fi
if [ -z EJBCA_EJBCA_CMSKEYSTOREPASS ]; then
  export EJBCA_EJBCA_CMSKEYSTOREPASS="ChangeMe"
fi
if [ -z EJBCA_EJBCA_CLI_DEFAULTPASSWORD ]; then
  export EJBCA_EJBCA_CLI_DEFAULTPASSWORD="ejbca"
fi
if [ -z EJBCA_INSTALL_CA_NAME ]; then
  export EJBCA_INSTALL_CA_NAME="ManagementCA"
fi
if [ -z EJBCA_INSTALL_CA_DN ]; then
  export EJBCA_INSTALL_CA_DN="CN=ManagementCA,O=EJBCA,C=SE"
fi
if [ -z EJBCA_INSTALL_SOPIN ]; then
  export EJBCA_INSTALL_SOPIN="123456789"
fi
if [ -z EJBCA_INSTALL_TOKENPASSWORD ]; then
  export EJBCA_INSTALL_TOKENPASSWORD="123456"
fi
if [ -z EJBCA_INSTALL_SUPERADMIN_PASSWORD ]; then
  export EJBCA_INSTALL_SUPERADMIN_PASSWORD="Sup3r4dm1n"
fi
if [ -z EJBCA_INSTALL_CREATE_SUPERADMIN_P12 ]; then
  export EJBCA_INSTALL_CREATE_SUPERADMIN_P12="true"
fi
if [ -z EJBCA_INSTALL_HTTPSSERVER_PASSWORD ]; then
  export EJBCA_INSTALL_HTTPSSERVER_PASSWORD="ChangeMe"
fi
if [ -z EJBCA_INSTALL_HTTPSSERVER_HOSTNAME ]; then
  export EJBCA_INSTALL_HTTPSSERVER_HOSTNAME="localhost"
fi
if [ -z EJBCA_INSTALL_HTTPSSERVER_DN ]; then
  export EJBCA_INSTALL_HTTPSSERVER_DN="CN=localhost,OU=EJBCA,O=EJBCA,C=SE"
fi

wildfly_check() {
  DURATION_SECONDS=30
  if [ ! -z "$1" ]; then
    DURATION_SECONDS="$1"
  fi
  DURATION=$(echo "$DURATION_SECONDS / 5" | bc)

  echo "wait ${DURATION_SECONDS}s for start up wildfly"
  for i in `seq 1 $DURATION`; do
    /opt/wildfly/bin/jboss-cli.sh --connect ":read-attribute(name=server-state)" | grep "result" | awk '{ print $3; }'|grep running
    if [ $? -eq 0 ]; then
      return 0
    fi
    sleep 5
  done
  echo "wildfly not started after ${DURATION_SECONDS}s, exit"
  exit 1
}

ejbca_deploy_check() {
  DURATION_SECONDS=30
  if [ ! -z "$1" ]; then
    DURATION_SECONDS="$1"
  fi
  DURATION=$(echo "$DURATION_SECONDS / 5" | bc)

  echo "wait ${DURATION_SECONDS}s for deploying EJBCA"
  for i in `seq 1 $DURATION`; do
    if [ -f /opt/wildfly/standalone/deployments/ejbca.ear.deployed ]; then
      echo "EJBCA deployed"
      return 0
    fi
    sleep 5
  done
  echo "EJBCA not deployed after ${DURATION_SECONDS}s, exit"
  exit 1
}

apt-get install -y openjdk-8-jdk ant wget unzip bc
unzip -q -o /tmp/ejbca-ce.zip -d /opt
mv /opt/ejbca_ce_7_4_3_2 /opt/ejbca
cp -r /tmp/ejbca-config/* /opt/ejbca/conf
chown -R wildfly:wildfly /opt/ejbca

cd /opt/ejbca

export EJBCA_HOME="/opt/ejbca"
export APPSRV_HOME="/opt/wildfly"

sudo -E -u wildfly ant -q clean deployear
/opt/wildfly/bin/jboss-cli.sh --connect :reload
ejbca_deploy_check
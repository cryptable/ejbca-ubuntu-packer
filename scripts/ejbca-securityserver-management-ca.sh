#!/bin/sh

# Check to install and configure the management CA
if [ EJBCA_INSTALL_CA = "false" ]; then
  exit 0
fi
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

cd /opt/ejbca
cp -r /tmp/ejbca-config/* /opt/ejbca/conf
chown -R wildfly:wildfly /opt/ejbca

sudo -E -u wildfly p11tool2 Slot=1 Login=ADMIN,/opt/securityserver/bin/key/ADMIN.key Label="${EJBCA_INSTALL_CA_NAME}" InitToken="${EJBCA_INSTALL_SOPIN}"
sudo -E -u wildfly p11tool2 Slot=1 LoginSO="${EJBCA_INSTALL_SOPIN}" InitPIN="${EJBCA_INSTALL_TOKENPASSWORD}"

export EJBCA_HOME="/opt/ejbca"
export APPSRV_HOME="/opt/wildfly"

sudo -E -u wildfly ant clientToolBox

sudo -E -u wildfly echo "Management CA Generate empty dummy key"
sudo -E -u wildfly $EJBCA_HOME/dist/clientToolBox/ejbcaClientToolBox.sh PKCS11HSMKeyTool generate /usr/lib/libcs_pkcs11_R3.so 512 emptyKey 1 -password ${EJBCA_INSTALL_TOKENPASSWORD}
sudo -E -u wildfly echo "Management CA Generate test key"
sudo -E -u wildfly $EJBCA_HOME/dist/clientToolBox/ejbcaClientToolBox.sh PKCS11HSMKeyTool generate /usr/lib/libcs_pkcs11_R3.so 512 testKey 1 -password ${EJBCA_INSTALL_TOKENPASSWORD}
sudo -E -u wildfly echo "Management CA Generate default key"
sudo -E -u wildfly $EJBCA_HOME/dist/clientToolBox/ejbcaClientToolBox.sh PKCS11HSMKeyTool generate /usr/lib/libcs_pkcs11_R3.so 4096 defaultKey 1 -password ${EJBCA_INSTALL_TOKENPASSWORD}
sudo -E -u wildfly echo "Management CA Generate signing key"
sudo -E -u wildfly $EJBCA_HOME/dist/clientToolBox/ejbcaClientToolBox.sh PKCS11HSMKeyTool generate /usr/lib/libcs_pkcs11_R3.so 4096 signKey 1 -password ${EJBCA_INSTALL_TOKENPASSWORD}

sudo -E -u wildfly ant runinstall
sudo -E -u wildfly ant deploy-keystore
/opt/wildfly/bin/jboss-cli.sh --connect :reload

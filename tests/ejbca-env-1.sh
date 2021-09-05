#!/bin/bash

export EJBCA_CESECORE_PASSWORD_ENCRYPTION_KEY="UnsecureEncryptionKeyStr"
export EJBCA_CESECORE_CA_KEYSTOREPASS="ChangeMe"
export EJBCA_EJBCA_CMSKEYSTOREPASS="ChangeMe"
export EJBCA_EJBCA_CLI_DEFAULTPASSWORD="ejbca"
export EJBCA_INSTALL_CA_NAME="ManagementCA"
export EJBCA_INSTALL_CA_DN="CN=ManagementCA,O=EJBCA,C=SE"
export EJBCA_INSTALL_SOPIN="123456789"
export EJBCA_INSTALL_TOKENPASSWORD="123456"
export EJBCA_INSTALL_SUPERADMIN_PASSWORD="Sup3r4dm1n"
export EJBCA_INSTALL_CREATE_SUPERADMIN_P12="true"
export EJBCA_INSTALL_HTTPSSERVER_PASSWORD="ChangeMe"
export EJBCA_INSTALL_HTTPSSERVER_HOSTNAME="localhost"
export EJBCA_INSTALL_HTTPSSERVER_DN="CN=localhost,OU=EJBCA,O=EJBCA,C=SE"
export EJBCA_HOME="/opt/ejbca"
export APPSRV_HOME="/opt/wildfly"
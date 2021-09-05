# VMware Section
# --------------

vm_name = "ejbca-test"

output_directory = "output-ubuntu"

# Ubuntu Section
# --------------

ejbca_user_password = "Ejbc4Us3r"

# MySQL Section
# -------------

mysql_root_password = "toorlqsym"

ejbca_mysql_password = "Ejbc4Mysql"

# HSM Section
# -----------

hsm_simulator = "true"

hsm_device = "3001@127.0.0.1"

# EJBCA Section
# -------------

ejbca_cesecore_password_encryption_key = "UnsecureEncryptionKeyStr"

ejbca_cesecore_ca_keystorepass = "ChangeMe"

ejbca_ejbca_cmskeystorepass = "ChangeMe"

ejbca_ejbca_cli_defaultpassword = "ejbca"

# EJBCA Management CA Section
# ---------------------------

ejbca_install_management_ca = "true"

ejbca_install_management_ca_name = "ManagementCA"

ejbca_install_management_ca_dn = "CN=ManagementCA,O=EJBCA,C=SE"

ejbca_install_management_ca_tokensopin = "123456789"

ejbca_install_management_ca_tokenpin = "123456"

ejbca_install_superadmin_password = "Sup3r4dm1n"

ejbca_install_create_superadmin_p12 = "true"

ejbca_install_httpsserver_password = "ChangeMe"

ejbca_install_httpsserver_hostname = "localhost"

ejbca_install_httpsserver_dn = "CN=localhost,OU=EJBCA,O=EJBCA,C=SE"
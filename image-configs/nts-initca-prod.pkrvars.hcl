# !--- Encrypt-file: cicd, dtillemans ---!

# VMware Section
# --------------

vm_name = "nts-initca-prod"

output_directory = "output-nts-initca-prod"

# Ubuntu Section
# --------------

# Password created with: openssl rand -base64 20

ejbca_user_password = "Ejbc4InitC4"

# MySQL Section
# -------------

mysql_root_password = "1KIffV2WvlxxIvfCRHiI7aGUGLM="

ejbca_mysql_password = "zv/dC78AiQ03gMk9aNmqETEN8XI="

# HSM Section
# -----------

hsm_simulator = "false"

hsm_device = "PCI"

# EJBCA Section
# -------------

ejbca_cesecore_password_encryption_key = "W+6Rn9GgZ4Hbl4Jk+QtACQ7LIno="

ejbca_cesecore_ca_keystorepass = "NaBFW6m7noBWEDq1uZGikJfsxYQ="

ejbca_ejbca_cmskeystorepass = "O17AFCabIou7YCSQGTlAxVD00DI="

ejbca_ejbca_cli_defaultpassword = "QfsWCtAH2IQddNa/hZB4owbcyAc="

# EJBCA Management CA Section
# ---------------------------
ejbca_install_management_ca = "false"

# VMware Section
# --------------

variable "vm_name" {
  type    = string
  default = "ejbca-test"
}

variable "cpu" {
  type    = string
  default = "2"
}

variable "ram_size" {
  type    = string
  default = "4096"
}

variable "disk_size" {
  type    = string
  default = "50000"
}

variable "iso_checksum" {
  type    = string
  default = "f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
}

variable "iso_checksum_type" {
  type    = string
  default = "sha256"
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/focal/ubuntu-20.04.3-live-server-amd64.iso"
}

variable "output_directory" {
  type    = string
  default = "output-ubuntu"
}

# Ubuntu Section
# --------------

variable "ejbca_user_password" {
  type    = string
  default = "Ejbc4Us3r"  
}

# MySQL Section
# -------------

variable "mysql_root_password" {
  type    = string
  default = "toorlqsym"
}

variable "ejbca_mysql_password" {
  type    = string
  default = "Ejbc4Mysql"  
}

# HSM Section
# -----------
variable "hsm_simulator" {
  type    = string
  default = "true"
}

variable "hsm_device" {
  type    = string
  default = "3001@127.0.0.1"
}

# EJBCA Section
# -------------

variable "ejbca_cesecore_password_encryption_key" {
  type    = string
  default = "UnsecureEncryptionKeyStr"
}

variable "ejbca_cesecore_ca_keystorepass" {
  type    = string
  default = "ChangeMe"
}

variable "ejbca_ejbca_cmskeystorepass" {
  type    = string
  default = "ChangeMe"
}

variable "ejbca_ejbca_cli_defaultpassword" {
  type    = string
  default = "ejbca"
}

# EJBCA Management CA Section
# ---------------------------

variable "ejbca_install_management_ca" {
  type    = string
  default = "true"
}

variable "ejbca_install_management_ca_name" {
  type    = string
  default = "ManagementCA"
}

variable "ejbca_install_management_ca_dn" {
  type    = string
  default = "CN=ManagementCA,O=EJBCA,C=SE"
}

variable "ejbca_install_management_ca_tokensopin" {
  type    = string
  default = "123456789"
}

variable "ejbca_install_management_ca_tokenpin" {
  type    = string
  default = "123456"
}

variable "ejbca_install_superadmin_password" {
  type    = string
  default = "Sup3r4dm1n"
}

variable "ejbca_install_create_superadmin_p12" {
  type    = string
  default = "true"
}

variable "ejbca_install_httpsserver_password" {
  type    = string
  default = "ChangeMe"
}

variable "ejbca_install_httpsserver_hostname" {
  type    = string
  default = "localhost"
}

variable "ejbca_install_httpsserver_dn" {
  type    = string
  default = "CN=localhost,OU=EJBCA,O=EJBCA,C=SE"
}

# VMWARE image section
# --------------------

source "vmware-iso" "ubuntu" {
  boot_command         = [
    "<wait>",
    " <wait>",
    " <wait>",
    " <wait>",
    " <wait>",
    "<esc><wait>",
    "<f6><wait>",
    "<esc><wait>",
    "<bs><bs><bs><bs><wait>",
    " autoinstall<wait5>",
    " ds=nocloud-net<wait5>",
    ";s=http://<wait5>{{.HTTPIP}}<wait5>:{{.HTTPPort}}/<wait5>",
    " hostname=temporary",
    " ---<wait5>",
    "<enter><wait5>",
  ]

  boot_wait            = "5s"
  communicator         = "ssh"
  cpus                 = "${var.cpu}"
  disk_size            = "${var.disk_size}"
  http_directory       = "./linux/ubuntu/http/20.04"
  iso_checksum         = "${var.iso_checksum_type}:${var.iso_checksum}"
  iso_url              = "${var.iso_url}"
  memory               = "${var.ram_size}"
  shutdown_command     = "echo 'vagrant' | sudo -S -E shutdown -P now"
  ssh_timeout          = "10m"
  ssh_username         = "vagrant"
  ssh_password         = "vagrant"
  vm_name              = "${var.vm_name}"
  guest_os_type        = "ubuntu-64"
  output_directory     = "${var.output_directory}"
  format = "ova"
}

build {
  sources = [
    "source.vmware-iso.ubuntu"
  ]

  provisioner "file" {
    source = "assets/SecurityServerEvaluation-V4.45.2.0.zip"
    destination = "/tmp/SecurityServer.zip"
  }

  provisioner "file" {
    source = "assets/securityserver-driver"
    destination = "/tmp"
  }

  provisioner "file" {
    source = "assets/ejbca_ce_7_4_3_2.zip"
    destination = "/tmp/ejbca-ce.zip"
  }

  provisioner "file" {
    source = "assets/ejbca-config"
    destination = "/tmp"
  }

  provisioner "file" {
    source = "assets/database-config"
    destination = "/tmp"
  }

  provisioner "shell" {
    execute_command = "{{ .Vars }} sudo -S -E sh {{ .Path }}"
    environment_vars = [
      "MSQL_ROOT_PASSWORD=${var.mysql_root_password}",
      "HSM_DEVICE=${var.hsm_device}",
      "HSM_SIMULATOR=${var.hsm_simulator}",
      "HOSTNAME=${var.ejbca_install_httpsserver_hostname}",
      "EJBCA_USER_PASSWORD=${var.ejbca_user_password}",
      "EJBCA_MYSQL_PASSWORD=${var.ejbca_mysql_password}",
      "EJBCA_CESECORE_PASSWORD_ENCRYPTION_KEY=${var.ejbca_cesecore_password_encryption_key}",
      "EJBCA_CESECORE_CA_KEYSTOREPASS=${var.ejbca_cesecore_ca_keystorepass}",
      "EJBCA_EJBCA_CMSKEYSTOREPASS=${var.ejbca_ejbca_cmskeystorepass}",
      "EJBCA_EJBCA_CLI_DEFAULTPASSWORD=${var.ejbca_ejbca_cli_defaultpassword}",
      "EJBCA_INSTALL_CA=${var.ejbca_install_management_ca}",
      "EJBCA_INSTALL_CA_NAME=${var.ejbca_install_management_ca_name}",
      "EJBCA_INSTALL_CA_DN=${var.ejbca_install_management_ca_dn}",
      "EJBCA_INSTALL_TOKENPASSWORD=${var.ejbca_install_management_ca_tokenpin}",
      "EJBCA_INSTALL_SOPIN=${var.ejbca_install_management_ca_tokensopin}",
      "EJBCA_INSTALL_SUPERADMIN_PASSWORD=${var.ejbca_install_superadmin_password}",
      "EJBCA_INSTALL_CREATE_SUPERADMIN_P12=${var.ejbca_install_create_superadmin_p12}",
      "EJBCA_INSTALL_HTTPSSERVER_PASSWORD=${var.ejbca_install_httpsserver_password}",
      "EJBCA_INSTALL_HTTPSSERVER_HOSTNAME=${var.ejbca_install_httpsserver_hostname}",
      "EJBCA_INSTALL_HTTPSSERVER_DN=${var.ejbca_install_httpsserver_dn}",
    ]
    scripts         = [
      "./scripts/update.sh", 
      "./scripts/temp.sh",
      "./scripts/vmware.sh",
      "./scripts/mariadb.sh",
      "./scripts/wildfly.sh",
      "./scripts/securityserver.sh",
      "./scripts/ejbca-install.sh",
      "./scripts/ejbca-securityserver-management-ca.sh",
      "./scripts/hostname.sh",
      "./scripts/cleanup.sh",
      "./scripts/harden.sh",
    ]
  }
}

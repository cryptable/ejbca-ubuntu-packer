EJBCA Packer template
=====================

Introduction
------------

This is a Hashicorp packer file to build an EJBCA Community edition on Ubuntu with a Utimaco SecurityServer HSM (simulator is supported).
You nee to use the Utimaco HSM simulator or Utimaco PCI driver

Setup
-----

1) Download the ejbca community edition 7.4.3.2, place it in the assets directory. Verify the file against the SHA256 file also published on Sourceforge

2a) (optional) Simulator: Download the Utimaco SecurityServer V4.45.2.0 simulator from the Utimaco site

2b) (optional) PCI: Copy the driver source files in the assets/securityserver-driver. Verify in documentation and scripts/securityserver.sh if the build commands have not been changed

3) Choose the necessary settings in the template.pkvars.hcl. Using the default settings are very unsecure.

TODO
----

- Default support for softhsm simulator
- Install wildfly from assets folder, instead downloading it from the Ubuntu image
- Migrate shell scripts to Ansible

Notes
-----

1) Small problems using vmware-iso
It is important when using the vmware-iso on linux that your DHCP settings are identical between the ubuntu installation and application installation (after ubuntu reboot). The best result I had with Ubuntu 20.04 was using 'dhcp-identifier:duid' in the user-data configuration (network setting and late-commands sed settings), because the autoinstall during Ubuntu installation uses this. Otherwise the vmnet8 dhcp server starts giving multiple IP addresses in the dhcp.leases and it confuses really packer.
If this does not work, try 'dhcp-identifier:mac' in both location of linux/ubuntu/http/20.04/user-data. When creating your image, keep on the safe side your hostname in the linux/ubuntu/http/20.04/user-data the same as the hostname in the boot parameters. Otherwise again your vmnet8 dhcp server can lease different IP addresses.
#!/bin/bash

sshpass -p "vagrant" scp ../scripts/ejbca.sh vagrant@192.168.46.139:/tmp
sshpass -p "vagrant" scp ../assets/ejbca_ce_7_4_3_2.zip vagrant@192.168.46.139:/tmp/ejbca-ce.zip
sshpass -p "vagrant" scp ../tests/ejbca-env-1.sh vagrant@192.168.46.139:/tmp
sshpass -p "vagrant" scp -r ../assets/ejbca-config vagrant@192.168.46.139:/tmp


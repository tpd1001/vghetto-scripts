#!/bin/bash
# Author: William Lam
# Site: www.virtuallyghetto.com
# Reference: http://www.virtuallyghetto.com/2015/01/ultimate-automation-guide-to-deploying-vcsa-6-0-part-2-platform-services-controller-node.html

case `uname` in
	Linux)
	OVFTOOL="/usr/bin/ovftool"
	;;
	Darwin)
	OVFTOOL="/Applications/VMware OVF Tool/ovftool"
	;;
	*)
	echo "Unsupported OS: `uname`"
	exit 1
	;;
esac
VCSA_OVA=/Volumes/Storage/Images/Beta/VMware-VCSA-all-6.0.0-2497477/vcsa/vmware-vcsa

ESXI_HOST=192.168.1.200
ESXI_USERNAME=root
ESXI_PASSWORD=vmware123
VM_NETWORK="VM Network"
VM_DATASTORE=mini-local-datastore-2

# Configurations for 1st PSC Node
PSC_VMNAME=psc-01
PSC_ROOT_PASSWORD=VMware1!
PSC_NETWORK_MODE=static
PSC_NETWORK_FAMILY=ipv4
## IP Network Prefix (CIDR notation)
PSC_NETWORK_PREFIX=24
## Same value as PSC_IP if no DNS
PSC_HOSTNAME=192.168.1.50
PSC_IP=192.168.1.50
PSC_GATEWAY=192.168.1.1
PSC_DNS=192.168.1.1
PSC_ENABLE_SSH=True

# Configuration for SSO
SSO_DOMAIN_NAME=vghetto.local
SSO_SITE_NAME=vghetto
SSO_ADMIN_PASSWORD=VMware1!

# NTP Servers
NTP_SERVERS=0.pool.ntp.org

### DO NOT EDIT BEYOND HERE ###

echo "Deploying vCenter Server Appliance 1st Platform Service Controller Node ${PSC_VMNAME} ..."
"${OVFTOOL}" --acceptAllEulas --skipManifestCheck --X:injectOvfEnv --allowExtraConfig --X:enableHiddenProperties --X:waitForIp --sourceType=OVA --powerOn \
"--net:Network 1=${VM_NETWORK}" --datastore=${VM_DATASTORE} --diskMode=thin --name=${PSC_VMNAME} \
"--deploymentOption=infrastructure" \
"--prop:guestinfo.cis.vmdir.domain-name=${SSO_DOMAIN_NAME}" \
"--prop:guestinfo.cis.vmdir.site-name=${SSO_SITE_NAME}" \
"--prop:guestinfo.cis.vmdir.password=${SSO_ADMIN_PASSWORD}" \
"--prop:guestinfo.cis.appliance.net.addr.family=${PSC_NETWORK_FAMILY}" \
"--prop:guestinfo.cis.appliance.net.addr=${PSC_IP}" \
"--prop:guestinfo.cis.appliance.net.pnid=${PSC_HOSTNAME}" \
"--prop:guestinfo.cis.appliance.net.prefix=${PSC_NETWORK_PREFIX}" \
"--prop:guestinfo.cis.appliance.net.mode=${PSC_NETWORK_MODE}" \
"--prop:guestinfo.cis.appliance.net.dns.servers=${PSC_DNS}" \
"--prop:guestinfo.cis.appliance.net.gateway=${PSC_GATEWAY}" \
"--prop:guestinfo.cis.appliance.root.passwd=${PSC_ROOT_PASSWORD}" \
"--prop:guestinfo.cis.appliance.ssh.enabled=${PSC_ENABLE_SSH}" \
"--prop:guestinfo.cis.appliance.ntp.servers=${NTP_SERVERS}" \
${VCSA_OVA} "vi://${ESXI_USERNAME}:${ESXI_PASSWORD}@${ESXI_HOST}/"

echo "Checking to see if the PSC endpoint https://${PSC_IP}/websso/ is ready ..."
until [[ $(curl --connect-timeout 30 -s -o /dev/null -w "%{http_code}" -i -k https://${PSC_IP}/websso/) -eq 200 ]];
do
	echo "Not ready, sleeping for 60sec"
	sleep 60
done
echo "VCSA 1st Platform Service Controller Node is now ready!"

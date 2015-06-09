#!/bin/sh

# Maintainer: Santiago Gomez Saez <santiago.gomez-saez@iaas.uni-stuttgart.de>

ESXI_HOST=
ESXI_ROOT=
TEMPLATE_DIR=
DATASTORE_PATH=
USER_DATA_PATH=.
VM_NUMBER=
VM_NAME=CoreOS$VM_NUMBER
CLOUD_CONFIG_ISO=configdrive.iso

# User Data Config
COREOS_HOST_NAME=coreos$VM_NUMBER
ETCD_DISCOVERY_URL=
# Colon should be escaped in the IP. Example: 0\.0\.0\.0
ETCD_ADDR=""
ETCD_PORT=4001
ETCD_PEER_ADDR=""
ETCD_PEER_PORT=7001
ETCD_HEARTBEAT_INTERVAL=50
ETCD_ELECTION_INTERVAL=500

# Colon should be escaped in the IP. Example: 0\.0\.0\.0\/32
DOCKER_REGISTRY_ADDR="<Docker_Registry_IP_Address>\/32"

# VMX Configuration (this configuration parameters are included in the the deploy_* script)
# Network
MAC_ADDRESS=""
ETHERNET_ADD_TYPE="static"
ETHERNET_VIRTUAL_DEVICE="vmxnet3"
VM_NETWORK="VM Network"
ETHERNET_PCI_SLOT="192"

# Computation Resources
VM_MEM=3840
VM_vCPU=2
VM_CORES_PER_SOCKET=1

# CoreOS ZIP URL
CORE_OS_DOWNLOAD_URL=http://beta.release.core-os.net/amd64-usr/current/coreos_production_vmware_insecure.zip

wget $CORE_OS_DOWNLOAD_URL

unzip coreos_production_vmware_insecure.zip
rm -f coreos_production_vmware_insecure.zip

# Creating Directories in ESXI Host
ssh $ESXI_ROOT@$ESXI_HOST "rm -rf $TEMPLATE_DIR && mkdir -p $TEMPLATE_DIR && mkdir -p $DATASTORE_PATH/$VM_NAME"


# Configuring deployment script on ESXI
cp deploy_coreos_on_esxi.sh deploy_coreos_on_esxi.sh.bckp

sed -i "s/VM_NUMBER\=.*/VM_NUMBER=\"${VM_NUMBER}\"/g" deploy_coreos_on_esxi.sh

sed -i "s/MAC_ADDRESS\=.*/MAC_ADDRESS=\"${MAC_ADDRESS}\"/g" deploy_coreos_on_esxi.sh
sed -i "s/ETHERNET_ADD_TYPE\=.*/ETHERNET_ADD_TYPE=\"${ETHERNET_ADD_TYPE}\"/g" deploy_coreos_on_esxi.sh
sed -i "s/ETHERNET_VIRTUAL_DEVICE\=.*/ETHERNET_VIRTUAL_DEVICE=\"${ETHERNET_VIRTUAL_DEVICE}\"/g" deploy_coreos_on_esxi.sh
sed -i "s/VM_NETWORK\=.*/VM_NETWORK=\"${VM_NETWORK}\"/g" deploy_coreos_on_esxi.sh
sed -i "s/ETHERNET_PCI_SLOT\=.*/ETHERNET_PCI_SLOT=\"${ETHERNET_PCI_SLOT}\"/g" deploy_coreos_on_esxi.sh
sed -i "s/VM_MEM\=.*/VM_MEM=${VM_MEM}/g" deploy_coreos_on_esxi.sh
sed -i "s/VM_vCPU\=.*/VM_vCPU=${VM_vCPU}/g" deploy_coreos_on_esxi.sh
sed -i "s/VM_CORES_PER_SOCKET\=.*/VM_CORES_PER_SOCKET=${VM_CORES_PER_SOCKET}/g" deploy_coreos_on_esxi.sh

chmod 755 deploy_coreos_on_esxi.sh

scp -r deploy_coreos_on_esxi.sh user_data make_ISO.sh coreos_production_vmware_insecure_image.vmdk coreos_production_vmware_insecure.vmx insecure_ssh_key $ESXI_ROOT@$ESXI_HOST:$TEMPLATE_DIR/

mv deploy_coreos_on_esxi.sh.bckp deploy_coreos_on_esxi.sh

# Customizing user_data file
cp $USER_DATA_PATH/user_data $USER_DATA_PATH/user_data.backup
sed -i "s/\#coreos\.hostname\#/$COREOS_HOST_NAME/g" $USER_DATA_PATH/user_data
sed -i "s/\#etcd\.discovery\.url\#/$ETCD_DISCOVERY_URL/g" $USER_DATA_PATH/user_data
sed -i "s/\#etcd\.addr\#/$ETCD_ADDR\:$ETCD_PORT/g" $USER_DATA_PATH/user_data
sed -i "s/\#etcd\.peer\.addr\#/$ETCD_PEER_ADDR\:$ETCD_PEER_PORT/g" $USER_DATA_PATH/user_data
sed -i "s/\#etcd\.heartbeat\.interval\#/$ETCD_HEARTBEAT_INTERVAL/g" $USER_DATA_PATH/user_data
sed -i "s/\#etcd\.election\.interval\#/$ETCD_ELECTION_INTERVAL/g" $USER_DATA_PATH/user_data
sed -i "s/\#docker\.registry\.addr\#/$DOCKER_REGISTRY_ADDR/g" $USER_DATA_PATH/user_data

chmod 755 ./*.sh
./make_ISO.sh  
scp -r $CLOUD_CONFIG_ISO $ESXI_ROOT@$ESXI_HOST:$TEMPLATE_DIR/

echo "Cleaning"
rm configdrive.iso coreos_production_vmware_insecure_image.vmdk coreos_production_vmware_insecure.vmx

rm $USER_DATA_PATH/user_data
mv $USER_DATA_PATH/user_data.backup $USER_DATA_PATH/user_data

#ssh $ESXI_ROOT@$ESXI_HOST "$TEMPLATE_DIR/deploy_coreos_on_esxi.sh && rm -rf $TEMPLATE_DIR/"

echo "Done provisioning VM $VM_NAME"

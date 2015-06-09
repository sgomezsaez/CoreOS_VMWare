#!/bin/sh
# Inspird by William Lam, www.virtuallyghetto.com
# Simple script to use CoreOS image with open-vm-tools & run on ESXi
# Maintainer: Santiago Gomez Saez <santiago.gomez-saez@iaas.uni-stuttgart.de>

echo "Starting Provisioning of CoreOS VM instance..."
# VM number in cluster and VM name
VM_NUMBER=24

# Network Preferences
MAC_ADDRESS=""
ETHERNET_ADD_TYPE="static"
ETHERNET_VIRTUAL_DEVICE="vmxnet3"
VM_NETWORK="VM Network"
ETHERNET_PCI_SLOT="192"

VM_NAME=CoreOS$VM_NUMBER
# VM Configuration
VM_MEM=3840
VM_vCPU=2
VM_CORES_PER_SOCKET=1

# Path to the template directory
TEMPLATE_DIR=/vmfs/volumes/datastore1/templates
mkdir -p /vmfs/volumes/datastore1/templates
echo "Template Directory: $TEMPLATE_DIR"

# Path of Datastore to store CoreOS
DATASTORE_PATH=/vmfs/volumes/datastore1
echo "DATASTORE_PATH: $DATASTORE_PATH"
echo "DATASTORE_PATH: $DATASTORE_PATH"

echo "VM_NAME: $VM_NAME"
echo "VM_NUMBER: $VM_NUMBER"

# Creates CoreOS VM Directory by hand
mkdir -p ${DATASTORE_PATH}/${VM_NAME}
echo "-VM Path: ${DATASTORE_PATH}/${VM_NAME}"

CLOUD_CONFIG_ISO=configdrive.iso

# Copying .vmdk and .vmx file
echo "-Copying .vmdk and .vmx file from $TEMPLATE_DIR to ${DATASTORE_PATH}/${VM_NAME}"
cp -rf $TEMPLATE_DIR/coreos_production_vmware_insecure.vmx  ${DATASTORE_PATH}/${VM_NAME}/coreos_production_vmware_insecure.vmx
cp -rf $TEMPLATE_DIR/coreos_production_vmware_insecure_image.vmdk ${DATASTORE_PATH}/${VM_NAME}/coreos_production_vmware_insecure_image.vmdk
cp -rf $TEMPLATE_DIR/$CLOUD_CONFIG_ISO ${DATASTORE_PATH}/${VM_NAME}/$CLOUD_CONFIG_ISO

# Convert VMDK from 2gbsparse from hosted products to Thin
cd ${DATASTORE_PATH}/${VM_NAME}
vmkfstools -i coreos_production_vmware_insecure_image.vmdk -d thin coreos.vmdk

# Move the original VMDK to templates for later use
rm coreos_production_vmware_insecure_image*.vmdk

# Setting VMX Network Preferences
# Ethernet Address

grep -q "^ethernet0.addressType" coreos_production_vmware_insecure.vmx && sed -i "s/ethernet0\.addressType.*/ethernet0\.addressType = \"${ETHERNET_ADD_TYPE}\"/g" coreos_production_vmware_insecure.vmx || echo "ethernet0.addressType = \"$ETHERNET_ADD_TYPE\"" >> coreos_production_vmware_insecure.vmx

grep -q "^ethernet0.present" coreos_production_vmware_insecure.vmx && sed -i "s/ethernet0\.present.*/ethernet0\.present = \"TRUE\"/g" coreos_production_vmware_insecure.vmx || echo "ethernet0.present = \"TRUE\"" >> coreos_production_vmware_insecure.vmx

grep -q "^ethernet0.virtualDev" coreos_production_vmware_insecure.vmx && sed -i "s/ethernet0\.virtualDev.*/ethernet0\.virtualDev = \"${ETHERNET_VIRTUAL_DEVICE}\"/g" coreos_production_vmware_insecure.vmx || echo "ethernet0.virtualDev = \"$ETHERNET_VIRTUAL_DEVICE\"" >> coreos_production_vmware_insecure.vmx

# Update CoreOS VMX to map to VM Network
grep -q "^ethernet0.networkName" coreos_production_vmware_insecure.vmx && sed -i "s/ethernet0\.networkName.*/ethernet0\.networkName = \"${VM_NETWORK}\"/g" coreos_production_vmware_insecure.vmx || echo "ethernet0.networkName = \"$VM_NETWORK\"" >> coreos_production_vmware_insecure.vmx

grep -q "^ethernet0.pciSlotNumber" coreos_production_vmware_insecure.vmx && sed -i "s/ethernet0\.pciSlotNumber.*/ethernet0\.pciSlotNumber = \"${ETHERNET_PCI_SLOT}\"/g" coreos_production_vmware_insecure.vmx || echo "ethernet0.pciSlotNumber = \"$ETHERNET_PCI_SLOT\"" >> coreos_production_vmware_insecure.vmx

grep -q "^ethernet0.address" coreos_production_vmware_insecure.vmx && sed -i "s/ethernet0\.address.*/ethernet0\.address = \"${MAC_ADDRESS}\"/g" coreos_production_vmware_insecure.vmx || echo "ethernet0.address = \"$MAC_ADDRESS\"" >> coreos_production_vmware_insecure.vmx

grep -q "^ethernet0.generatedAddress" coreos_production_vmware_insecure.vmx && sed -i "s/ethernet0\.generatedAddress .*$/\#ethernet0\.generatedAddress = $1/g" coreos_production_vmware_insecure.vmx

grep -q "^ethernet0.generatedAddressOffset" coreos_production_vmware_insecure.vmx && sed -i "s/ethernet0\.generatedAddressOffset.*/ethernet0\.generatedAddressOffset = \"0\"/g" coreos_production_vmware_insecure.vmx || echo "ethernet0.generatedAddressOffset = \"0\"" >> coreos_production_vmware_insecure.vmx

# Update CoreOS VMX to reference new VMDK
sed -i 's/coreos_production_vmware_insecure_image.vmdk/coreos.vmdk/g' coreos_production_vmware_insecure.vmx

# Update CoreOS VMX w/memory size
sed -i "s/memsize.*/memsize = \"${VM_MEM}\"/g" coreos_production_vmware_insecure.vmx

# Update CoreOS VMX w/vCPU number
grep -q "^numvcpus" coreos_production_vmware_insecure.vmx && sed -i "s/^numvcpus.*/numvcpus = $VM_vCPU/" coreos_production_vmware_insecure.vmx || echo "numvcpus = \"$VM_vCPU\"" >> coreos_production_vmware_insecure.vmx

# Update CoreOS VMX w/cores per socket
grep -q "^cpuid.coresPerSocket" coreos_production_vmware_insecure.vmx && sed -i "s/^cpuid\.coresPerSocket.*/cpuid\.coresPerSocket = $VM_CORES_PER_SOCKET/" coreos_production_vmware_insecure.vmx || echo "cpuid.coresPerSocket = \"$VM_CORES_PER_SOCKET\"" >> coreos_production_vmware_insecure.vmx

# Update CoreOS VMX w/new VM Name
sed -i "s/displayName.*/displayName = \"${VM_NAME}\"/g" coreos_production_vmware_insecure.vmx

# Update CoreOS VMX to include CD-ROM & mount cloud-config ISO
cat >> coreos_production_vmware_insecure.vmx << __CLOUD_CONFIG_ISO__
ide0:0.deviceType = "cdrom-image"
ide0:0.fileName = "$CLOUD_CONFIG_ISO"
ide0:0.present = "TRUE"
__CLOUD_CONFIG_ISO__


# Register CoreOS VM which returns VM ID
VM_ID=$(vim-cmd solo/register ${DATASTORE_PATH}/${VM_NAME}/coreos_production_vmware_insecure.vmx)

# Upgrade CoreOS Virtual Hardware from 4 to 9
#vim-cmd vmsvc/upgrade ${VM_ID} vmx-09

# PowerOn CoreOS VM
vim-cmd vmsvc/power.on ${VM_ID}

#cp -rf $TEMPLATE_DIR/$CLOUD_CONFIG_ISO ${DATASTORE_PATH}/${VM_NAME}/$CLOUD_CONFIG_ISO
# Reset CoreOS VM to quickly get DHCP address
vim-cmd vmsvc/power.reset ${VM_ID}

#cp -rf $TEMPLATE_DIR/$CLOUD_CONFIG_ISO ${DATASTORE_PATH}/${VM_NAME}/$CLOUD_CONFIG_ISO
rm $TEMPLATE_DIR/$CLOUD_CONFIG_ISO


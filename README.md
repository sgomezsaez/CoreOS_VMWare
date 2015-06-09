Deployment of CoreOS cluster in VMWare
=================================================================

Inspired by https://github.com/lamw/vghetto-scripts/blob/master/shell/deploy_coreos_on_esxi2.sh


Getting Started
-----------------------------------------------------------------

``` 

- Install and configure a VMWare ESXi server

- Download the scripts contained in this folder

- A Static IP associated to a manually entered MAC Addresses in VMWare is necessary for each VM hosting the Docker instance

``` 


Configuring & Running
-----------------------------------------------------------------

``` 
- Configure the parameters located in get_vm.sh

- Further ETCD Cloud Config parameters can be configured in the user_data file

- Run get_vm.sh

- Login to the ESXi server and go to the folder specified in TEMPLATE_DIR

- Run deploy_coreos_on_esxi.sh

``` 

Logging into a CoreOS instance\n
----------------------------------------------------------------

- Download the insecure_ssh_key from this folder

- Execute ssh -i insecure_ssh_key core@<CoreOS_Instance_IP>



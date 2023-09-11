# Building a Docker image for Decentramind.io platform using lolMiner as an example

#### Prerequisites 
* Ubuntu 20.04 or other OS with Docker support
* **Decentramind.io** account

#### Expected result
* A custom application (lolMiner in this example) wrapped in a docker container and ready to run on **Decentramind.io** platform. 
* The application docker image uploaded to **Decentramind.io** repository.

#### Installing and configuring Docker
Install docker according to the [official installation manual](https://docs.docker.com/engine/install/ubuntu/).
Connect it to the Decentramind.io image repository:

```
sudo docker login https://registry.decentramind.io/v2/
```
You will be prompted for login and password, enter your **Decentramind.io** login and password.

#### Create Dockerfile
Describe the image to be created in terms of ```Dockerfile```. To do this let's execute the commands:

```
mkdir ~/docker-calcpi
cd ~/docker-calcpi/
nano Dockerfile
```

The approximate contents of the ```Dockerfile``` may be as follows:

```
# base image for the image to be created, CUDA is needed for the cryptominer to work
FROM nvidia/cuda:10.1-base

# update the keys for the nvidia deb-package server
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A4B469963BF863CC

# install the necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends --no-upgrade jq wget

# downloading lolMiner, unzipping and deleting the original archive
RUN wget https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.68/lolMiner_v1.68_Lin64.tar.gz && tar -xf lol* && mv 1.68 lolMiner && rm lolMiner_v1.68_Lin64.tar.gz

# add a startup script and give it permission to run
ADD start.sh /
RUN chmod +x start.sh

# configure what will be run when the container is started
ENTRYPOINT ["/start.sh"]

```
As you can see above, this ```Dockerfile``` describes a container based on the Nvidia CUDA 10.1 container in which the lolMiner application has been added.

#### Creating a startup script 
In the task (container) on the platform **Decentramind.io** you can pass arbitrary parameters in the form of text. To get the parameters the environment variable ```$BASE64_ARGS_VAR``` is used, the data in which is encoded in Base64 (on the API side the data is passed in an open, unencoded form, see [Decentramind.io API](https://github.com/Decentramind-io/API-SDK/blob/main/megamind.api.v1.public.json)). For example, let's assume that the container being created expects to see the address of the Ethereum Classic wallet for mining and the name of the worker in the task parameters. We also assume that these parameters should be passed as a json object of the form ```{ "wallet": "<wallet address>", "worker_name": "<worker name>"}```. Let's create a start script ```start.sh```, which gets the wallet for mining and the name of the worker from the task parameters by calling ```nano start.sh```. In the simplest case, the start script should contain the following text:

```
#!/bin/bash

# base64 decoding
UNB64=$(echo $BASE64_ARGS_VAR | base64 --decode)

# get the wallet and worker_name fields from json
WALLET=$(jq -r '.wallet' << $UNB64)
WORKER=$(jq -r '.worker_name' << $UNB64)

# if the wallet is not passed, there is no point in any further work
if [[[ "$WALLET" == "null" || ( -z "$WALLET") ]];
	then
		echo 'empty wallet supplied'
		exit
	fi

# if worker name is not passed, you can substitute the name of the task within the Decentramind.io platform; it is stored in the $TASKNAME variable
if [[[ "$WORKER" == "null" || ( -z "$WORKER") ];
	then
		WORKER=$TASKNAME
	fi

# start the miner in Ethereum Classic mode with the specified parameters
/lolMiner/lolMiner --algo ETCHASH --pool etc.2miners.com:1010 --user $WALLET --worker $WORKER

```

#### Create an image
Build an image with the command 
```
sudo docker build -t registry.decentramind.io/lolminer:1 .
```
Here we build an image in the current folder and assign it tag registry.decentramind.io/lolminer:1, where ```registry.decentramind.io/``` is a mandatory part (docker registry address to save image to), ```lolminer``` is the name of the image (chosen randomly), ```1``` is the version label (chosen randomly, one image can contain several versions).

#### Upload image to the repository
Upload the image to the repository **Decentramind.io**:
```
sudo docker push registry.decentramind.io/lolminer:1
```
From now on, the ```registry.decentramind.io/lolminer:1``` image is available to run on the **Decentramind.io** platform. You need to use [Decentramind.io API](https://github.com/Decentramind-io/API-SDK/blob/main/megamind.api.v1.public.json) to run and control tasks.

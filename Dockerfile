FROM nvidia/cuda:10.1-base

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A4B469963BF863CC
RUN apt-get update && apt-get install -y --no-install-recommends --no-upgrade jq wget
RUN wget https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.68/lolMiner_v1.68_Lin64.tar.gz && tar -xf lol* && mv 1.68 lolMiner && rm lolMiner_v1.68_Lin64.tar.gz

ADD start.sh /
RUN chmod +x start.sh

ENTRYPOINT ["/start.sh"]

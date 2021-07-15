FROM ubuntu:latest AS mm_compiler
ENV MM_BRANCH="master"
ENV MM_CHECKOUT="974d6e5f1440f68c48492122ca33828a98864dfc"
ENV BB_BRANCH="master"
ENV BB_CHECKOUT="95389dc2a2b5c746e5afa36f51e106de3d0f8c91"

WORKDIR /root

RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y gcc g++ cmake libsodium-dev git

RUN echo "cloning MadMax branch ${MM_BRANCH}"
RUN git clone --branch ${MM_BRANCH} https://github.com/madMAx43v3r/chia-plotter.git \
&& cd chia-plotter \
&& git checkout ${MM_CHECKOUT} \
&& git submodule update --init \
&& /bin/sh ./make_devel.sh

RUN echo "cloning BladeBit ${BB_BRANCH}"
RUN git clone --branch ${BB_BRANCH} --recursive https://github.com/harold-b/bladebit.git \
&& cd bladebit \
&& ./build-bls \
&& make clean && make -j$(nproc --all)


FROM ubuntu:latest

EXPOSE 8555
EXPOSE 8444

ENV keys="generate"
ENV harvester="false"
ENV farmer="false"
ENV plots_dir="/plots"
ENV farmer_address="null"
ENV farmer_port="null"
ENV testnet="false"
ENV full_node_port="null"
ENV TZ="UTC"
ENV CHIA_BRANCH="1.2.2"
ENV CHIA_CHECKOUT="e24baa620d1f5ee13373baf065c024bd05a41b90"
ENV FARMR_VERSION="v1.5.2.1"
ENV PLOTMAN_VERSION="v0.5"

# Chia
RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl jq python3 ansible tar bash ca-certificates git openssl unzip wget python3-pip sudo acl build-essential python3-dev python3.8-venv python3.8-distutils apt nfs-common python-is-python3 vim tzdata libsodium-dev rsync tmux mc

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

RUN echo "cloning ${CHIA_BRANCH}"
RUN git clone --branch ${CHIA_BRANCH} https://github.com/Chia-Network/chia-blockchain.git \
&& cd chia-blockchain \
&& git checkout ${CHIA_CHECKOUT} \
&& git submodule update --init mozilla-ca \
&& chmod +x install.sh \
&& /usr/bin/sh ./install.sh

# Farmr
RUN wget https://github.com/joaquimguimaraes/farmr/releases/download/${FARMR_VERSION}/farmr-linux-x86_64.tar.gz \
&& mkdir /farmr \
&& tar xf farmr-linux-x86_64.tar.gz -C /farmr/
COPY ./files/config-xch.json /farmr/config/config-xch.json
COPY ./files/cache-xch.json /farmr/cache/cache-xch.json

# Plotman
RUN pip install --force-reinstall git+https://github.com/ericaltendorf/plotman@${PLOTMAN_VERSION}

ENV PATH=/chia-blockchain/venv/bin/:$PATH
WORKDIR /chia-blockchain
ADD ./entrypoint.sh entrypoint.sh

# Copy madmax
COPY --from=mm_compiler /root/chia-plotter/build /usr/lib/chia-plotter
RUN ln -s /usr/lib/chia-plotter/chia_plot /usr/bin/chia_plot

# Copy bladebit
COPY --from=mm_compiler /root/bladebit/.bin/release/bladebit /usr/bin/bladebit


ENTRYPOINT ["bash", "./entrypoint.sh"]

if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

# Setup locations for /data to be functional
if [ ! -d "/data" ] ; then
	echo "Warning: No /data, container state data will be lost at restart/shutdown!"
	mkdir /data
fi

# Setup Chia main state directory
if [ ! -d "/data/flax" ] ; then
	mkdir -p /data/flax
fi
ln -fs /data/flax /root/.flax

# Setup Farmr Files
if [ ! -d "/data/farmr/config" ] ; then
	mkdir -p /data/farmr/config
fi
rm -rf /farmr/config
ln -fs /data/farmr/config /farmr/config
rm /farmr/blockchain/xch.json
cp /farmr/blockchain/xfx.json.template /farmr/blockchain/xfx.json

if [ ! -d "/data/farmr/cache" ] ; then
	mkdir -p /data/farmr/cache
fi
rm -rf /farmr/cache
ln -fs /data/farmr/cache /farmr/cache
ln -fs /data/farmr/id.json /farmr/id.json

# Set location of XFX binary
echo "/flax-blockchain/venv/bin/flax" > /farmr/override-xfx-binary.txt

# Setup plotman persistence
if [ ! -d "/data/plotman" ] ; then
	mkdir -p /data/plotman
fi
if [ ! -d /root/.config ] ; then
	mkdir /root/.config/
fi
ln -fs /data/plotman /root/.config/plotman


cd /flax-blockchain

. ./activate

flax init

# Enable INFO log level by default
flax configure -log-level INFO

if [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  flax keys generate
else
  flax keys add -f ${keys}
fi

# Check if a CA cert is provided for harvester
if [[ -n "${ca}" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
    exit
  fi
  flax init -c ${ca}
fi

for p in ${plots_dir//:/ }; do
    mkdir -p ${p}
    if [[ ! "$(ls -A $p)" ]]; then
        echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    fi
    flax plots add -d ${p}
done

sed -i 's/localhost/127.0.0.1/g' ~/.flax/mainnet/config/config.yaml

if [[ ${farmer} == 'true' ]]; then
  flax start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    flax configure --set-farmer-peer ${farmer_address}:${farmer_port}
    flax start harvester
  fi
else
  flax start farmer
fi

if [[ ${testnet} == "true" ]]; then
  if [[ -z $full_node_port || $full_node_port == "null" ]]; then
    flax configure --set-fullnode-port 6888
  else
    flax configure --set-fullnode-port ${var.full_node_port}
  fi
fi

if [[ $farmr == 'farmer' ]]; then
	(cd /farmr/ && sleep 60 && ./farmr farmer headless) &
fi
if [[ $farmr == 'harvester' ]]; then
	(cd /farmr/ && sleep 60 && ./farmr harvester headless) &
fi

if [[ $plotman == 'true' ]]; then
	(nohup plotman plot >> /data/plotman/daemon.log 2>&1) &
fi

while true; do sleep 30; done;

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
if [ ! -d "/data/chia" ] ; then
	mkdir /data/chia
fi
ln -s /data/chia /root/.chia

# Setup Farmr Files
if [ ! -d "/data/farmr/config" ] ; then
	mkdir -p /data/farmr/config
	mv /farmr/config/config-xch.json /data/farmr/config/
fi
rm -rf /farmr/config
ln -s /data/farmr/config /farmr/config

if [ ! -d "/data/farmr/cache" ] ; then
	mkdir -p /data/farmr/cache
	mv /farmr/cache/cache-xch.json /data/farmr/cache/
fi
rm -rf /farmr/cache
ln -s /data/farmr/cache /farmr/cache
ln -s /data/farmr/id.json /farmr/id.json

# Setup plotman persistence
if [ ! -d "/data/plotman" ] ; then
	mkdir -p /data/plotman
fi
if [ ! -d /root/.config ] ; then
	mkdir /root/.config/
fi
ln -fs /data/plotman /root/.config/plotman


cd /chia-blockchain

. ./activate

chia init

# Enable INFO log level by default
chia configure -log-level INFO

if [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  chia keys generate
elif [[ ${keys} == "copy" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
	exit
  else
  chia init -c ${ca}
  fi
else
  chia keys add -f ${keys}
fi

for p in ${plots_dir//:/ }; do
    mkdir -p ${p}
    if [[ ! "$(ls -A $p)" ]]; then
        echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    fi
    chia plots add -d ${p}
done

sed -i 's/localhost/127.0.0.1/g' ~/.chia/mainnet/config/config.yaml

if [[ ${farmer} == 'true' ]]; then
  chia start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    chia configure --set-farmer-peer ${farmer_address}:${farmer_port}
    chia start harvester
  fi
else
  chia start farmer
fi

if [[ ${testnet} == "true" ]]; then
  if [[ -z $full_node_port || $full_node_port == "null" ]]; then
    chia configure --set-fullnode-port 58444
  else
    chia configure --set-fullnode-port ${var.full_node_port}
  fi
fi

if [[ $farmr == 'farmer' ]]; then
	(cd /farmr/ && ./farmer.sh) &
fi
if [[ $farmr == 'harvester' ]]; then
	(cd /farmr/ && ./harvester.sh) &
fi

if [[ $plotman == 'true' ]]; then
	(nohup plotman plot >> /data/plotman/daemon.log 2>&1) &
fi

while true; do sleep 30; done;

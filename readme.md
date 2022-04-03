# Official [TrueNAS](https://www.truenas.com) Flax Docker Container

Current Versions:

* Flax: [0.1.8](https://github.com/Flax-Network/flax-blockchain/)
* Plotman: [v0.5.1](https://github.com/ericaltendorf/plotman/)
* Farmr: [1.7.7.4](https://github.com/joaquimguimaraes/farmr/)
* MadMax: [master / a9a49031ac03504b272b7199ef3e071c2d93e9cc](https://github.com/madMAx43v3r/chia-plotter/)
* BladeBit: [master / cef433cac3ff8f469529486bb5f036ec879d88be](https://github.com/harold-b/bladebit/)
* PlotNG: [v0.62](https://github.com/maded2/plotng)

## Basic Startup
```
docker run --name <container-name> -d ixsystems/flax-docker:latest
(optional -v /path/to/data:/data)
(optional -v /path/to/plots:/plots)
```

## Flax Binary
```
# flax 
```

## Plotman
```
# plotman
```

## MadMax Plotter
```
# chia_plot
```

## BladeBit Plotter
```
# bladebit
```

## PlotNG
```
# plotng-server
# plotng-client
```

#### set the timezone for the container (optional, defaults to UTC)
Timezones can be configured using the `TZ` env variable. A list of supported time zones can be found [here](http://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html)
```
-e TZ="America/Chicago"
```
## Configuration

You can modify the behavior of your Flax container by setting specific environment variables.

To ensure that your flax config settings and sycned blockchain persist, you can pass in a directory for /data
```
-v /path/to/data:/data
```

To use your own keys, place your secret mnemonic into a file and pass as arguments on startup.
```
-v /path/to/key/file:/path/in/container -e keys="/path/in/container"
```
or pass keys into the running container
```
docker exec -it <container-name> venv/bin/flax keys add
```

To start a farmer only node pass
```
-e farmer="true"
```

To start a harvester only node pass
```
-e harvester="true" -e farmer_address="addres.of.farmer" -e farmer_port="portnumber" -v /path/to/ssl/ca:/path/in/container -e ca="/path/in/container"
```

To start the farmr.net bot in farmer mode (Logs stored in /farmr/log.txt)
```
-e farmr="farmer"
```

To start the farmr.net bot in harvester mode (Logs stored in /farmr/log.txt)
```
-e farmr="harvester"
```

To start the plotman tool in daemon mode (Logs stored in /data/plotman/daemon.log)
```
-e plotman="true"
```
NOTE: You should make sure plotman is configured properly first


The `plots_dir` environment variable can be used to specify the directory containing the plots, it supports PATH-style colon-separated directories.

#### or run commands externally with venv (this works for most flax XYZ commands)
```
docker exec -it flax venv/bin/flax plots add -d /plots
```

#### status from outside the container
```
docker exec -it flax venv/bin/flax show -s -c
```

#### Connect to testnet?
```
docker run -d --expose=58444 --expose=6888 -e testnet=true --name <container-name> ixsystems/flax-docker:latest
```

#### Need a wallet?
```
docker exec -it flax-farmer1 venv/bin/flax wallet show (follow the prompts)
```

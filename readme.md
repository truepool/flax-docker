# Official [TruePool.io](https://www.truepool.io) & [TrueNAS](https://www.truenas.com) Chia Docker Container

## Important Links

* [TruePool.io - Website & Leaderboards](https://www.truepool.io)
* [Official Container Image Documentation](https://www.truepool.io/kb/truepool-docker-image/)
* [ixsystems/chia-docker - Docker Hub](https://hub.docker.com/repository/docker/ixsystems/chia-docker)


Current Versions:

* Chia: [1.2.0](https://github.com/Chia-Network/chia-blockchain/releases/tag/1.2.0)
* Plotman: [v0.5](https://github.com/ericaltendorf/plotman/releases/tag/v0.5)
* Farmr: [1.4.7.1](https://github.com/joaquimguimaraes/farmr/releases/tag/v1.4.7.1)
* MadMax: [master / 2144ce10cb2133b3fd911640d9fa483ec3223b7d](https://github.com/madMAx43v3r/chia-plotter/commit/2144ce10cb2133b3fd911640d9fa483ec3223b7d)

## Basic Startup
```
docker run --name <container-name> -d ixsystems/chia-docker:latest
(optional -v /path/to/plots:/plots)
```
#### set the timezone for the container (optional, defaults to UTC)
Timezones can be configured using the `TZ` env variable. A list of supported time zones can be found [here](http://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html)
```
-e TZ="America/Chicago"
```
## Configuration

You can modify the behavior of your Chia container by setting specific environment variables.

To use your own keys pass as arguments on startup (post 1.0.2 pre 1.0.2 must manually pass as shown below)
```
-v /path/to/key/file:/path/in/container -e keys="/path/in/container"
```
or pass keys into the running container
```
docker exec -it <container-name> venv/bin/chia keys add
```
alternatively you can pass in your local keychain, if you have previously deployed chia with these keys on the host machine
```
-v ~/.local/share/python_keyring/:/root/.local/share/python_keyring/
```

To start a farmer only node pass
```
-e farmer="true"
```

To start a harvester only node pass
```
-e harvester="true" -e farmer_address="addres.of.farmer" -e farmer_port="portnumber" -v /path/to/ssl/ca:/path/in/container -e ca="/path/in/container" -e keys="copy"
```

To start the farmr bot in farmer mode
```
-e farmr="farmer"
```

To start the farmr bot in harvester mode
```
-e farmr="harvester"
```

The `plots_dir` environment variable can be used to specify the directory containing the plots, it supports PATH-style colon-separated directories.

#### or run commands externally with venv (this works for most chia XYZ commands)
```
docker exec -it chia venv/bin/chia plots add -d /plots
```

#### status from outside the container
```
docker exec -it chia venv/bin/chia show -s -c
```

#### Connect to testnet?
```
docker run -d --expose=58444 --expose=8555 -e testnet=true --name <container-name> ixsystems/chia-docker:latest
```

#### Need a wallet?
```
docker exec -it chia-farmer1 venv/bin/chia wallet show (follow the prompts)
```

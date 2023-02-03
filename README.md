# Qubitro connector for the ESP32

Connect your devices to [Qubitro](https://www.qubitro.com/) and visualize your data in the
[Qubitro Portal](https://portal.qubitro.com/).

This [Toit](https://toitlang.org) package provides an easy and convenient way to
connect to Qubitro via MQTT from devices running on the ESP32-family of chips.

## Architecture

The Qubitro connector runs as a separate micro-service isolated from the rest of the
system through [Toit containers](https://github.com/toitlang/toit/discussions/869).

## Installing the Qubitro connector

To install the Qubitro connector service on your device, we recommend that you
use [Jaguar](https://github.com/toitlang/jaguar). Jaguar makes it easy to experiment
with the Qubitro services because it allows you to upload new services and
applications via WiFi without having to restart your device.

The Qubitro credentials easily be provided to the service at install time, so you
don't have to write it into your source code:

```sh
jag container install qubitro src/service.toit \
     -D qubitro.device.id=<PASTE_DEVICE_ID> \
     -D qubitro.device.token=<PASTE_DEVICE_TOKEN>
```

This install the Qubitro connector service in a separate container and it sticks
around across device restarts:

```
$ jag container list
DEVICE      IMAGE                                  NAME
lunar-bet   3fb76dd5-5842-57ff-b19c-857669906b04   jaguar
lunar-bet   d04371a2-bb38-54cb-9124-5e48d06ff3d1   qubitro
```

## Publishing data

Once the service is installed, you do not need to provide credentials to publish
data from individual applications, although you still can by providing arguments
to `qubitro.connect`. The code for publishing data is reasonably straight forward:

```
import qubitro
main:
  client ::= qubitro.connect
  10.repeat:
    client.publish { "MyData": random 1000 }
    sleep (Duration --s=2)
  client.close
```

To run code like the above, you can use `jag run`:

```sh
jag run examples/publish.toit
```

// Copyright (C) 2022 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import log
import monitor
import net

import encoding.json
import encoding.tison

import artemis
import certificate-roots
import mqtt
import mqtt.packets as mqtt

import .internal.api show QubitroService

import system.assets
import system.services show ServiceHandler ServiceProvider ServiceResource
import system.base.network show NetworkModule NetworkState NetworkResource

HOST ::= "broker.qubitro.com"
PORT ::= 8883

CONFIG-DEVICE-ID    ::= "qubitro.device.id"
CONFIG-DEVICE-TOKEN ::= "qubitro.device.token"

main:
  logger ::= log.Logger log.DEBUG-LEVEL log.DefaultTarget --name="qubitro"
  logger.info "service starting"
  defines-key := artemis.available ? "artemis.defines" : "jag.defines"
  defines := assets.decode.get defines-key
      --if-present=: tison.decode it
      --if-absent=: {:}

  certificate-roots.install-common-trusted-roots
  service := QubitroServiceProvider logger defines
  service.install
  logger.info "service running"

class QubitroServiceProvider extends ServiceProvider implements ServiceHandler:
  logger_/log.Logger
  defines_/Map
  state_ ::= NetworkState

  constructor .logger_ .defines_:
    super "qubitro" --major=1 --minor=0
    provides QubitroService.SELECTOR --handler=this

  handle index/int arguments/any --gid/int --client/int -> any:
    if index == QubitroService.CONNECT-INDEX:
      return connect arguments client
    if index == QubitroService.PUBLISH-INDEX:
      resource := (resource client arguments[0]) as QubitroClient
      return resource.module.publish arguments[1]
    unreachable

  connect config/Map client/int -> ServiceResource:
    device-id ::= config.get CONFIG-DEVICE-ID or defines_.get CONFIG-DEVICE-ID
    device-token := config.get CONFIG-DEVICE-TOKEN or defines_.get CONFIG-DEVICE-TOKEN
    if not device-id: throw "ILLEGAL_ARGUMENT: No device id provided"
    if not device-token: throw "ILLEGAL_ARGUMENT: No device token provided"
    module := state_.up: QubitroMqttModule logger_ device-id device-token
    if module.device-id != device-id:
      unreachable
    if module.device-token != device-token:
      unreachable
    return QubitroClient this client state_

class QubitroMqttModule implements NetworkModule:
  logger_/log.Logger
  device-id/string
  device-token/string
  client_/mqtt.FullClient? := null
  done_/monitor.Latch? := null

  constructor logger/log.Logger .device-id .device-token:
    logger_ = logger.with-name "mqtt"

  connect -> none:
    connected := monitor.Latch
    done := monitor.Latch
    done_ = done
    task::
      try:
        connect_ connected
      finally:
        client_ = done_ = null
        critical-do: done.set true
    // Wait until the MQTT task has connected and is running.
    client_ = connected.get
    client_.when-running: null

  disconnect -> none:
    if not client_: return
    // Close the client and wait until it has disconnected.
    client_.close
    done_.get

  connect_ connected/monitor.Latch -> none:
    transport/mqtt.TcpTransport? := null
    client/mqtt.FullClient? := null
    try:
      transport = mqtt.TcpTransport.tls
          --host=HOST
          --port=PORT
      client = mqtt.FullClient
          --logger=logger_
          --transport=transport
      options := mqtt.SessionOptions
          --client-id=device-id
          --username=device-id
          --password=device-token
      client.connect --options=options
      logger_.info "connected" --tags={"host": HOST, "port": PORT, "device": device-id}
      connected.set client
      client.handle: | packet/mqtt.Packet |
        logger_.warn "packet received (ignored)" --tags={"type": packet.type}
    finally: | is-exception exception |
      if client: client.close
      else if transport: transport.close
      // We need to call monitor operations to send exceptions
      // to the task that initiated the connection attempt, so
      // we have to do this in a critical section if we're being
      // canceled as part of a disconnect.
      critical-do:
        if connected.has-value:
          logger_.info "disconnected" --tags={"host": HOST, "port": PORT, "device": device-id}
        if is-exception:
          connected.set --exception exception
          return

  publish data/Map -> none:
    payload ::= json.encode data
    client_.publish device-id payload
    logger_.info "packet published" --tags={"device": device-id, "data": data}

class QubitroClient extends NetworkResource:
  module/QubitroMqttModule
  constructor provider/QubitroServiceProvider client/int state/NetworkState:
    module = state.module as QubitroMqttModule
    super provider client state

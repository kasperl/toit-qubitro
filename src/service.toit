// Copyright (C) 2022 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import log
import monitor
import net

import encoding.json
import encoding.tison

import certificate_roots
import mqtt
import mqtt.packets as mqtt

import .internal.api show QubitroService

import system.assets
import system.services show ServiceHandler ServiceProvider ServiceResource
import system.base.network show NetworkModule NetworkState NetworkResource

HOST ::= "broker.qubitro.com"
PORT ::= 8883

CONFIG_DEVICE_ID    ::= "qubitro.device.id"
CONFIG_DEVICE_TOKEN ::= "qubitro.device.token"

main:
  logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="qubitro"
  logger.info "service starting"
  defines := assets.decode.get "jag.defines"
      --if_present=: tison.decode it
      --if_absent=: {:}
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
    if index == QubitroService.CONNECT_INDEX:
      return connect arguments client
    if index == QubitroService.PUBLISH_INDEX:
      resource := (resource client arguments[0]) as QubitroClient
      return resource.module.publish arguments[1]
    unreachable

  connect config/Map client/int -> ServiceResource:
    device_id ::= config.get CONFIG_DEVICE_ID or defines_.get CONFIG_DEVICE_ID
    device_token := config.get CONFIG_DEVICE_TOKEN or defines_.get CONFIG_DEVICE_TOKEN
    if not device_id: throw "ILLEGAL_ARGUMENT: No device id provided"
    if not device_token: throw "ILLEGAL_ARGUMENT: No device token provided"
    module := state_.up: QubitroMqttModule logger_ device_id device_token
    if module.device_id != device_id:
      unreachable
    if module.device_token != device_token:
      unreachable
    return QubitroClient this client state_

class QubitroMqttModule implements NetworkModule:
  logger_/log.Logger
  device_id/string
  device_token/string
  client_/mqtt.FullClient? := null

  task_/Task? := null
  done_/monitor.Latch? := null

  constructor logger/log.Logger .device_id .device_token:
    logger_ = logger.with_name "mqtt"

  connect -> none:
    connected := monitor.Latch
    done := monitor.Latch
    done_ = done
    task_ = task::
      try:
        connect_ connected
      finally:
        client_ = task_ = done_ = null
        critical_do: done.set true
    // Wait until the MQTT task has connected and is running.
    client_ = connected.get
    client_.when_running: null

  disconnect -> none:
    if not task_: return
    // Cancel the MQTT task and wait until it has disconnected.
    task_.cancel
    done_.get

  connect_ connected/monitor.Latch -> none:
    transport/mqtt.TcpTransport? := null
    client/mqtt.FullClient? := null
    try:
      transport = mqtt.TcpTransport.tls
          --host=HOST
          --port=PORT
          --root_certificates=[ certificate_roots.BALTIMORE_CYBERTRUST_ROOT ]
      client = mqtt.FullClient --transport=transport
      options := mqtt.SessionOptions
          --client_id=device_id
          --username=device_id
          --password=device_token
      client.connect --options=options
      logger_.info "connected" --tags={"host": HOST, "port": PORT, "device": device_id}
      connected.set client
      client.handle: | packet/mqtt.Packet |
        logger_.warn "packet received (ignored)" --tags={"type": packet.type}
    finally: | is_exception exception |
      if client: client.close
      else if transport: transport.close
      // We need to call monitor operations to send exceptions
      // to the task that initiated the connection attempt, so
      // we have to do this in a critical section if we're being
      // canceled as part of a disconnect.
      critical_do:
        if connected.has_value:
          logger_.info "disconnected" --tags={"host": HOST, "port": PORT, "device": device_id}
        if is_exception:
          connected.set --exception exception
          return

  publish data/Map -> none:
    payload ::= json.encode data
    client_.publish device_id payload
    logger_.info "packet published" --tags={"device": device_id, "data": data}

class QubitroClient extends NetworkResource:
  module/QubitroMqttModule
  constructor provider/QubitroServiceProvider client/int state/NetworkState:
    module = state.module as QubitroMqttModule
    super provider client state

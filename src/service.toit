// Copyright (C) 2022 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import certificate_roots
import encoding.json
import log
import monitor
import net

import mqtt
import mqtt.packets as mqtt

import .internal.api show QubitroService

import system.services show ServiceDefinition ServiceResource
import system.base.network show NetworkModule NetworkState NetworkResource

HOST ::= "broker.qubitro.com"
PORT ::= 8883

CONFIG_DEVICE_ID    ::= "qubitro.device.id"
CONFIG_DEVICE_TOKEN ::= "qubitro.device.token"

main arguments:
  logger ::= log.Logger log.DEBUG_LEVEL log.DefaultTarget --name="qubitro"
  logger.info "service starting"
  service := QubitroServiceDefinition logger (arguments is Map ? arguments : {:})
  service.install
  logger.info "service running"

class QubitroServiceDefinition extends ServiceDefinition:
  logger_/log.Logger
  arguments_/Map
  state_ ::= NetworkState

  constructor .logger_ .arguments_:
    super "qubitro" --major=1 --minor=0
    provides QubitroService.UUID QubitroService.MAJOR QubitroService.MINOR

  handle pid/int client/int index/int arguments/any -> any:
    if index == QubitroService.CONNECT_INDEX:
      return connect arguments client
    if index == QubitroService.PUBLISH_INDEX:
      resource := (resource client arguments[0]) as QubitroClient
      return resource.module.publish arguments[1]
    unreachable

  connect config/Map client/int -> ServiceResource:
    device_id ::= config.get CONFIG_DEVICE_ID or arguments_.get CONFIG_DEVICE_ID
    device_token := config.get CONFIG_DEVICE_TOKEN or arguments_.get CONFIG_DEVICE_TOKEN
    // TODO(kasper): Check that we have device id and device token.
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
    network := net.open
    transport/mqtt.TcpTransport? := null
    client/mqtt.FullClient? := null
    try:
      transport = mqtt.TcpTransport.tls network
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
    finally:
      if client: client.close
      else if transport: transport.close
      logger_.info "disconnected" --tags={"host": HOST, "port": PORT, "device": device_id}
      network.close

  publish data/Map -> none:
    payload ::= json.encode data
    client_.publish device_id payload
    logger_.info "packet published" --tags={"device": device_id, "data": data}

class QubitroClient extends NetworkResource:
  module/QubitroMqttModule
  constructor service/QubitroServiceDefinition client/int state/NetworkState:
    module = state.module as QubitroMqttModule
    super service client state

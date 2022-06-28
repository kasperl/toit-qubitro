// Copyright (C) 2021 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import mqtt
import net
import tls
import certificate_roots

import .client

QUBITRO_HOST ::= "broker.qubitro.com"
QUBITRO_PORT ::= 8883

/**
Connects to the Qubitro MQTT broker. If no $network is provided, the default
  system network is used.
*/
connect --id/string --token/string --network/net.Interface?=null -> Client:
  if not network: network = net.open

  transport := mqtt.TcpTransport.tls network --host=QUBITRO_HOST --port=QUBITRO_PORT
      --root_certificates=[certificate_roots.BALTIMORE_CYBERTRUST_ROOT]

  options := mqtt.SessionOptions
      --client_id=id
      --username=id
      --password=token

  mqtt_client := mqtt.Client --transport=transport
  mqtt_client.start --options=options

  return Client id mqtt_client

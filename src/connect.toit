// Copyright (C) 2021 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import mqtt
import net
import tls
import certificate_roots

import .client
import .service show CONFIG_DEVICE_ID CONFIG_DEVICE_TOKEN

/**
Connects to Qubitro.
*/
connect --id/string?=null --token/string?=null -> Client:
  client := _client_
  if not client: throw "Cannot find Qubitro service"
  config := {:}
  if id: config[CONFIG_DEVICE_ID] = id
  if token: config[CONFIG_DEVICE_TOKEN] = token
  handle ::= client.connect config
  return Client handle

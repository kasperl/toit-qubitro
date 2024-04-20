// Copyright (C) 2021 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import .client
import .service show CONFIG-DEVICE-ID CONFIG-DEVICE-TOKEN

/**
Connects to Qubitro.
*/
connect --id/string?=null --token/string?=null -> Client:
  client := _client_
  if not client: throw "Cannot find Qubitro service"
  config := {:}
  if id: config[CONFIG-DEVICE-ID] = id
  if token: config[CONFIG-DEVICE-TOKEN] = token
  handle ::= client.connect config
  return Client handle

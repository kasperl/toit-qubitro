// Copyright (C) 2021 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import mqtt as mqttx  // Avoid issues with mqtt getter.
import encoding.json

class Client:
  device_id_ /string
  mqtt_      /mqttx.Client? := null

  constructor .device_id_ .mqtt_:
    add_finalizer this:: close

  /**
  Publishes the $data key-value mapping to Qubitro.
  */
  publish data/Map -> none:
    encoded := json.encode data
    mqtt_.publish device_id_ encoded

  /**
  Closes the connection to Qubitro.
  */
  close:
    if mqtt_:
      mqtt_.close
      remove_finalizer this
      mqtt_ = null

  /**
  Returns the underlying MQTT client, which allows publishing and subscribing
    to non-default topics.
  */
  mqtt -> mqttx.Client:
    return mqtt_

// Copyright (C) 2021 Kasper Lund.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import qubitro

// $ jag container install qubitro src/service.toit \
//     -D qubitro.device.id=<PASTE_DEVICE_ID> \
//     -D qubitro.device.token=<PASTE_DEVICE_TOKEN>

// $ jag run examples/publish.toit

main:
  client ::= qubitro.connect
  client.publish { "MyData": random 1000 }

// Copyright (C) 2021 Kasper Lund.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import qubitro

main:
  client ::= qubitro.connect
      --id="<PASTE_DEVICE_ID>"
      --token="<PASTE_DEVICE_TOKEN>"
  client.publish { "MyData": random 1000 }
  print "Published data to Qubitro!"

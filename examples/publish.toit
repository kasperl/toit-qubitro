// Copyright (C) 2021 Kasper Lund.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import qubitro

main:
  client ::= qubitro.connect
  client.publish { "MyData": random 1000 }

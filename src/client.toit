// Copyright (C) 2021 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import system.services show ServiceResourceProxy
import .internal.api

_client_/QubitroServiceClient? ::= (QubitroServiceClient).open
    --if_absent=: null

class Client extends ServiceResourceProxy:
  constructor handle/int:
    super _client_ handle

  /**
  Publishes the $data key-value mapping to Qubitro.
  */
  publish data/Map -> none:
    _client_.publish handle_ data

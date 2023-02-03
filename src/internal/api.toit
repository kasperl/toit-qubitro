// Copyright (C) 2022 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import system.services

interface QubitroService:
  static SELECTOR ::= services.ServiceSelector
      --uuid="4590d299-5c62-46f7-a3f3-3ccac3d67994"
      --major=1
      --minor=0

  connect config/Map -> int
  static CONNECT_INDEX ::= 0

  publish handle/int data/Map -> none
  static PUBLISH_INDEX ::= 1

class QubitroServiceClient extends services.ServiceClient implements QubitroService:
  static SELECTOR ::= QubitroService.SELECTOR
  constructor selector/services.ServiceSelector=SELECTOR:
    assert: selector.matches SELECTOR
    super selector

  connect config/Map -> int:
    return invoke_ QubitroService.CONNECT_INDEX config

  publish handle/int data/Map -> none:
    invoke_ QubitroService.PUBLISH_INDEX [handle, data]

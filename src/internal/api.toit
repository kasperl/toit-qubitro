// Copyright (C) 2022 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import system.services

interface QubitroService:
  static UUID/string ::= "4590d299-5c62-46f7-a3f3-3ccac3d67994"
  static MAJOR/int   ::= 1
  static MINOR/int   ::= 0

  static CONNECT_INDEX ::= 0
  connect config/Map -> int

  static PUBLISH_INDEX ::= 1
  publish handle/int data/Map -> none

class QubitroServiceClient extends services.ServiceClient implements QubitroService:
  constructor --open/bool=true:
    super --open=open

  open -> QubitroServiceClient?:
    return (open_ QubitroService.UUID QubitroService.MAJOR QubitroService.MINOR) and this

  connect config/Map -> int:
    return invoke_ QubitroService.CONNECT_INDEX config

  publish handle/int data/Map -> none:
    invoke_ QubitroService.PUBLISH_INDEX [handle, data]

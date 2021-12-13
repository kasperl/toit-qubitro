// Copyright (C) 2021 Kasper Lund.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import mqtt
import net
import tls
import certificate_roots
import encoding.json
import net.x509

QUBITRO_HOST ::= "broker.qubitro.com"
QUBITRO_PORT ::= 8883

connect --id/string --token/string --network/net.Interface? -> int:
  if not network: network = net.open
  socket := network.tcp_connect QUBITRO_HOST QUBITRO_PORT

  tls_socket := tls.Socket.client socket
      --root_certificates=[certificate_roots.BALTIMORE_CYBERTRUST_ROOT]
  tls_socket.handshake

  client := mqtt.Client
    id
    mqtt.TcpTransport tls_socket
    --username=id
    --password=token
  return 42

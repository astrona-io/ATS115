# Socket Device Settings

A file on the same volume as the server shares its fate: if the volume fills or the node fails, the log is lost with the server. A socket device sends records to another process, usually a log collector, so the evidence lives somewhere else. The price is that a network connection can fail or hang, and OpenBao treats audit records as essential. This part covers the settings that decide how a socket device behaves when the other end does not.

## The address and the socket type

A socket device needs an `address` and a `socket_type`:

<!-- astrona:playground:renew -->

```sh
bao audit enable -path=socket socket address=audit-sink.clients.svc.cluster.local:9090 socket_type=tcp
bao audit list -detailed
```

The three socket types behave differently:

| Type | Delivery | What happens when the receiver is gone |
| --- | --- | --- |
| `tcp` | Ordered and acknowledged by the network layer | The connection fails or waits, and the device reports an error or blocks |
| `udp` | One datagram per record, no acknowledgement | Records are lost without any error |
| `unix` | A local socket file | The device fails if no process listens on the file |

Prefer `tcp` for audit records you must not lose. `udp` is only acceptable for a second copy that you can afford to lose. A `unix` socket suits a collector that runs on the same machine as OpenBao, for example as a sidecar.

## write_timeout

The option `write_timeout` limits how long the device waits for a write to finish. The default is two seconds. Without a limit, a receiver that accepts the connection and never reads would stall every request, because OpenBao waits for all devices to finish writing before it answers. With a limit, the device gives up, reports an error, and the other devices decide whether the request succeeds.

A device path can be enabled only once, so disable the device first and enable it again with the new option:

```sh
bao audit disable socket
bao audit enable -path=socket socket address=audit-sink.clients.svc.cluster.local:9090 socket_type=tcp write_timeout=5s
```

Choose a value that is longer than a normal write to your collector and shorter than the time your clients wait for OpenBao. A value that is too short makes the device fail during short pauses of the collector. A value that is too long makes every request slow when the collector hangs.

## Testing what happens when the receiver is gone

In the playground, the receiver is the Deployment `audit-sink`. Compare the effect of one device and of two.

First, make the socket device the only device. List the devices with `bao audit list`, and disable every other one with `bao audit disable <path>`. Then stop the receiver and make a request:

```sh
kubectl -n clients scale deploy/audit-sink --replicas=0
bao kv get secret/inventory/db
```

With the only device unable to write, OpenBao refuses the request. Start the receiver again:

```sh
kubectl -n clients scale deploy/audit-sink --replicas=1
kubectl -n clients rollout status deploy/audit-sink
```

Now enable a file device next to the socket device, scale the receiver down again and repeat the request. This time the request succeeds, because one device recorded it. The socket device reports an error to the server log in the meantime. Read it:

```sh
kubectl -n openbao logs openbao-0 --tail=20
```

Look for lines that name the audit device and an error. The records that the socket device could not send are not delivered later. The file device is the complete copy, and the socket device is the shipping path.

## The other network device

The `http` device sends each record to a web endpoint. It follows the same idea as the socket device, with the same trade-off between losing records and holding up requests. The course does not run one, because it needs an endpoint that accepts and acknowledges records; if you use it in production, test the failure of the endpoint as in this part.

## Common pitfalls

> [!WARNING]
> - **Using `udp` as the only copy.** Lost records are not reported.
> - **A socket device as the only device.** A receiver outage then stops OpenBao.
> - **Leaving `write_timeout` unreviewed.** A hung collector slows every request for the length of the timeout.
> - **Assuming a record that failed to send is retried.** It is lost for that device. Keep a file device as the complete copy.

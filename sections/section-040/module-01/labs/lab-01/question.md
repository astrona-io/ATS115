# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Audit

## Scenario

The compliance team wants every request to OpenBao recorded twice: once in a file on the audit volume of the OpenBao pod, and once on the central log collector, which listens for TCP connections at `audit-sink.clients.svc.cluster.local:9090`. Today no audit device is enabled. The server configuration allows creating audit devices through the API, and the audit volume is mounted at `/openbao/audit`.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

1. Enable a `file` audit device at the path `file/` that writes to `/openbao/audit/audit.log`.
2. Enable a `socket` audit device at the path `socket/` that sends records over TCP to `audit-sink.clients.svc.cluster.local:9090`.
3. Prove that one request reached both devices.

## Constraints

- Use exactly the paths `file/` and `socket/`.
- Do not write the audit log to `stdout` or to `/tmp`.
- Do not change the `audit-sink` Deployment.

## Done when

- `bao audit list` shows `file/` with the file path above and `socket/` with the address above.
- A secret value written after your change is found, in its hashed form, in `/openbao/audit/audit.log` and in the log of `audit-sink`.

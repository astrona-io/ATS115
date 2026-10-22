# Prerequisites

Before starting this lab you should be able to:

- Enable and list audit devices with `bao audit enable` and `bao audit list`.
- Find a value in an audit log with `sys/audit-hash`.
- Change Helm values with `helm upgrade` and restart a StatefulSet pod.

## What the environment gives you

The environment builds itself before the task begins. It takes a few minutes:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`), installed
  with the `openbao` Helm chart 0.30.4, **initialized and unsealed**. The
  lab-only unseal key and root token are in the Secret `openbao-init`; a real
  installation never keeps them in a Kubernetes Secret.
- **Helm 3.22.1** and the **`bao` CLI 2.7.1** in `/usr/local/bin` or
  `~/.local/bin` on your machine.
- OpenBao answers at `http://openbao.localtest.me:8200`. Run
  `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal
  and `export BAO_ADDR=http://openbao.localtest.me:8200`. If the name does not
  resolve, add `127.0.0.1 openbao.localtest.me` to `/etc/hosts`. Log in with
  `export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)`.
- KV with an example secret, an audit volume at /openbao/audit and the TCP listener audit-sink.
- An audit volume mounted at `/openbao/audit` in `openbao-0`, and the TCP
  listener `audit-sink` in the namespace `clients` on port `9090`, which
  prints what it receives to its log. The server configuration allows
  creating audit devices through the API (`unsafe_allow_api_audit_creation`).

## Working rules

- Everything is graded on the **final state**, so check your result at the end
  and leave the fix in place.
- Change one thing at a time and check again.
- If `openbao-0` restarts, OpenBao is sealed again. Unseal it with the key in
  `openbao-init` before you continue.

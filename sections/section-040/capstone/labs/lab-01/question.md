# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Audit

## Scenario

OpenBao's only audit device was enabled through the API at `file/` and writes to `/tmp/audit.log`, inside the container, so every pod restart throws the log away. The server configuration still contains `unsafe_allow_api_audit_creation = true`, so anyone with `sudo` on `sys/audit` can add or remove devices. The audit volume is mounted at `/openbao/audit` and is empty.

OpenBao was installed with the Helm release `openbao` in the namespace `openbao` (chart `openbao/openbao` 0.30.4). The lab-only unseal key and root token are in the Secret `openbao-init`.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

1. Declare a `file` audit device at the path `file-persistent` in the server configuration, writing to `/openbao/audit/audit.log`.
2. Remove the API-created device at `file/`.
3. Turn off creating audit devices through the API.
4. Leave OpenBao running and unsealed.

## Constraints

- Change the server configuration through the Helm release, not by editing the ConfigMap by hand.
- Do not re-initialize OpenBao.

## Done when

- The server configuration in the ConfigMap `openbao-config` contains the `audit` stanza for `file-persistent` and no `unsafe_allow_api_audit_creation = true`.
- `bao audit list` shows `file-persistent/`, and no device writes to `/tmp/audit.log`.
- A secret value written after your change is found, hashed, in `/openbao/audit/audit.log`.
- Enabling a new audit device through the API is refused.

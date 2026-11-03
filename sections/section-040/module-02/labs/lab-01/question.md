# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Audit

## Scenario

A test left the audit device `debug/` enabled. It writes to `/openbao/audit/debug.log` with `log_raw=true` and `hmac_accessor=false`, so every secret that crossed the server is in that file in clear text, including `secret/billing/api`. The server configuration allows creating audit devices through the API, and the audit volume is mounted at `/openbao/audit`.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

1. Enable a `file` audit device at the path `file/` that writes to `/openbao/audit/audit.log`, with the file mode `0600`, with list responses elided, and with values and accessors hashed.
2. Disable the audit device `debug/`.
3. Remove the file `/openbao/audit/debug.log` from the audit volume.
4. Prove that a new secret value does not appear in clear text in `/openbao/audit/audit.log`.

## Constraints

- Do not enable the new device with `log_raw=true` or `hmac_accessor=false`.
- Do not use `stdout` as the file path.
- Do not leave any request unrecorded: enable the new device before you disable the old one.

## Done when

- `bao audit list -detailed` shows `file/` with the path above, `mode` `0600` and `elide_list_responses` `true`, and does not show `debug/`.
- `log_raw` is not `true` and `hmac_accessor` is not `false` on `file/`.
- The file `/openbao/audit/debug.log` no longer exists.
- A value written after your change is found, in its hashed form, in `/openbao/audit/audit.log`, and not in clear text.

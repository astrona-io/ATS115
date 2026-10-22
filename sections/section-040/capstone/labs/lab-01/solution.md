# Solution: Move Auditing Into The Server Configuration

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass.

The grader reads the ConfigMap `openbao-config`, lists the audit devices, writes a secret and looks for its hash in `/openbao/audit/audit.log`, and tries to enable a new device through the API.

## Step 1: Look at the current devices and configuration

Start the port-forward and log in as shown in the task. Then read both:

```sh
bao audit list -detailed
kubectl -n openbao get configmap openbao-config -o jsonpath='{.data.extraconfig-from-values\.hcl}'
```

The only device is `file/` with `file_path=/tmp/audit.log`, and the configuration contains `unsafe_allow_api_audit_creation = true`.

## Step 2: Disable the API-created device

Do this while API changes are still allowed:

```sh
bao audit disable file/
```

Until the declared device is active, OpenBao has no audit device, so requests are not recorded. Keep this window short.

## Step 3: Change the Helm values

Get the values in use, then edit them:

```sh
helm get values openbao -n openbao -o yaml > openbao-values.yaml
```

In `openbao-values.yaml`, in the `config` block under `server.standalone`, delete the comment and the line `unsafe_allow_api_audit_creation = true`, and add this stanza after `ui = true`:

```hcl
audit "file" "file-persistent" {
  description = "Audit log on the audit volume"
  options {
    file_path = "/openbao/audit/audit.log"
  }
}
```

Keep the rest of the file as it is, including `server.auditStorage`. Apply it:

```sh
helm upgrade openbao openbao/openbao --version 0.30.4 -n openbao --values openbao-values.yaml
kubectl -n openbao get configmap openbao-config -o jsonpath='{.data.extraconfig-from-values\.hcl}'
```

The ConfigMap shows the new configuration.

## Step 4: Restart and unseal

The chart's StatefulSet uses `OnDelete`, so delete the pod, then unseal the new one with the lab-only key:

```sh
kubectl -n openbao delete pod openbao-0
kubectl -n openbao exec openbao-0 -- bao operator unseal "$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.unseal-key}' | base64 -d)"
```

If the exec says the pod is not running yet, wait a few seconds and run it again. Start the port-forward again, then check the devices:

```sh
bao audit list -detailed
```

The list shows `file-persistent/` with the description and file path from the stanza.

## Step 5: Prove the new device records, and the API is closed

```sh
bao kv put secret/inventory/probe marker=capstone-check-3
HASH=$(bao write -field=hash sys/audit-hash/file-persistent input=capstone-check-3)
kubectl -n openbao exec openbao-0 -- grep -c "$HASH" /openbao/audit/audit.log
bao audit enable -path=test file file_path=discard
```

The count is at least one, and the last command is refused, because the server configuration no longer allows creating audit devices through the API.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Enable a second API device on `/openbao/audit` | The log survives restarts, but devices can still be added and removed through the API |
| Edit the ConfigMap with `kubectl edit` | The next `helm upgrade` overwrites it, and the task forbids it |
| Run `helm upgrade` without deleting the pod | `OnDelete` keeps the old pod with the old configuration running |
| Re-initialize to get a fresh server | Every secret and token is lost |

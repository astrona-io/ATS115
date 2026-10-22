# Solution: Hand Over An AppRole Secret ID And Revoke One Certificate

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass.

The grader checks that the wrapping token is used up, that an AppRole login with the stored values works, that the role has one secret ID, and which certificate leases still exist.

## Step 1: Read the handover and check the wrapping token

Start the port-forward and log in as shown in the task. Read the two values from the ConfigMap, then look the wrapping token up:

```sh
ROLE_ID=$(kubectl -n clients get configmap handoff -o jsonpath='{.data.role-id}')
WRAPPING_TOKEN=$(kubectl -n clients get configmap handoff -o jsonpath='{.data.wrapping-token}')
bao write sys/wrapping/lookup token="$WRAPPING_TOKEN"
```

The lookup succeeds, and `creation_path` is exactly `auth/approle/role/inventory/secret-id`. Had the lookup failed, or the path been different, the right reaction would be an alert, not a new secret ID.

## Step 2: Unwrap and store the credentials

```sh
SECRET_ID=$(bao unwrap -field=secret_id "$WRAPPING_TOKEN")
kubectl -n clients create secret generic inventory-approle \
  --from-literal=role-id="$ROLE_ID" --from-literal=secret-id="$SECRET_ID"
```

Prove the values work, and that the wrapping token is now used up:

```sh
bao write auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID"
bao write sys/wrapping/lookup token="$WRAPPING_TOKEN"
bao list auth/approle/role/inventory/secret-id
```

The login returns a token, the lookup fails, and the list shows one secret ID accessor.

## Step 3: Look up the leaked certificate's lease

The incident ConfigMap holds the certificate's serial number and the lease ID the security team recorded when the certificate was issued. Read both, and look the lease up before you revoke it:

```sh
LEASE_ID=$(kubectl -n clients get configmap incident -o jsonpath='{.data.compromised-lease-id}')
SERIAL=$(kubectl -n clients get configmap incident -o jsonpath='{.data.compromised-serial}')
bao lease lookup "$LEASE_ID"
bao list sys/leases/lookup/pki/issue/web
```

The lookup shows a lease under `pki/issue/web/`, and the list shows three leases: one per certificate.

## Step 4: Revoke that one lease

```sh
bao lease revoke "$LEASE_ID"
```

Check the certificate and the other leases:

```sh
bao read pki/cert/"$SERIAL"
bao list sys/leases/lookup/pki/issue/web
```

The certificate shows a non-zero `revocation_time`, and the list now has two entries.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Generate a fresh secret ID | The handover is bypassed and the role has two secret IDs; the grader counts them |
| `bao lease revoke -prefix pki/issue/web` | The two certificates in use are revoked too |
| Revoke the certificate with `pki/revoke` but keep the lease | The lease still exists; the grader checks the lease |

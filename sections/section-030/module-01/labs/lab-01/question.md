# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Response wrapping

## Scenario

The deployment pipeline prepared the inventory application's credentials. It stored the AppRole role ID and a **wrapping token** that holds a new secret ID in the ConfigMap `handoff` in the namespace `clients`. At the same time, the security team reports that the private key of the certificate for `admin.inventory.local` has leaked. Its serial number and lease ID are in the ConfigMap `incident` in the namespace `clients`. Two other certificates, for `shop.inventory.local` and `api.inventory.local`, are in use and must keep working.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

1. Check the wrapping token before you use it: it must be valid and its creation path must be `auth/approle/role/inventory/secret-id`.
2. Unwrap it, and store the role ID and the secret ID in a Kubernetes Secret named `inventory-approle` in the namespace `clients`, with the keys `role-id` and `secret-id`.
3. Revoke the lease of the `admin.inventory.local` certificate, and only that lease.

## Constraints

- Use the secret ID in the wrapping token. Do not generate another secret ID for the role `inventory`.
- Do not revoke the leases of the other two certificates.
- Do not use `-prefix` revocation.

## Done when

- The wrapping token can no longer be looked up, and an AppRole login with the values in `inventory-approle` succeeds.
- The role `inventory` has exactly one secret ID.
- The `admin.inventory.local` lease is gone and its certificate is revoked; the `shop` and `api` leases still exist.

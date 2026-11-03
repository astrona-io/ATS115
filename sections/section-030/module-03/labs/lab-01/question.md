# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Leases and incident response

## Scenario

The AppRole credentials of the application `billing` were printed in a build log. The security team gives you the ConfigMap `incident` in the namespace `clients`, which holds the accessor of the token that the credentials created and the accessor and value of the leaked secret ID.

That token has issued two certificates from `pki/issue/web` and created one child token. A second application, `inventory`, uses the same PKI role and the same AppRole method. It has its own token and one certificate, and it must keep working.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
kubectl -n clients get configmap incident -o yaml
```

## Your task

1. Stop the leaked `billing` secret ID from logging in again.
2. End the leaked `billing` token, its child token and the two certificates it issued.
3. Leave the AppRole role `billing` in place, so a new secret ID can be created later.

## Constraints

- Do not disable the mounts `pki/` or `approle/`.
- Do not revoke leases by the prefix `pki/issue/web`, and do not use `bao token revoke -mode=path`.
- Do not touch the token, the secret ID or the certificate of `inventory`.

## Done when

- The leaked secret ID cannot log in, and its accessor cannot be looked up.
- The `billing` token, its child and both of its certificate leases are invalid.
- The `inventory` token and certificate lease are still valid, and the role `billing` still exists.

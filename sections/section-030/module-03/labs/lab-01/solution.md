# Solution: Contain A Leaked Credential

Work the task yourself first. Running `astrona submit -c sections/section-030/module-03/labs/lab-01` after a step tells you which checks pass.

The grader looks the objects up by accessor and lease ID, tries the leaked secret ID, and checks that `inventory` is untouched.

## Step 1: Read the incident record

```sh
kubectl -n clients get configmap incident -o yaml
```

Note `token-accessor` and `secret-id-accessor`. Put them in shell variables:

```sh
TOKEN_ACCESSOR=$(kubectl -n clients get configmap incident -o jsonpath='{.data.token-accessor}')
SECRET_ID_ACCESSOR=$(kubectl -n clients get configmap incident -o jsonpath='{.data.secret-id-accessor}')
```

## Step 2: Contain by destroying the secret ID

```sh
bao write auth/approle/role/billing/secret-id-accessor/destroy secret_id_accessor="$SECRET_ID_ACCESSOR"
```

The leaked secret ID can no longer log in. The role stays.

## Step 3: Scope the token

```sh
bao token lookup -accessor "$TOKEN_ACCESSOR"
```

The lookup shows the policy `cert-issuer` and the AppRole login path. It shows that this token, and not a shared one, belongs to `billing`.

## Step 4: Revoke the token tree

```sh
bao token revoke -accessor "$TOKEN_ACCESSOR"
```

The token, its child token and the leases created with it are revoked. You do not need the lease IDs.

## Step 5: Verify

```sh
bao token lookup -accessor "$TOKEN_ACCESSOR"
bao write auth/approle/role/billing/secret-id-accessor/lookup secret_id_accessor="$SECRET_ID_ACCESSOR"
bao list sys/leases/lookup/pki/issue/web/
```

The first two commands fail. The list shows only the certificate lease of `inventory`, once the background revocation has finished.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `bao lease revoke -prefix pki/issue/web` | The certificate of `inventory` is revoked too |
| `bao secrets disable pki/` | Every certificate is revoked and the certificate authority is destroyed |
| `bao auth disable approle/` | The token of `inventory` and both roles are removed |
| Revoking the token and not destroying the secret ID | The leaked secret ID logs in again and creates a new token |

## Practice on your own

- Look up each of the two `billing` certificate leases and compare their `issue_time` with the token.
- Create a new secret ID for `billing` and deliver it in a wrapped response.

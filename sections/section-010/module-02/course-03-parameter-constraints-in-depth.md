# Parameter Constraints In Depth

A path rule says where a token may send a request. A parameter constraint says what the request body may contain. Constraints matter on paths where one endpoint can do harmless or harmful work depending on the fields: issuing a certificate for any name, creating a token with any policy, or setting a user's password. This part covers the three constraint fields and the order in which they apply.

## Which paths constraints work on

A constraint looks at the top-level keys of the JSON body that the client sends. A KV version 2 write wraps the secret in a key called `data`, so a constraint can see only `data`, not the fields inside it. Constraints are therefore not useful on KV version 2 paths. They are useful on engines and auth methods that take flat fields. This part uses the PKI role `web` in your playground, which signs certificates for names under `example.internal`.

<!-- astrona:playground:renew -->

Ask `bao` which rule a certificate request needs:

```sh
bao write -output-policy pki/issue/web common_name=shop.example.internal
```

The command prints a rule on `pki/issue/web` with the capability `update` and does not send the request. A certificate request is a write to the role's `issue` path, so it needs `update`.

## Allowed parameters

The field `allowed_parameters` is a map. Each key is a parameter name. Each value is a list of the values the client may send for it. An empty list means any value. Once the map exists, every parameter that is not a key of the map is refused.

Write a policy that lets a client request certificates only for two names, with a free choice of lifetime:

```sh
bao policy write web-issuer - <<'POLICY'
path "pki/issue/web" {
  capabilities = ["update"]
  allowed_parameters = {
    "common_name" = ["shop.example.internal", "api.example.internal"]
    "ttl"         = []
  }
}
POLICY
ISSUER=$(bao token create -policy=web-issuer -ttl=30m -field=token)
```

Test one request that fits the policy and two that do not:

```sh
BAO_TOKEN=$ISSUER bao write pki/issue/web common_name=shop.example.internal ttl=1h
BAO_TOKEN=$ISSUER bao write pki/issue/web common_name=admin.example.internal
BAO_TOKEN=$ISSUER bao write pki/issue/web common_name=shop.example.internal alt_names=www.example.internal
```

The first request returns a certificate. The second fails with `permission denied`, because `admin.example.internal` is not in the list. The third fails too: `alt_names` is not a key in the map, so the extra parameter is refused even though the name is allowed.

To allow every other parameter while still pinning some, add the key `"*"` with an empty list. It means "any parameter not listed above". The listed keys keep their own limits.

## Denied parameters

The field `denied_parameters` has the same shape and works the other way round. A value list names values that are refused; an empty list refuses the parameter completely. A denied parameter wins over an allowed one.

Add a rule to the same policy that opens the wildcard but refuses IP address subject alternative names:

```sh
bao policy write web-issuer - <<'POLICY'
path "pki/issue/web" {
  capabilities = ["update"]
  allowed_parameters = {
    "common_name" = ["shop.example.internal", "api.example.internal"]
    "*"           = []
  }
  denied_parameters = {
    "ip_sans" = []
  }
}
POLICY
BAO_TOKEN=$ISSUER bao write pki/issue/web common_name=shop.example.internal alt_names=www.example.internal
BAO_TOKEN=$ISSUER bao write pki/issue/web common_name=shop.example.internal ip_sans=127.0.0.1
```

The first request now works, because the wildcard lets `alt_names` through. The second is refused, because `ip_sans` is denied outright. The policy changed and the same token followed it at once.

## Required parameters

The field `required_parameters` is a list of parameter names. A request that leaves one out is refused before it reaches the endpoint. It protects against a request that is valid for the endpoint but too loose for your rule, such as a token request without an expiry.

```sh
bao policy write web-issuer - <<'POLICY'
path "pki/issue/web" {
  capabilities        = ["update"]
  required_parameters = ["common_name", "ttl"]
  allowed_parameters  = {
    "common_name" = ["shop.example.internal", "api.example.internal"]
    "ttl"         = []
  }
}
POLICY
BAO_TOKEN=$ISSUER bao write pki/issue/web common_name=shop.example.internal
BAO_TOKEN=$ISSUER bao write pki/issue/web common_name=shop.example.internal ttl=2h
```

The first request is refused because `ttl` is missing. The second succeeds. Note that the role's own `max_ttl` still caps the lifetime; a policy limits the request, and the role limits the result.

## Limits on response wrapping

A path rule can also force the client to wrap the response. The fields `min_wrapping_ttl` and `max_wrapping_ttl` take durations. When `min_wrapping_ttl` is set, a request without a `-wrap-ttl`, or with a shorter one, is refused. When `max_wrapping_ttl` is set, a longer wrapping lifetime is refused. Use them on paths that return secrets, so that the value never travels in plain form.

```hcl
path "pki/issue/web" {
  capabilities     = ["update"]
  min_wrapping_ttl = "1m"
  max_wrapping_ttl = "10m"
}
```

You can now limit the body of a request in three ways and force wrapping. The fields work together: the path decides if the rule applies, the capability decides the operation, and the constraints decide the content. What is still missing is how to give someone the right to manage policies themselves, without giving them everything.

## Common pitfalls

> [!WARNING]
> - **Using constraints on KV version 2.** The secret sits under the single key `data`, so a constraint on `password` never matches anything.
> - **Forgetting that `allowed_parameters` refuses everything not listed.** A new field that the application starts to send breaks the application, unless `"*" = []` is present.
> - **Expecting a value list to be a pattern.** The values are compared as given. Write each allowed value out.
> - **Relying on a constraint for secrets that the endpoint ignores.** A parameter the endpoint does not know is still passed on, and an unknown name in a constraint never matches. Check the endpoint's documented field names.

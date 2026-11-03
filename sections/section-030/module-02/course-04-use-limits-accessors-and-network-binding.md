# Use Limits, Accessors And Network Binding

A short TTL limits when a token works. Three other controls limit how it is used: a use count, a way to manage a token without knowing its secret value, and a restriction on where it can be used from. This part covers each, and ends with how to find and revoke a token you only know by its accessor.

## Use limits

A token can be created with a **use limit**: a number of requests after which OpenBao revokes the token. A token with a use limit of 1 is good for one request. This fits a handover where one party passes a token to another to do one thing.

<!-- astrona:playground:renew -->

```sh
LIMITED=$(bao token create -policy=worker-read -use-limit=2 -ttl=30m -field=token)
BAO_TOKEN=$LIMITED bao token lookup -format=json
```

The lookup is the first use, so `num_uses` in its answer shows what is left after it. Run the lookup again, which is the second use. The token is then revoked, and a third request fails with `permission denied`. Every request counts, including lookups and renewals, so a client library that looks up its token on start burns one use.

A use limit of `0` means unlimited, which is the default.

## Accessors

Every service token has an **accessor**, a second identifier that is not the token. An accessor can look up the token's properties, look up its capabilities on a path, renew it and revoke it. It cannot be used to make requests, so it is safe to store in a log or an inventory. The caller needs the right policy; the accessor does not carry rights.

```sh
ACCESSOR=$(bao token create -policy=worker-read -ttl=30m -field=token_accessor)
bao token lookup -accessor "$ACCESSOR"
bao token capabilities -accessor "$ACCESSOR" secret/data/worker/queue
bao token revoke -accessor "$ACCESSOR"
```

The lookup prints the fields of the token without its value. The capabilities command lists what that token can do on the path. The revoke ends the token and its children. Audit logs record accessors, so a line in the audit log leads to a token through its accessor.

To find all accessors, list them. The call needs `sudo` on the path, which the root token has:

```sh
bao list auth/token/accessors
```

The output lists one accessor per service token, which can be a long list on a busy server.

## Revoking with different modes

`bao token revoke` has modes. Without a flag it revokes the token and all its children. With `-mode=orphan` it revokes only the token and leaves the children as orphans. With `-mode=path` the argument is a path prefix instead of a token, and OpenBao revokes every token created under it, which is how you end all tokens from one login mount. Use `-mode=orphan` when a parent token must be retired but its children keep long-running work alive.

## Binding to network ranges

A token can be restricted to client addresses. On a role, `token_bound_cidrs` takes a list of Classless Inter-Domain Routing (CIDR) ranges such as `10.0.0.0/8`. A request with that token from outside the ranges is refused, even if the token is valid. This limits the damage of a stolen token: the thief must also be on the right network.

```sh
bao write auth/token/roles/worker-local allowed_policies=worker-read token_bound_cidrs=203.0.113.0/24
WTOKEN=$(bao token create -role=worker-local -field=token)
BAO_TOKEN=$WTOKEN bao token lookup
```

The lookup is refused, because the address OpenBao sees is not in the documentation test range `203.0.113.0/24`. Replace the range with the range of the address OpenBao sees to see the lookup succeed. Bound ranges are checked against the address OpenBao sees, so a load balancer that hides the client address needs the right forwarded-address settings, or the binding blocks everyone.

## Putting the controls together

A worker that starts a job needs a short, single-purpose token. A role that allows one policy, uses `token_type=batch`, has a TTL of the job length, and is bound to the cluster network is a tight fit. A long-running service needs a periodic token from a role with an orphan setting and a bound network. In both cases the application never sees a rule it could change, because everything that matters sits in the role.

You can now limit a token by use, find and manage one by its accessor, revoke in the mode that fits, and bind it to a network. These controls together turn a token from a general key into a narrow, expiring pass.

## Common pitfalls

> [!WARNING]
> - **Counting on a use limit for clients that look up their token.** Lookups and renewals use up the count.
> - **Storing token values in logs when accessors would do.** An accessor is safe to log, a token is not.
> - **Binding to a network behind a proxy.** OpenBao must see the real client address, or every request is refused.
> - **Revoking a parent when the children must live.** Use the orphan mode or create the children as orphans.

## Your mission: Make The Worker Role Strict

You can now read a token role, change it and prove what its tokens look like. The mission gives you a role named `worker` that lets callers request any policy, ends every token after 30 minutes and leaves the tokens as children of the creator. You change the role so it matches the rules above.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-115-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-115-lab-030-02
astrona start ats-115-playground-030-02
```

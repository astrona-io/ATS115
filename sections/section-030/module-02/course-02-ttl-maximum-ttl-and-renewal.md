# TTL, Maximum TTL And Renewal

A token has a time to live, the TTL: the time left before it expires. Several settings at several levels all say what the TTL may be, and the answer is always the shortest limit that applies. Understanding the combination lets you predict when a token will stop working, instead of finding out in production.

## The fields of a token lookup

Create a token and read the time fields:

```sh
TOKEN=$(bao token create -policy=worker-read -ttl=10m -explicit-max-ttl=1h -field=token)
bao token lookup "$TOKEN"
```

The lookup shows `creation_ttl`, the lifetime requested at creation, `ttl`, the time left now, `expire_time`, the moment the token expires, `explicit_max_ttl`, a hard cap that no renewal can pass, and `renewable`. A renewable token can have its TTL extended by `bao token renew`.

## Where the limits come from

Four levels decide the TTL, and OpenBao applies the lowest:

- The **system maximum TTL**, 32 days by default, set in the server configuration.
- The **mount maximum TTL**, set with `bao auth tune -max-lease-ttl=...` on an auth mount. For tokens created by `bao token create`, the mount is `token/`.
- The **role or auth method setting**, such as `token_ttl` and `token_max_ttl` on a role or a user.
- The **request**, for example `-ttl=10m`, which can ask for less but never for more than the other levels allow.

When a request asks for more than the limits allow, OpenBao does not refuse it. It gives the longest TTL that is allowed and says nothing. Compare the TTL you asked for with the TTL in the response, every time.

Ask for 100 days and see what you get:

```sh
bao token create -policy=worker-read -ttl=2400h -format=json
```

The `lease_duration` in the response is shorter than 2400 hours. It is the system maximum, 32 days or 768 hours, unless the server configuration or the `token/` mount sets a lower value.

## Renewing a token

A holder keeps a token alive by renewing it. `bao token renew` asks OpenBao to set the TTL to a new value, called the increment, counted from now. The increment is a request, and the limits still apply: the new TTL is never past the maximum, and the explicit maximum TTL is a hard end.

```sh
bao token renew -increment=2h "$TOKEN"
bao token lookup "$TOKEN"
```

The token was created with `-ttl=10m` and `-explicit-max-ttl=1h`. The renewal asks for two hours. The lookup shows a TTL near one hour minus the time used, because the explicit maximum TTL cut the increment. The token can not be extended past the hard end, however often it is renewed.

A token that is not renewed expires at the end of its TTL, and OpenBao revokes it together with its children and leases. The time of the renewal does not matter for the maximum: an old, often-renewed token reaches its maximum like any other.

## Tuning the token mount

The mount for tokens can have its own defaults. The values apply to tokens that do not ask for a TTL, and to the cap on those that do:

```sh
bao auth tune -default-lease-ttl=1h -max-lease-ttl=8h token/
bao read sys/auth/token/tune
```

The read shows `default_lease_ttl` and `max_lease_ttl` in seconds. After this change, a token created without a TTL lives 1 hour, and no token created in this mount can have a longer TTL than 8 hours. Existing tokens keep the TTL they have. Set the values back after you try it:

```sh
bao auth tune -default-lease-ttl=0 -max-lease-ttl=0 token/
```

A value of `0` means "use the system default".

## Periodic and explicit maximums together

A periodic token has no ordinary maximum, but it can still have an explicit maximum TTL, and the explicit maximum wins: the token ends when it is reached, even if the holder renews on time. This gives you a way to say "this service token is renewed every hour, but is replaced after 30 days anyway":

```sh
bao token create -period=1h -explicit-max-ttl=720h -policy=worker-read -format=json
```

You can now predict when a token expires from the four limits and the explicit maximum, and you know that renewal cannot pass a hard end. The next part moves the decision of what a token may be from the person who asks for it to a role.

## Common pitfalls

> [!WARNING]
> - **Assuming the requested TTL is the granted TTL.** A request above the limits is silently reduced. Read `lease_duration` in the response.
> - **Renewing to avoid a rotation.** A token with an explicit maximum TTL ends on schedule. The application must fetch a new token before that.
> - **Tuning the mount and expecting old tokens to change.** Tuning affects new tokens and renewals only.
> - **Setting a very short maximum on a mount shared by many clients.** Every client with a longer need breaks at once.

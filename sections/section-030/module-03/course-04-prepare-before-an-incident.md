# Prepare Before An Incident

A good response is mostly decided before the incident. Short lifetimes limit how long a leaked value works. Separate paths and roles limit which applications one command reaches. A practiced runbook limits the time spent deciding. This part lists the settings and habits that make the response small.

## Short lifetimes

Every credential lifetime is a limit on the damage of a leak. Set them on purpose:

- Give tokens from AppRole roles a short `token_ttl`, and a `token_max_ttl` the application can live with. Use periodic tokens only for services that renew.
- Give certificate roles a short `max_ttl` and a mount default that is lower than the system default.
- Give secret IDs a `secret_id_ttl` and, for a single login, `secret_id_num_uses`.

<!-- astrona:playground:renew -->

```sh
bao write auth/approle/role/billing token_ttl=20m token_max_ttl=1h secret_id_ttl=1h secret_id_num_uses=1
bao read auth/approle/role/billing
```

The role keeps its other fields, and a secret ID from now on works once and for one hour. The tradeoff is operational: a short lifetime needs automation that renews or reissues without human steps. If the application cannot renew, a short lifetime is an outage, not a control.

## Separate paths and roles

A revocation scope is as small as the way you split identities. One AppRole per application gives one secret-ID store per application, and one token tree. A certificate role per application means `bao lease revoke -prefix pki/issue/<role>` ends only that application's certificates. Compare that with one shared role, where the same prefix ends them all.

Use the same idea for policies. A policy per application, written for the paths it needs, means a leak of one token reaches only those paths. A token with a wide policy makes the scope step of the runbook long.

## Delivery that does not leak

Secret IDs are the most common leak, because they are passed on. Deliver them in wrapped responses with a short wrapping TTL, as the response wrapping module showed, so a log that shows the wrapping token shows a token that is already used. A wrapped secret ID that was used by someone else is also a signal: the legitimate receiver finds the unwrap fails.

## Know where the evidence is

Enable audit devices before an incident. An audit log made afterwards has nothing from the leak. A later section covers devices, formats and investigation. Here the rule is: no audit device, no scope.

Keep an inventory of the accessors of long-lived tokens, such as periodic tokens of services. An accessor can be stored and logged without risk, and it lets you act on a token without ever reading it.

## Practice the response

Run the runbook against a test credential on a schedule. Create a token, give it a lease, treat it as leaked, and time each step. The result shows which command is slow, which scope is too wide, and which application breaks. Fix the cause, for example a shared role, while there is no pressure.

Check these points in each drill:

- You found the accessor without reading the token.
- You revoked at the lowest scope that covered the leak.
- A lookup of every revoked object failed.
- A lookup of an unrelated token and lease still worked.

## Common pitfalls

> [!WARNING]
> - **Very short lifetimes without renewal.** The application fails at the end of every period.
> - **One role for everything.** The only safe scope becomes "everything".
> - **Turning on audit after an incident.** The evidence is already missing.
> - **Skipping drills.** The first run of the runbook should not happen during a real leak.

## Your mission: Contain A Leaked Credential

You can now read a lease, choose a revocation scope and follow the runbook. The mission puts you on duty. The AppRole credentials of the `billing` application have leaked. The token that the credentials created has issued certificates and has a child token. Another application, `inventory`, runs on the same mounts and must not notice anything.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-115-playground-030-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-030/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-115-lab-030-03
astrona start ats-115-playground-030-03
```

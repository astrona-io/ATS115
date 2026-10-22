# Section 030: Response Wrapping And Leases

A secret is most exposed on its way to the application and after the application stops needing it. Response wrapping protects the first: OpenBao hands out a single-use token instead of the secret, so whoever carries it never sees the value, and a stolen token is noticed. Leases protect the second: every dynamic secret and token has a lifetime, and OpenBao can end it early, for one secret or for a whole tree of tokens at once.

**Topic covered:** Wrapping and leases

## What you will learn

- Response wrapping: what a wrapping token holds, `-wrap-ttl`, and the `X-Vault-Wrap-TTL` header.
- Checking a wrapping token before unwrapping it, and what a failed lookup means.
- Handing an AppRole secret ID to an application in a wrapping token.
- Leases: lookup, renew, revoke one lease, and revoke a prefix.
- The token tree: child tokens, orphan tokens, and what a revocation takes with it.
- Requiring wrapping with `min_wrapping_ttl` and `max_wrapping_ttl` in a policy.

## The learning path

### 1. Hand Over Secrets Safely And Control Their Lifetime

The module starts at its landing page, which also launches the playground. The playground holds OpenBao with KV, an AppRole role `inventory` and a PKI secrets engine whose role `web` issues certificates with leases.

1. Response Wrapping
2. Checking And Unwrapping A Wrapping Token
3. Leases, Renewal And Revocation Trees, followed by the lab **Hand Over An AppRole Secret ID And Revoke One Certificate**
4. Summary

## Section capstone: Contain A Leaked Token Tree

A build orchestrator's token has leaked. It created a child token, which issued certificates, while a separate orphan token runs releases. The capstone asks you to revoke everything the leaked token created, leave the orphan alone, and make sure secret IDs can only leave OpenBao wrapped from now on.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-115-capstone-030
```

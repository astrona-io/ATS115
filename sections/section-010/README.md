# Section 010: Writing Policies

Every request to OpenBao carries a token, and every token carries policies. A policy is a named set of rules that says which paths the token may use and with which capabilities. When no rule allows a request, OpenBao refuses it with `permission denied`. When a rule allows too much, nothing tells you: the application just has more access than it needs.

This section teaches you to write policies that allow exactly what an application needs, and to prove it. You start with the parts of a rule, then learn how OpenBao chooses one rule when several match, and finish with testing a policy against real requests before anybody depends on it.

**Topic covered:** Policies

## What you will learn

- The parts of a path rule, and the capabilities `create`, `read`, `update`, `patch`, `delete`, `list`, `scan`, `sudo` and `deny`.
- Why a KV version 2 mount needs rules on `secret/data/...` and `secret/metadata/...`, not on `secret/...`.
- Globs at the end of a path, the `+` segment, and the priority rules OpenBao uses when several rules match.
- How `deny` beats every other capability.
- Parameter constraints: limiting which fields a request may send.
- Testing a policy with a fresh token, `bao token capabilities` and the `-output-policy` flag.

## The learning path

### 1. Write Least-Privilege Policies

The module starts at its landing page, which also launches the playground. The playground holds OpenBao with a KV version 2 mount at `secret/` and example secrets for three teams.

1. Paths And Capabilities
2. How OpenBao Matches A Request To A Rule
3. Testing Policies And Reading A Permission Denied, followed by the lab **Fix The Inventory Application Policy**
4. Summary

## Section capstone: Repair Policies That Deny Or Allow Too Much

The capstone is one graded scenario with three faulty policies. One denies the secret its application needs, one never matches because of a glob in the wrong place, and one allows far more than the application uses. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-115-capstone-010
```

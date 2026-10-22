# ATS115 — Access Control Policies, Leases & Audit Devices (OpenBao)

Course material for the **Access Control Policies, Leases & Audit Devices**
domain of the Astrona OpenBao training path
([ATP022](https://github.com/astrona-io/ATP022)), which is **15% of the
path**. Written for **OpenBao v2.7.1**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the OpenBao 2.7 documentation and source. None has been started on a
> cluster, and no lab has passed `astrona test` yet. See `CLAUDE.md` for the
> ranked list of facts to check first.

The course opens with an Introduction in `sections/intro/` (welcome, machine
setup, how the course is made). Everything else lives under `sections/`. Each
section contains:

- **A module** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining the section into a single
  scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Writing Policies | 1 | 1 + capstone | Policies |
| [020](sections/section-020) | Templated Policies And Control Groups | 1 | 1 + capstone | Identity-aware policies |
| [030](sections/section-030) | Response Wrapping And Leases | 1 | 1 + capstone | Wrapping and leases |
| [040](sections/section-040) | Audit Devices | 1 | 1 + capstone | Audit |

The order follows a request through OpenBao. A policy decides whether the
request is allowed at all. Identity and control groups decide whether this
caller, now, may make it. Wrapping and leases decide how the answer travels
and how long it stays valid. Audit devices record what happened.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Write Least-Privilege Policies](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Write Identity-Aware Policies And Control Groups](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Hand Over Secrets Safely And Control Their Lifetime](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Audit Every Request](sections/section-040/module-01/course.md) | 3 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Repair Policies That Deny Or Allow Too Much | a deny on the wrong path, a glob in the middle of a path, an over-broad policy with `sudo` |
| [020](sections/section-020/capstone/labs/lab-01) | Make Payroll Reads Need An Approval | a control group factor naming a group that does not exist, the policy on the wrong group, an empty approvers group |
| [030](sections/section-030/capstone/labs/lab-01) | Contain A Leaked Token Tree | a leaked parent token with a child and leases, an orphan that must survive, a policy that does not force wrapping |
| [040](sections/section-040/capstone/labs/lab-01) | Move Auditing Into The Server Configuration | an API-created device writing to `/tmp`, API audit creation left on |

---

## The lab environment

Every playground and lab is a **kind** cluster with OpenBao v2.7.1 installed
by the `openbao` Helm chart 0.30.4, **initialized and unsealed** with one
lab-only key share. The unseal key and root token are kept in the Secret
`openbao-init` in the namespace `openbao` so scripts and graders can use
them; a real installation never does this.

OpenBao answers at `http://openbao.localtest.me:8200` everywhere: on the
reader's machine through `kubectl -n openbao port-forward svc/openbao 8200:8200`,
and inside the cluster through a CoreDNS rewrite. The environment installs the
`bao` CLI 2.7.1 and Helm 3.22.1 on the reader's machine.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** with independent checks. Graders create
their own tokens and log in as the example users, so they test the policies
and not the reader's token. Several reject the plausible-but-wrong fix:
giving an application `sudo`, attaching a policy to every user, generating a
new secret ID instead of using the wrapped one, or revoking an orphan token
together with a leaked tree.

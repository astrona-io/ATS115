# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS115 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Access Control Policies, Leases & Audit Devices**
  domain of the **OpenBao** training path (`ATP022`). It is 15% of the path.
  There is no official OpenBao certification exam; the path's domains and
  weights are Astrona's own, set in `ATP022/path.yaml`.
- **What the domain really tests:** deciding who may do what in OpenBao,
  and proving afterwards who did it. The student must *do* things: write a
  policy and prove with a real token that it allows exactly the right
  requests, build per-user areas with identity templates, require a second
  person's approval with a control group, hand a secret over in a wrapping
  token, revoke one lease or a whole token tree, and find a request in two
  audit logs. Every fix is proved with requests that succeed and requests
  that are refused.
- **The four topics:** writing policies, templated policies and control
  groups, response wrapping and leases, and audit devices.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Writing Policies | Policies |
  | 020 | Templated Policies And Control Groups | Identity-aware policies |
  | 030 | Response Wrapping And Leases | Wrapping and leases |
  | 040 | Audit Devices | Audit |

- **The versions:** **OpenBao v2.7.1** (server and `bao` CLI), installed
  with the `openbao` Helm chart **0.30.4** and Helm **3.22.1** on a
  single-node `kind` cluster. The documentation version is 2.7.x.
- **The main sources:** the OpenBao documentation, <https://openbao.org/docs/>,
  and the source of `openbao/openbao` at tag `v2.7.1`
  (`website/content/docs/`). Facts in this course were read from
  `concepts/policies.mdx`, `concepts/control-groups.mdx`,
  `concepts/response-wrapping.mdx`, `concepts/lease.mdx`, `audit/*.mdx`,
  `configuration/audit.mdx`, `configuration/index.mdx` and
  `api/system/audit-hash.mdx` at that tag.
- **OpenBao is not Vault.** Use OpenBao names (`bao`, `BAO_ADDR`,
  `BAO_TOKEN`). OpenBao 2.7 has control groups (identity-group factors only).
  The HTTP header for the token and for wrapping is still `X-Vault-Token`
  and `X-Vault-Wrap-TTL`, as the OpenBao API documentation shows.

### Status: built, not yet run

The first version of this repository was written from the OpenBao 2.7
documentation **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

Doubts to check first, most important first:

1. **Control group responses.** `sys/control-group/authorize` with
   `{"accessor": ...}` is confirmed by `api/system/control-group.mdx` at
   v2.7.1. Still unconfirmed: that a held KV read answers with
   `wrap_info.token` and `wrap_info.accessor`, that unwrapping returns the
   original KV response (`.data.data`), and that `bao policy write` accepts a
   factor naming a group that does not exist (the section 020 capstone seeds
   one).
2. **Policy writes with a `*` in the middle.** The section 010 capstone seeds
   the path `secret/data/*/reports`. The docs say a glob only works at the
   end; the seed assumes OpenBao stores such a path as a literal instead of
   refusing it.
3. **PKI leases.** Section 030 relies on `generate_lease=true` on a PKI role
   giving each certificate a lease, `bao lease revoke` revoking the
   certificate (`pki/cert/<serial>` then shows a `revocation_time`), and
   leases of a token being revoked with the token.
4. **Wrapping limits.** The section 030 capstone grader expects a request
   without `X-Vault-Wrap-TTL` to a path with `min_wrapping_ttl` to fail, and
   one above `max_wrapping_ttl` to fail.
5. **Audit devices.** `bao audit enable` works only with
   `unsafe_allow_api_audit_creation = true` in the server configuration
   (since 2.3.2). The socket device tests its connection when it is enabled,
   so `audit-sink` must be up. The declarative `audit` stanza needs a pod
   restart (the chart uses the `OnDelete` update strategy) and an unseal.
6. **Smaller items:** `bao login -method=userpass -token-only -no-store`,
   the `display_name` prefix `token-` on created tokens, the file audit
   device's default mode `0600` on the audit volume, `bao token capabilities`
   printing `deny` when no rule matches,
   `bao write -f -wrap-ttl=60m -field=wrapping_token`,
   `bao secrets enable -version=2 kv`, the `LIST` verb through `curl -X LIST`,
   and `sys/leases/lookup` with `PUT`.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Policy | A named set of HCL rules that says which paths a token may use and with which capabilities |
| Path rule | One `path "..." { ... }` block; the path may end in a glob `*`, and `+` matches exactly one path segment |
| Capability | A permission on a path: `create`, `read`, `update`, `patch`, `delete`, `list`, `scan`, `sudo`, or `deny` |
| `deny` | A capability that refuses the request, whatever any other matching rule allows |
| Parameter constraints | `allowed_parameters`, `denied_parameters` and `required_parameters`: which request fields and values a rule accepts |
| `default` policy | The policy attached to almost every token; it lets a token look itself up, renew and revoke itself |
| Templated policy | A policy whose paths contain `{{identity...}}` parameters that OpenBao fills in from the token's entity and groups |
| Identity entity / alias / group | The record of one person or machine / its login name on one auth method / a set of entities that share policies |
| Control group | A `control_group` factor in a policy rule: the request is held, wrapped, until enough members of named identity groups approve it |
| Response wrapping | OpenBao puts a response in the cubbyhole of a new single-use token and returns that token instead of the secret |
| Wrapping token | The single-use token that holds a wrapped response; `bao unwrap` returns the response and uses the token up |
| Lease | The time a dynamic secret or token is valid; OpenBao revokes it when the lease ends or is revoked |
| Revocation tree | Child tokens and the leases a token created are revoked together with the token; an orphan token has no parent |
| Audit device | A component that writes every request and response to a destination: `file`, `socket`, `syslog` or `http` |
| Audit hash | The HMAC-SHA256 of a value with one audit device's salt; `sys/audit-hash/<path>` computes it so a value can be found in the log |
| Declarative audit | An `audit` stanza in the server configuration file instead of `bao audit enable` |

### The example workloads

| Name | What it is |
| --- | --- |
| OpenBao (namespace `openbao`, Helm release `openbao`) | OpenBao v2.7.1, pod `openbao-0`, Service `openbao` on port `8200`, Integrated Storage (`raft`) on a PersistentVolumeClaim, no TLS (lab-only). Every environment starts **initialized and unsealed** |
| Secret `openbao-init` (namespace `openbao`) | The lab-only unseal key (`unseal-key`) and root token (`root-token`). Say on the page that a real installation never keeps these in a Kubernetes Secret |
| `tester` (namespace `clients`) | `nicolaka/netshoot:v0.13` with `curl` and `jq`; graders call the HTTP API from here |
| `audit-sink` (namespace `clients`, section 040 only) | `alpine/socat:1.8.1.3` listening on TCP port `9090` and printing what it receives; the target of the socket audit device |
| KV version 2 at `secret/` | `secret/inventory/{db,api,reports}`, `secret/billing/{db,admin,reports}`, `secret/ci/registry`, `secret/payroll/salaries`, `secret/users/bob/notes` (depending on the section) |
| userpass users (section 020) | `alice`, `bob`, `carol`, `dave`, password `<name>-password`, each with an entity of the same name; groups `staff` (alice, bob, dave), `payroll`, `approvers` |
| AppRole role `inventory`, PKI role `web` (section 030) | The role whose secret ID is handed over; a PKI mount whose role `web` issues certificates for `*.inventory.local` with `generate_lease=true` |

### Environment facts the text must respect

- **One address everywhere: `http://openbao.localtest.me:8200`**, through a
  CoreDNS `rewrite stop` block (with the answer name rewritten back) in the
  cluster and `kubectl -n openbao port-forward svc/openbao 8200:8200` on the
  reader's machine. Pages set `export BAO_ADDR=http://openbao.localtest.me:8200`
  and log in with the root token from `openbao-init`, and say that this is
  lab-only. Never copy the one-line `rewrite name` form.
- **The `bao` CLI runs on the reader's machine.** Scripts run it in the pod:
  `kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=... bao ...`.
- **A pod restart seals OpenBao.** The chart's update strategy is `OnDelete`,
  so a changed server configuration only applies after
  `kubectl -n openbao delete pod openbao-0`, and the new pod must be unsealed
  with the key in `openbao-init`.
- **Section 040 environments** add an audit volume (`server.auditStorage`,
  mounted at `/openbao/audit`), the `audit-sink` listener, and
  `unsafe_allow_api_audit_creation = true` in the server configuration so
  `bao audit enable` works. The syslog audit device always writes to a local
  syslog daemon, which the OpenBao container does not have, so syslog is
  taught in prose and the graded devices are `file` and `socket`.
- **Graders use their own short-lived tokens** (`bao token create -policy=...`)
  or userpass logins, so they test the policy, not the reader's token.

### Where things are in this repo

Same layout as every Astrona course: `astrona.yaml`, `README.md`,
`sections/intro/`, `sections/section-0N0/README.md`, module pages,
`playground/` (`config.yaml`, `bootstrap/prepare.sh`,
`manifests/openbao-values.yaml`, `manifests/lab-start.yaml`,
`docs/overview.md`), labs (`config.yaml`, `README.md`, `prerequisites.md`,
`question.md`, `solution.md`, `bootstrap/01-install-openbao.sh`,
`bootstrap/02-seed-state.sh`, `manifests/`, `solution/apply.sh`,
`testing/wait-for-openbao.sh`, `validation/validate-*.sh`) and one capstone
per section.

**Generated plumbing.** Everything except the learner pages (`course*.md`,
section `README.md`, `question.md`, `solution.md`, `docs/overview.md`) was
written by a generator from one set of shared helpers: the manifests, the
bootstrap, testing, solution and validation scripts, `config.yaml`, the
author `README.md` and `prerequisites.md`. The generator is not part of this
repository. Every script starts with the same `shared helpers` block: when
you change a helper, change it in every script.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS115`, domain `Access Control Policies, Leases &
Audit Devices`, weight `15`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order.

- `topic`: exactly one of `policies`, `templating`, `control-groups`,
  `response-wrapping`, `leases`, `audit`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `acl-policy`, `capabilities`,
  `glob-path`, `plus-segment`, `deny`, `parameter-constraints`, `kv-v2`,
  `token-capabilities`, `default-policy`, `templated-policy`,
  `identity-entity`, `identity-group`, `userpass`, `control-group`,
  `approval`, `response-wrapping`, `wrap-ttl`, `unwrap`, `approle`,
  `secret-id`, `lease`, `lease-revoke`, `revocation-tree`, `orphan-token`,
  `pki-lease`, `audit-device`, `file-audit`, `socket-audit`, `audit-hash`,
  `declarative-audit`, `helm-values`.
- `resources`: 1 to 4 pages on `openbao.org`. The only place outside links
  are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-010/module-01/playground
astrona destroy ats-115-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-115-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-115-playground-<section>-<module>`, `ats-115-lab-<section>-<module>`,
`ats-115-capstone-<section>`. Graders check **behaviour** (requests that must
succeed and requests that must be refused, a control group flow from request
to unwrap, a hash found in an audit log) and reject the plausible but wrong
fix (giving the application the root token or `sudo`, attaching a policy to
every user instead of a group, generating a new secret ID instead of using
the wrapped one, revoking an orphan with the leaked tree, re-creating
groups). A lab's `question.md` and `solution.md` must match what its
`validation/` scripts check.

### Where to find trusted sources

- **Policies:** <https://openbao.org/docs/concepts/policies/>
- **Control groups:** <https://openbao.org/docs/concepts/control-groups/>
- **Identity:** <https://openbao.org/docs/concepts/identity/>
- **Response wrapping:** <https://openbao.org/docs/concepts/response-wrapping/>
- **Leases:** <https://openbao.org/docs/concepts/lease/>
- **Audit devices:** <https://openbao.org/docs/audit/>,
  <https://openbao.org/docs/configuration/audit/>
- **Commands:** <https://openbao.org/docs/commands/>

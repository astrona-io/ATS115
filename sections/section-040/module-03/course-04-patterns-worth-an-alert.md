# Patterns Worth An Alert

An investigation starts after something has already happened. A few patterns in the audit log give an earlier warning. This part lists them, explains why each matters, and shows how to check for them in a log. Where you run the checks continuously, a log collector or monitoring system does the same filtering and sends a message.

## Repeated refusals from one identity

One refused request is normal. Many refused requests from one identity in a short time is probing: someone is testing which paths work.

<!-- astrona:playground:renew -->

```sh
jq -s '[.[] | select(.type=="response" and (.error // "") != "")]
  | group_by(.auth.display_name)
  | map({name: .[0].auth.display_name, refusals: length})
  | sort_by(-.refusals)' audit.log
```

The result lists identities by the number of failed responses. Compare it with a normal day. A new name at the top, or a normal name with a large count, deserves a look.

## Use of the root token

The root token should exist only for short tasks. Any request with the display name `root` outside a planned task is a finding:

```sh
jq -c 'select(.type=="request" and .auth.display_name=="root")
  | {time, op: .request.operation, path: .request.path}' audit.log
```

In the playground, every command you run uses the root token, so the list is long. In production it should be empty most of the time.

## Changes to what is recorded

Disabling or changing an audit device is the action that hides other actions. Watch requests to `sys/audit`:

```sh
jq -c 'select(.type=="request" and (.request.path | startswith("sys/audit")))
  | {time, name: .auth.display_name, op: .request.operation, path: .request.path}' audit.log
```

Because a disabled device stops writing, the last record of the change may appear only in the other devices. This is one more reason to run more than one device, and to ship records to a place that the administrators cannot edit.

## Changes to policies and identities

A person who can change policies can give themselves access. Watch writes to the policy and identity paths:

```sh
jq -c 'select(.type=="request" and .request.operation != "read" and .request.operation != "list"
  and ((.request.path | startswith("sys/policies/")) or (.request.path | startswith("identity/"))))
  | {time, name: .auth.display_name, op: .request.operation, path: .request.path}' audit.log
```

Every result should match a change that someone requested. Compare it with your change tickets.

## Unusual volume or breadth

A normal application reads the same few paths again and again. An identity that reads many different paths, or a token created for one job that lists the whole mount, is behaving unlike its job. List the distinct paths one identity touched, and count them:

```sh
jq -s '[.[] | select(.type=="request" and .auth.display_name=="userpass-dave") | .request.path] | unique | length' audit.log
```

Compare the number with what the application needs.

## Logins from unexpected addresses

Each request holds the address it came from. An application that always logs in from the cluster network and suddenly logs in from elsewhere is a signal. Group the logins by address:

```sh
jq -s '[.[] | select(.type=="request" and (.request.path | startswith("auth/")))]
  | group_by(.request.remote_address) | map({from: .[0].request.remote_address, logins: length})' audit.log
```

A short list of known addresses is the normal state.

## Turn a check into an alert

Each of these filters can run on a schedule on the shipped log, and send a message when the result is not empty. Start with the cheap, precise ones: any use of the root token, any request to `sys/audit`, any policy change. Add the ones that need a baseline, such as refusals and breadth, after you have seen a normal week.

## Common pitfalls

> [!WARNING]
> - **Alerting on everything.** A noisy alert is ignored. Start with the few precise ones.
> - **Alerts without a baseline.** A count means nothing until you know the normal count.
> - **Running checks only on the local file.** An attacker with access to the server can change it. Check the shipped copy.
> - **Silence as proof.** An empty result is only as good as the device that was writing at the time.

## Your mission: Find Who Read The Payroll Secret

You can now read a record, search by hash, follow an identity and recognize risky patterns. The mission is an investigation. Someone read `secret/payroll/salaries`, and you must report who, how often, and who tried and was refused.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-115-playground-040-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-040/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-115-lab-040-03
astrona start ats-115-playground-040-03
```

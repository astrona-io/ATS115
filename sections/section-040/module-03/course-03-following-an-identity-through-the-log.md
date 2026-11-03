# Following An Identity Through The Log

A single request tells you little. A timeline of everything one identity did tells you what happened. This part builds a timeline, from the first login to the last request, and turns it into a short report that a manager or an auditor can read.

## Start from the login

Every token starts with a login or a create request. In the log, a login request has the path of the auth method, for example `auth/userpass/login/bob`, and its response carries the new token in hashed form. Find the logins of one user:

<!-- astrona:playground:renew -->

```sh
jq -c 'select(.type=="request" and .request.path=="auth/userpass/login/bob")
  | {time, request_id: .request.id, from: .request.remote_address}' audit.log
```

Each result is a login of `bob`, with the time and the address it came from. Note the times and addresses. A login from an address that does not belong to the person is a finding by itself.

## Build the timeline

After you know the identity, list everything it did in time order:

```sh
jq -c 'select(.type=="request" and .auth.display_name=="userpass-bob")
  | {time, op: .request.operation, path: .request.path, from: .request.remote_address}' audit.log
```

The file is already in time order, so the output is too. Read it from top to bottom, and ask at each line whether the identity had a reason to make the request.

## Add the outcome

A request line says what was asked. The response line says what happened. Join them by request ID:

```sh
jq -s 'group_by(.request.id)
  | map({id: .[0].request.id,
         time: .[0].time,
         name: .[0].auth.display_name,
         path: .[0].request.path,
         op: .[0].request.operation,
         error: ([.[] | .error // empty] | first // "none")})
  | map(select(.name == "userpass-bob"))' audit.log
```

Each object is one call with its outcome. Calls with an error other than `none` were refused or failed. The list shows what the identity could do, and what it tried and could not do.

## Follow the identity into tokens it made

An identity can create other tokens, and the new tokens write their own entries under a different accessor. If the timeline shows `auth/token/create` or a login of a new auth method, follow the new token:

1. Take the `auth.accessor` hash from the response entry of the create request.
2. Search the log for that hash.
3. Add those requests to the timeline.

The hash of an accessor in a response entry is the same hash that appears in later requests of that token, because it comes from the same device with the same salt. You do not need the value to follow it.

## Summarize for a reader

An audit finding is a short, factual statement. Write it as a list that a reader can check:

- **Who:** the display name, entity and policies.
- **When:** first and last request, and the login times.
- **From where:** the remote addresses.
- **What was read, written or listed:** the paths and counts.
- **What was refused:** the paths and the number of attempts.
- **What it did to the system:** token creation, policy changes, audit changes.

Do not guess motive. The log records requests, not reasons. State what happened and what is not known.

## Keep the evidence

Copy the log file you analyzed, with its checksum, to a place where it cannot be edited, before you start to filter. A conclusion drawn from a file that others can still change is weaker. Record the exact filters you ran. A colleague should be able to repeat your steps and reach the same numbers.

```sh
shasum -a 256 audit.log
```

## Common pitfalls

> [!WARNING]
> - **Reading the request lines only.** The response line tells you if the request worked.
> - **Dropping later tokens of the same identity.** Follow created tokens through their accessor hashes.
> - **Reporting motive.** The log shows actions, not intent.
> - **Analyzing the only copy.** Work on a copy with a checksum.

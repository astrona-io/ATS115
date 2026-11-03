# Reading An Audit Record

An audit log is a stream of JSON objects, one per line. Before you filter it, learn what one request looks like. This part shows how to take a log out of the pod, read the fields, and match a request to its response.

## Get the log

Copy the log to your machine so that you can read it many times without calling the cluster:

<!-- astrona:playground:renew -->

```sh
kubectl -n openbao exec openbao-0 -- cat /openbao/audit/audit.log > audit.log
wc -l audit.log
```

The `wc` command shows the number of lines. Every API request produces two lines, so the count is about twice the number of requests. Look at one line in a readable form:

```sh
head -n 1 audit.log | jq .
```

## Request and response entries

Each line has a `type`, which is `request` or `response`, and a `time`. The two lines of one API call carry the same `request.id`, so you can pair them. The main fields are:

| Field | What it tells you |
| --- | --- |
| `type` | `request` or `response` |
| `time` | When the entry was written |
| `auth.display_name` | A readable name for the identity, for example `userpass-bob` for a userpass login, or `root` for the root token |
| `auth.policies` and `auth.token_policies` | The policies the token carried |
| `auth.entity_id` | The identity entity of the caller, when there is one |
| `auth.client_token` and `auth.accessor` | Hashed values of the token and its accessor |
| `request.id` | The ID that pairs a request with its response |
| `request.operation` | `read`, `create`, `update`, `delete` or `list` |
| `request.path` | The API path, including the `data` segment for KV version 2 |
| `request.remote_address` | The address the request came from |
| `request.data` | The request body, with strings hashed |
| `response.data` | The response body, with strings hashed |
| `error` | The error text of a failed request |

Treat this table as a guide, not a schema. The fields that exist depend on the request: a login request has no token in the `auth` object, and a response may carry its own `auth` object with the new token. Look at real lines from your own server before writing a filter.

## Matching a request and a response

Take a request entry and find its response:

```sh
ID=$(jq -r 'select(.type=="request" and .request.path=="secret/data/general/handbook") | .request.id' audit.log | head -n 1)
jq --arg id "$ID" 'select(.request.id==$id)' audit.log
```

The output has two objects: the request with its operation and path, and the response with its data. If the call failed, the response has an `error` field.

## Success and refusal

A refused request still writes lines, which is what makes the audit log useful for catching probing. Find all entries with an error:

```sh
jq -c 'select(.error != null and .error != "") | {time, name: .auth.display_name, path: .request.path, error}' audit.log
```

A line that names a path and the text `permission denied` is a request that the policy refused. The lines before it show how the same identity got there.

## What the log does not hold

Remember the limits of the log:

- Strings of secret data are hashed. You can confirm that a known value was written or read, but you cannot read an unknown value from the log.
- Sealing and unsealing, and the health endpoints, are not recorded.
- The log shows the identity of the token that made a request, not the person behind it. Tie a token to a person with the identity that logged in: for a userpass login, the `display_name` includes the user name.

## Common pitfalls

> [!WARNING]
> - **Counting lines as requests.** Each request writes two lines. Filter on `type` before you count.
> - **Searching for a path without the `data` segment.** KV version 2 reads appear as `secret/data/...`, not `secret/...`.
> - **Trusting a filter you wrote once.** Check it against a real line, then against a request you know happened.
> - **Expecting to read an unknown secret from the log.** Hashing prevents that, and it is meant to.

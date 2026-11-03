# Solution: Find Who Read The Payroll Secret

Work the task yourself first. Running `astrona submit -c sections/section-040/module-03/labs/lab-01` after a step tells you which checks pass.

The grader compares your three values with the facts that the seed script produced, and checks that the log was not changed.

## Step 1: Copy the log

```sh
kubectl -n openbao exec openbao-0 -- cat /openbao/audit/audit.log > audit.log
wc -l audit.log
```

Work on the copy. Use `jq` on your machine, or run it in the tester pod with `kubectl -n clients exec -i deploy/tester -- jq`.

## Step 2: List the requests for the secret

```sh
jq -c 'select(.type=="request" and .request.path=="secret/data/payroll/salaries")
  | {time, name: .auth.display_name, op: .request.operation}' audit.log
```

Each line is one request. The root token created the secret during setup, so one line is a write. Look at the lines with the operation `read`: three come from one name, and one comes from another.

## Step 3: Separate success from refusal

```sh
jq -c 'select(.type=="response" and .request.path=="secret/data/payroll/salaries" and .request.operation=="read")
  | {time, name: .auth.display_name, error: (.error // "none")}' audit.log
```

The response with an error `permission denied` belongs to the user who was refused. The responses without an error belong to the user who read the secret.

## Step 4: Count

```sh
jq -s '[.[] | select(.type=="request" and .request.operation=="read" and .request.path=="secret/data/payroll/salaries")]
  | group_by(.auth.display_name) | map({name: .[0].auth.display_name, requests: length})' audit.log
```

Count request entries only. Counting both lines of each request doubles the number.

## Step 5: Write the answer

```sh
bao kv put secret/incident/answer reader=<user> reads=<number> denied=<user>
```

Replace the placeholders with the user names without the `userpass-` prefix, and the number.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Name the users that hold `payroll-read` | Bob and dave both qualify, and dave never read the secret |
| Count all lines for the path | Every request is counted twice |
| Search for `secret/payroll/salaries` without `data` | Nothing matches, because KV version 2 paths contain `data` |
| Delete or disable `file/` to start clean | The evidence is destroyed, and the check for an intact log fails |

## Practice on your own

- Build a timeline for the user who was refused and list every path they touched.
- Find the logins of each user and the address they came from.

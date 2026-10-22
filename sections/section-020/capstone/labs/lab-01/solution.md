# Solution: Make Payroll Reads Need An Approval

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass.

The grader runs the whole flow as `dave` and `carol`, checks that `alice` is refused, and compares the group IDs with the ones the environment created.

## Step 1: Read the policy and the groups

Start the port-forward and log in as shown in the task. Then read everything the rule depends on:

```sh
bao policy read payroll-read
bao list identity/group/name
bao read identity/group/name/staff
bao read identity/group/name/payroll
bao read identity/group/name/approvers
```

Three faults show up:

- The factor names the group `approver`, but the group is called `approvers`. A factor that names a group that does not exist can never be approved.
- `payroll-read` is attached to `staff`, so `alice` and `bob` can request payroll data. The group `payroll` has no policies.
- The group `approvers` has no members, so even with the right name nobody could approve.

## Step 2: Fix the factor

Save this as `payroll-read.hcl`:

```hcl
path "secret/data/payroll/*" {
  capabilities = ["read"]
  control_group = {
    factor "payroll-approval" {
      identity {
        group_names = ["approvers"]
        approvals   = 1
      }
    }
  }
}
```

Load it:

```sh
bao policy write payroll-read payroll-read.hcl
```

## Step 3: Move the policy to the right group, and fill the approvers group

The `policies` field of a group is replaced as a whole, so writing an empty value removes the policy from `staff`. The `member_entity_ids` field is replaced the same way:

```sh
entity_id() { bao read -field=id "identity/entity/name/$1"; }
bao write identity/group/name/staff policies=""
bao write identity/group/name/payroll policies=payroll-read
bao write identity/group/name/approvers member_entity_ids="$(entity_id carol)"
```

Writing to `identity/group/name/<name>` changes the existing group, so its ID stays the same.

## Step 4: Run the flow

```sh
DAVE=$(bao login -method=userpass -token-only -no-store username=dave password=dave-password)
BAO_TOKEN=$DAVE bao kv get secret/payroll/salaries
```

The output is a wrapping token, its accessor and the creation path, not the data. Copy the two values into variables; the values below are placeholders:

```sh
WRAPPING_TOKEN=<WRAPPING_TOKEN>
WRAPPING_ACCESSOR=<WRAPPING_ACCESSOR>
```

Approve as `carol`, then unwrap as `dave`:

```sh
CAROL=$(bao login -method=userpass -token-only -no-store username=carol password=carol-password)
BAO_TOKEN=$CAROL bao write sys/control-group/authorize accessor="$WRAPPING_ACCESSOR"
BAO_TOKEN=$DAVE bao unwrap "$WRAPPING_TOKEN"
```

The authorize call reports `approved` as `true`, and the unwrap returns the salaries.

## Step 5: Check that alice is refused

```sh
ALICE=$(bao login -method=userpass -token-only -no-store username=alice password=alice-password)
BAO_TOKEN=$ALICE bao kv get secret/payroll/salaries
```

The read fails with `permission denied`: `alice`'s groups no longer give her any rule on `secret/data/payroll/`.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Remove the control group | `dave` gets the data, and so does anyone with the policy, without approval |
| Create a new group named `approver` with `carol` in it | The approval works, but the rule now depends on a second, unexplained group; the grader requires the factor to name `approvers` |
| Add `dave` to `approvers` | He cannot approve his own request, because `self_authorization` defaults to `false` |
| Leave the policy on `staff` and add a `deny` for `alice` | `bob` can still request payroll data |

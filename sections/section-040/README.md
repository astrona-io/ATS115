# Section 040: Audit Devices

When a secret leaks, the first question is who read it, and when. OpenBao can answer only if an audit device recorded the request. An audit device writes every request and response to a destination, with the secret values replaced by salted hashes. This section shows what the audit log contains, how to enable devices, how to find a known value in a log, and how to declare devices in the server configuration so they cannot be switched off through the API.

**Topic covered:** Audit

## What you will learn

- What an audit device records, which paths it does not record, and how values are hashed.
- The `file`, `socket`, `syslog` and `http` devices, and why this course grades `file` and `socket`.
- Enabling devices with `bao audit enable`, and the `unsafe_allow_api_audit_creation` setting it needs.
- Finding a value in an audit log with `sys/audit-hash`.
- Declaring audit devices with an `audit` stanza in the server configuration.
- What happens to requests when no audit device can write.

## The learning path

### 1. Audit Every Request

The module starts at its landing page, which also launches the playground. The playground holds OpenBao with an audit volume mounted at `/openbao/audit` and a TCP listener, `audit-sink`, that prints whatever it receives.

1. Audit Devices And The Audit Log Format
2. Enabling File And Socket Audit Devices, followed by the lab **Send Every Request To Two Audit Devices**
3. Declarative Audit Devices And Blocked Logging
4. Summary

## Section capstone: Move Auditing Into The Server Configuration

The only audit device was enabled through the API and writes to `/tmp`, which is lost when the pod restarts, and creating audit devices through the API is still allowed. The capstone asks you to declare a device in the server configuration that writes to the audit volume, remove the old one, and turn API creation off.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-115-capstone-040
```

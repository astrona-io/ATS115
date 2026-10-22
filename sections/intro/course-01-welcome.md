# Welcome To The Course

This course trains you for the **Access Control Policies, Leases & Audit Devices** part of the Astrona **OpenBao** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, pods, Secrets, `kubectl exec` and `helm upgrade`. You have used OpenBao, or HashiCorp Vault, from the command line: you can log in with a token, enable a secrets engine and read and write a KV secret. You do not need to know policies, identity or audit devices yet. Each new idea is explained the first time it appears.

## What you can do at the end

OpenBao is an open-source server that stores secrets and decides who may read them. This course is about the deciding and the recording. It does not ask you to remember words. It asks you to write a rule, prove with real tokens that it allows exactly the right requests, and find afterwards who made a request. The course has four topics.

The first topic is **policies**. You will learn to:

- Write path rules with the right capabilities for a KV version 2 mount.
- Predict which rule wins when several rules match, and use `deny`, `+` and parameter constraints.
- Test a policy with a fresh token before an application depends on it, and read a permission denied.

Policies get more useful when they know who is calling, so the second topic is **templated policies and control groups**. You will learn to:

- Write one templated policy that gives every user their own area.
- Attach policies to identity groups.
- Hold a request until another person approves it with a control group.

The third topic is **response wrapping and leases**. You will learn to:

- Hand a secret to its consumer in a single-use wrapping token, and check that token first.
- Look up, renew and revoke leases, one at a time or a whole tree of tokens.
- Force wrapped responses with a policy.

The fourth topic is **audit devices**. You will learn to:

- Enable file and socket audit devices, and read the audit log format.
- Find a request in an audit log with the audit hash.
- Declare audit devices in the server configuration, and explain what happens when none can write.

Everything is written for **OpenBao v2.7.1**.

## The words this course uses

The pages use OpenBao's and Kubernetes' own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **token** is the credential that comes with every request to OpenBao. A **policy** is a named set of rules that says which **paths** a token may use and with which **capabilities**, such as `read` or `update`. An **identity entity** is OpenBao's record of one person or machine, and an **identity group** is a set of entities. A **lease** is the time a secret or token stays valid. An **audit device** writes every request and response to a destination such as a file.

| Term | What it is |
| --- | --- |
| Path | Where a request goes, for example `secret/data/inventory/db` |
| Capability | What a rule allows on a path: `create`, `read`, `update`, `patch`, `delete`, `list`, `scan`, `sudo` or `deny` |
| Wrapping token | A single-use token that holds a response until someone unwraps it |
| Audit hash | The salted hash OpenBao writes instead of a secret value in the audit log |

## The example setup in your playground

Every playground and lab runs OpenBao v2.7.1 in a small Kubernetes cluster on your machine. OpenBao starts **initialized and unsealed**, so you can work right away. The lab-only unseal key and root token are kept in a Kubernetes Secret, `openbao-init`, so the scripts can use them. A real installation never keeps them there.

A KV version 2 secrets engine at `secret/` holds example secrets for an inventory application, a billing application and a build system. Some modules add users (`alice`, `bob`, `carol` and `dave`), an AppRole role, certificates with leases, or an audit listener. Each module's landing page tells you what is there. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. They follow a request through OpenBao: whether it is allowed, whether this caller may make it now, how the answer travels and how long it lives, and how it is recorded.

| Section | What it covers |
| --- | --- |
| 010 | Writing Policies |
| 020 | Templated Policies And Control Groups |
| 030 | Response Wrapping And Leases |
| 040 | Audit Devices |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.

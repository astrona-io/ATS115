# How This Course Is Made

You will trust a course more when you know how it is built. This page tells you how the content is written and checked, who is behind it, and how you can help make it better.

## How the content is written

The course targets one version of OpenBao. Everything is written for **OpenBao v2.7.1**, so when a page says how OpenBao behaves, it means that version.

Facts come from real sources. They are checked against the official OpenBao documentation, in particular the concept pages on policies, control groups, response wrapping and leases, the audit device pages and the server configuration reference, and against the OpenBao source at the release v2.7.1, where that documentation lives. Each page then explains everything you need on the page itself, so you never have to leave the course to look something up.

Results are described honestly. When a page shows command output, it comes from a real run, and if the output is shortened, the page says so. If there was no real run to copy from, the page describes the result in words instead of making up output.

The same care goes into the graded labs, because their graders check behaviour. Every graded lab creates its own tokens or logs in as the lab's users and sends real requests: some must succeed and some must be refused. Others run a whole approval flow or find a request in an audit log. Many graders also reject the fix that only hides the problem, such as giving an application `sudo`, attaching a policy to every user, or generating a new secret instead of using the one handed over. Each lab also has a reference solution that is meant to be run against its own grader, so the grader is known to accept a correct answer.

The pages are written in plain English, for people who are not native English speakers and have no university degree. Words are written out in full, and each technical term gets a short, plain definition the first time it appears. The pages use the real technical terms, not metaphors, because those are the words you meet in the product, the logs and the documentation.

Finally, large parts of this course are drafted and edited with the help of AI tools. A maintainer reviews every change before it is published, and the technical checks above apply to all content, however it was written.

## Maintainers

A small group of people builds and looks after the course. The core maintainer is **Paris Nakita Kejser** ([@parisnakitakejser](https://github.com/parisnakitakejser)).

Many others have helped along the way. Every person who has changed the course is listed on the GitHub contributors page:
[github.com/astrona-io/ATS115/graphs/contributors](https://github.com/astrona-io/ATS115/graphs/contributors)

## Found a mistake? Report it

Even with these checks, mistakes slip through. If a command fails, a page says something wrong, or a lab grades a correct answer as wrong, please tell us. Every report makes the course better for the next learner. A good report takes four steps:

1. Open a new issue on GitHub: [github.com/astrona-io/ATS115/issues](https://github.com/astrona-io/ATS115/issues).
2. Say which page or lab it is (the file path is the easiest, for example `sections/section-010/module-01/labs/lab-01`).
3. Paste the command you ran and what you saw. Leave out passwords, tokens, unseal keys, private keys or anything else private. A token or unseal key you paste is enough to read secrets, so never paste one from a real server.
4. Say what you expected to happen instead.

Want to fix it yourself? Pull requests are welcome on the same repository.

## License

The course is published under the [Apache License 2.0](https://github.com/astrona-io/ATS115/blob/main/LICENSE). You are welcome to use it, share it and build on it under the terms of that license.

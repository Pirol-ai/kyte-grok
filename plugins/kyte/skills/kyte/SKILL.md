---
name: kyte
description: Work with the company's kyte workspace — customers, contacts, deals, products, projects, time entries and hours, invoices, processes, goals and key results, people, teams, absences and the company's documents. Use when the person asks about any of these, wants something looked up, logged, booked, created, changed or removed in kyte, or asks a question their company data can answer.
---

# Working in kyte

kyte is the person's company workspace — the company OS by Pirol Labs. This plugin starts the
`kyte` program on their own computer, which serves that workspace as tools. You work **as that
person**, under their permissions: what they may not see does not exist for you, and what they may
not change you cannot change.

## When to use this

Whenever the question or the task touches the company: a customer, a contact, a deal, a product, a
project, hours, an invoice, a process, a goal, a person, a team, an absence, a document. Reach for
the kyte tools before you reason from memory — the workspace is the record, you are not.

## Look things up before you answer

- Prefer the kyte tools over guessing, and over asking the person for data the workspace already
  holds.
- The `*_list` tools page their results. Narrow with `search` first; read on with `offset` when the
  answer needs more rows. A list says how many rows there are in total — say so when you show only
  some.
- Use the ids the tools return. Never invent an id, and never reuse one from a different kind of
  record.

## Before you change anything

- Change only what the person asked for. When the request is ambiguous — which customer, which
  project, which week — ask, or show what you found and ask which one.
- A `*_delete` cannot be undone from here. Name the record you are about to delete and get a clear
  yes first.
- A tool that answers `ok: false` changed nothing. Say so, with its reason — never report a change
  that did not happen.

## After you changed something

Say in one or two sentences what you changed: which record, which fields, the values before and
after where you know them. Every change is recorded in kyte as made by an agent on the person's
behalf.

## What does not happen here

Apps, extensions and new data structures are built in kyte itself, in its Extend mode, not through
these tools. When the person wants a new field, table or app, tell them to build it there.

## When the workspace itself cannot answer

Sometimes the program runs but the workspace is not available — nobody has signed in for that
folder, or the company's team server cannot be reached. kyte then serves a single tool that
explains the situation instead of the usual ones. Call it, relay what it says word for word, and
treat the workspace as unreadable until it is fixed.

## When there are no kyte tools at all

The plugin is installed but the connection is not: either the `kyte` program is missing from this
machine, or no workspace has been opened for the folder this plugin uses. Say so plainly, and until
it is fixed do not answer questions about the company — anything you say about their customers,
projects or hours without those tools is invention.

The person does both steps themselves; `grok mcp doctor kyte` shows how far they have come.

1. Install the kyte command line if `kyte --version` answers nothing. The installer and what it
   does are described at <https://kyte.pirol.ai/docs/en/mcp/> and in the README of
   <https://github.com/Pirol-ai/kyte-grok>. It writes one program, usually to `~/.local/bin/kyte` —
   a folder that is not always on the `PATH` yet, which is why a bare `kyte` can still answer
   "command not found" to someone who did everything right.

2. Sign in once, for this plugin's own folder:

   ```
   kyte login --db ~/.kyte/grok
   ```

   That folder is Grok's own copy of the workspace. kyte keeps an encrypted local copy and one
   folder serves one process, so a Grok session and a kyte session in a terminal pointed at the
   same folder would be two writers on one database.

Then start a new Grok session: the server is connected at session start, so a running session does
not pick it up.

# Porting notes

How to repoint these files at your own setup.

## Placeholder convention

The review skills were written against one monorepo. The structure is the
reusable part, the names are not, so names appear as angle-bracket
placeholders. Substitute your own before use.

| Placeholder | Stands for |
| --- | --- |
| `<ui-package>` | shared component library |
| `<utils-package>` | shared utility package |
| `<models-package>` | data access layer |
| `<constants-package>` | shared enums and constants |
| `<analytics-package>` | vendor-agnostic analytics client |
| `<events-package>` | event and job package |
| `<pkg>/` | any other package scope |
| `<orm>` | the project's ORM |
| `<query-lib>` | the project's server-state library |
| `<analytics-vendor>` | the product analytics vendor |
| `<analytics-vendor-b>` | a second analytics vendor, used where the example contrasts two |
| `<tracker-url>` | issue tracker base URL |
| `<schema-docs>` | the database schema reference doc |
| `<handler-wrapper>` | the shared lambda handler wrapper |
| `<queue-utils>` | the shared queue send helper |

Generic layout is left as-is: `client/`, `server/`, `packages/`. Those are
conventions rather than names, so they need no substitution.

Ticket ids in examples are placeholders too: `TICKET-1234`, `SUPPORT-1234`,
`PR-1234`. They illustrate a format rule and do not point anywhere.

## Not included yet

Hooks are shell scripts, so they land in a later pass. `settings.json` here
carries no `hooks` block for that reason.

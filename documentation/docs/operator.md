# For the operator: changing the server by chatting

You don't need to know anything about Azure, servers or code. You talk to
Claude in your web browser; Claude does the technical work and explains it.
Nothing changes until you say yes **and** someone clicks Approve on GitHub.

## What this is

The company's database lives on a computer rented from Microsoft, in a
data center ("Azure"). This website describes that computer: how big it is,
how much storage it has, and who is allowed to connect. When you want
something different, Claude writes the change down, GitHub's robot checks
what it would do, and only then is it made.

## How to ask for a change

1. Open Claude in your browser (the link Andrew gave you) and say what you
   want in your own words. For example:
    - "The database feels slow. Can we make the server bigger?"
    - "I'm working from home today and need to connect."
    - "What does this server cost us each month?"
    - "Explain what we have, like I'm new to this."
2. Claude explains what it would change, what it costs, and whether the
   database would be offline for a moment. Ask anything: "what does that
   mean?" is always a good question.
3. Claude prepares the change and shows you GitHub's check of it.
4. If you agree, say **yes**. If you're unsure, say **no** or "let's ask
   Andrew". Saying no never breaks anything.
5. Claude sends you a link. On that page, click **Review deployments**,
   tick **azure-production**, and click **Approve and deploy**. (If Andrew
   is the approver, he does this step.)
6. A few minutes later Claude tells you it's done.

## What is safe

- Asking questions: always safe, nothing changes.
- Saying no, or leaving a change waiting: safe.
- The server's data is protected: the setup refuses to delete the server or
  its disks, even by mistake.

## When to call Andrew

- Claude says a change would delete or rebuild something.
- Something says "failed" and Claude can't fix it.
- You're asked for a password or to type commands. You should never need
  to.

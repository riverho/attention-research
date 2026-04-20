---
name: attention-research
description: Scheduled intelligence research pipeline — monitors topics on a twice-daily cadence, produces signal-first digests, maintains META.json freshness state. Use for tracking geopolitical conflicts, AI trends, macro signals, climate, and biotech with structured state and delta-based updates.
metadata:
  {
    "openclaw":
      {
        "requires": { "bins": ["python3", "openclaw"] },
        "install":
          [
            {
              "id": "python",
              "kind": "node",
              "package": "python3",
              "label": "Python 3",
            },
            {
              "id": "pyyaml",
              "kind": "pip",
              "package": "pyyaml",
              "label": "PyYAML",
            },
            {
              "id": "tavily",
              "kind": "env",
              "label": "Tavily API key (TAVILY_API_KEY)",
            },
          ],
      },
  }
---

# attention-research Skill

Scheduled intelligence research pipeline with topic monitoring, freshness state, and signal-first digest delivery.

## What It Is

A twice-daily research cadence (morning + afternoon) that:
- Scans configured topics via Tavily
- Maintains per-topic freshness state in META.json
- Produces digests that connect signals, not just dump headlines
- Delivers via Telegram or WhatsApp

## Core Concepts

### Topic
A long-running monitoring domain (e.g., `us-iran-conflict`, `ai`, `geopolitics`).

### Thread
An active research question within a topic. Threads have state, typed connections, and delta updates.

### Digest
The default output surface. A structured readout of what changed and why.

### META.json Freshness Contract
Every topic has a `META.json` that acts as a shared freshness marker for all writers:
- Morning and afternoon slots have independent timestamps
- Max 2 retries per topic per day total
- After 2 failures → topic skipped for that day

## Research Root

`$HOME/.openclaw/workspace/notes/research-v2/`

## Package Structure

```
attention-research/
├── PROMPTS/
│   ├── CORE/                    # Generic — no domain
│   │   ├── system-prompt.md
│   │   ├── signal-rules.md
│   │   └── digest-format.md
│   ├── TOPICS/                  # Domain-specific — inherits CORE
│   │   ├── us-iran-conflict.md
│   │   ├── ai.md
│   │   ├── geopolitics.md
│   │   ├── finance-markets.md
│   │   ├── climate-changes.md
│   │   └── bio-tech.md
│   ├── TEMPLATES/
│   │   ├── morning-research.md
│   │   ├── afternoon-research.md
│   │   └── onboarding.md
│   └── GENERATOR/
│       ├── generator.md
│       └── from-paper.md
├── CONFIG/
│   ├── topics.yaml
│   └── default-paths.yaml
├── SCHEMA/
│   ├── META.json.template
│   └── entity.schema.json
├── SCRIPTS/
│   ├── research-executor.sh
│   └── setup-cron.sh
├── INSTALL/
│   └── install.sh
├── SKILL.md
├── README.md
└── package.json
```

## Installation

```bash
# Install via clawhub (after publishing)
clawhub install attention-research

# Or clone and install manually
git clone https://github.com/YOUR_USER/attention-research.git ~/.openclaw/skills/attention-research
cd ~/.openclaw/skills/attention-research
./INSTALL/install.sh --fresh
```

## Configuration

### topics.yaml — What to Track

```yaml
topics:
  us-iran-conflict:
    display_name: "US-Iran Conflict"
    description: "US-Iran tensions, Hormuz, nuclear talks, sanctions"
    enabled: true
    search_query: "US Iran conflict Hormuz nuclear talks"
```

### Delivery Channel

Edit `CONFIG/default-paths.yaml`:

```yaml
delivery:
  telegram:
    chat_id: "YOUR_CHAT_ID"
```

## Cron Jobs

| Job | Schedule | Purpose |
|-----|----------|---------|
| AR morning digest | 08:00 HKT | Morning research scan |
| AR afternoon update | 16:00 HKT | Afternoon research scan |

## Publishing

```bash
clawhub publish ./attention-research \
  --slug attention-research \
  --name "Attention Research Pipeline" \
  --version 1.0.0 \
  --changelog "Initial publish"
```

## Requirements

- Python 3 + PyYAML
- OpenClaw with cron daemon
- Tavily API key (`TAVILY_API_KEY` env var)
- Telegram or WhatsApp delivery channel
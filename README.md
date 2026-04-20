# attention-research

**Scheduled intelligence research pipeline for OpenClaw.**

An agentic workflow that monitors topics on a twice-daily cadence, connects signals across time, and delivers structured digests. Not a news aggregator. A signal-tracking system that reads the matrix and surfaces what changed.

---

## For Agents — How to Run This

### Prompt Stack Order

```
1. PROMPTS/CORE/system-prompt.md       ← generic base (always load first)
2. PROMPTS/CORE/signal-rules.md        ← what counts as signal
3. PROMPTS/CORE/digest-format.md       ← output format
4. PROMPTS/TOPICS/<topic>.md           ← domain-specific (one per topic)
5. PROMPTS/TEMPLATES/morning-research.md  ← for morning runs
   or
   PROMPTS/TEMPLATES/afternoon-research.md  ← for afternoon runs
```

CORE is the foundation. TOPICS inherits from it — adds domain nuance, never contradicts.

### Research Loop Per Topic

```
1. Read topics/<topic>/META.json
2. Freshness gate — skip if already updated this slot
3. Run Tavily search (web_search tool) — max 8 results, time range: day
4. Write news file: topics/<topic>/news/<topic>-YYYY-MM-DD.md
5. Update META.json timestamps
6. On failure: meta_record_failure, retry once if allowed
7. After all topics: produce digest from news files, not from new search
8. Deliver via message tool (Telegram or WhatsApp)
```

### META.json Freshness Contract

- `lastMorningUpdate` / `lastAfternoonUpdate` — prevents double-runs
- `retryCount` — max 2 failures per topic per day
- On success: reset `retryCount` to 0
- On 2 failures: skip permanently for that day

### Digest Production Rules

- Read news files only — do not re-search
- Connect signals across topics, not just within them
- Lead with behavior, not headline
- End each topic with "Read: one sentence on structural meaning"
- End with bottom line: what changed, what it implies, what to watch
- Mark freshness per topic: `[fresh]` / `[stale]` / `[retry N/2]` / `[exhausted]`

### Onboarding a New Topic

```
1. Load PROMPTS/TEMPLATES/onboarding.md
2. Check requirements (TAVILY_API_KEY, cron daemon, delivery channel, research root)
3. If requirements not met: tell human what's missing
4. If topic matches a pre-built template: propose defaults
5. If topic is new: propose generic entity weights + signal criteria + cadence
6. User approves / adjusts / drops a paper
7. If paper: read it, extract framework → write PROMPTS/TOPICS/<slug>.md
8. Show user the framework, ask for approval
9. On approval: add to CONFIG/topics.yaml, run setup-cron.sh, activate
```

### Building a Topic from a Paper

```
1. Load PROMPTS/GENERATOR/generator.md
2. Extract: domain, core thesis, key entities + weights, signal criteria,
   noise filters, confidence calibration, watch items, source hierarchy
3. Write PROMPTS/TOPICS/<topic-slug>.md — complete file, no placeholders
4. Inherit from CORE files — do not contradict
5. Show user the framework with: methodology, entity weights, signal criteria
6. User approves → activate
```

---

## For Humans — Setup and Interaction

### What You Need

| Requirement | How to get |
|-------------|------------|
| Tavily API key | Free tier at [tavily.com](https://tavily.com) |
| OpenClaw with cron daemon | `openclaw gateway start` |
| Telegram bot or WhatsApp | For digest delivery |
| Python 3 + PyYAML | `pip install pyyaml` |

### Installation

```bash
# Clone the repo
git clone https://github.com/river/attention-research.git \
  ~/.openclaw/skills/attention-research

# Run setup
cd ~/.openclaw/skills/attention-research
./INSTALL/install.sh --fresh

# Set your Tavily API key (stored in ~/.openclaw/workspace/.env)
export TAVILY_API_KEY=tvly-xxxx

# Verify cron jobs registered
openclaw cron status
```

### How to Interact

**Add a topic:**
> "I want to track biotech clinical results"

Agent proposes entities, signal criteria, noise filters, cadence. Approve, adjust, or drop a paper.

**Customize with a paper:**
> "Here's a paper on KRAS oncology — build the topic from it"

Agent extracts the framework and shows you the topic prompt. Approve to activate.

---

## Default Topics

| Topic | What it tracks |
|-------|----------------|
| `us-iran-conflict` | US-Iran tensions, Hormuz, nuclear talks, sanctions |
| `ai` | Frontier labs, infra, chip policy, regulation |
| `geopolitics` | Power shifts, diplomacy, bloc formation |
| `finance-markets` | Equities, bonds, rates, commodities, macro |
| `climate-changes` | Physical events, policy, transition risk |
| `bio-tech` | Clinical results, FDA decisions, drug pipelines |

---

## Architecture

```
Cron trigger (08:00 / 16:00 HKT)
    ↓
research-executor.sh
    ↓
META.json freshness gate
    ↓
Tavily search (fresh topics only)
    ↓
Write news files
    ↓
Update META.json
    ↓
Produce digest (CORE + TOPICS prompts)
    ↓
Deliver via Telegram/WhatsApp
```

---

## Directory Structure

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
│       └── generator.md
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

---

## Publishing

```bash
clawhub login
clawhub publish ./attention-research \
  --slug attention-research \
  --name "Attention Research Pipeline" \
  --version 1.0.0 \
  --changelog "Initial publish"
```

---

## Version History

| Version | Date | Summary |
|---------|------|---------|
| 1.0.0 | 2026-04-20 | Initial — CORE + TOPICS layered structure, 6 pre-built topics, paper-to-topic generator, requirements check, META.json freshness contract |

---

## License

MIT
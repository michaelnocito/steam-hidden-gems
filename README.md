# Steam Hidden Gems — SQL Analysis

A SQL analysis of the Steam game catalog to surface **"hidden gems"**: highly
rated games that haven't reached a mainstream audience. Built with SQLite and
DB Browser for SQLite.

> ### Why this project is worth a read
> This is a good example of **real-world data and how to troubleshoot it.** Public
> datasets are rarely clean — this one ships from Kaggle with a broken header that
> silently loads every value into the wrong column. The interesting part of the
> project isn't the final query; it's the process: *noticing* a result that
> couldn't be real, *diagnosing* the cause, *fixing* it without damaging the raw
> data, and *validating* the output against reality before trusting it. That
> troubleshooting loop is most of the actual job of a data analyst, and it's
> documented here step by step so you can follow the reasoning, not just the code.

### The analysis pipeline at a glance

```mermaid
flowchart LR
    A[Raw CSV<br/>from Kaggle] --> B[Fix broken header<br/>in a clean copy]
    B --> C[Import into SQLite<br/>table: games_raw]
    C --> D[Verify against a<br/>known record]
    D --> E[Filter the noise<br/>6 layers]
    E --> F[Validate results<br/>against reality]
    F --> G[175 hidden gems<br/>top 25 showcased]
```

## Data Source

**Steam Games Dataset** by FronkonGames (Kaggle, free):
https://www.kaggle.com/datasets/fronkongames/steam-games-dataset

The dataset contains ~125,000 games with review counts, pricing, ownership
estimates, playtime, genres, and tags.

> **Note:** the full dataset (~380 MB CSV / ~480 MB database) is **not** stored
> in this repo — it exceeds GitHub's 100 MB file limit. A 500-row sample
> (`handoff_bundle/steam_sample.csv`) is included so you can see the data
> shape, and the steps below let you rebuild the full database from the source.

## Data Cleaning Note: Malformed Header in Source File

While exploring the data I noticed `MAX(Positive)` returned a suspiciously flat
**100** across all 125,000+ games — implausible for Steam review counts.

**Diagnosis:** I validated a single known record (AppID 496350, *Supipara*)
against the raw file. The database showed `Positive = 0, Negative = 252`, but
the source row was actually `Positive = 252, Negative = 3`. Every column after
`Price` was shifted by one.

**Root cause:** the source CSV's **header row lists 39 columns while every data
row contains 40**. A missing comma fuses two columns — `Discount` and
`DLC count` — into a single `DiscountDLC count`. Because columns align by
**position**, every field after that point loads into the wrong column.

Here's the misalignment, using the *Supipara* row. One missing header name means
each data value lands one slot to the left of where it belongs:

```
                 Price │ Discount │ DLC count │ ... │ Positive │ Negative
                 ──────┼──────────┼───────────┼─────┼──────────┼─────────
 DATA VALUES:    5.24  │    65    │     0     │ ... │   252    │    3      ← what's really in the file
 BROKEN HEADER:  5.24  │      [DiscountDLC count]  │ ... │    0     │   252     ← 2 columns share 1 name → shift →
                              ▲ one name, two values          ▲ "Positive" now reads Negative's value
```

Think of it like buttoning a shirt with one button skipped: everything below the
mistake is off by one, even though each button is fastened.

**Confirmed at the source:** a fresh, untouched download from Kaggle exhibits
the identical defect, so it ships from the source rather than being introduced
during processing.

**Fix:** I corrected the header in a **cleaned copy** (`steam_clean.csv`),
leaving the raw file untouched, then re-imported. Verified against the known
record — Supipara now correctly reads `Positive = 252, Negative = 3`.

**Takeaway:** a result that looked wrong turned out to be a source-data defect,
not a query error. Validating against a trusted reference record caught it
before it could corrupt the analysis.

## Methodology: Filtering Out the Noise

"Hidden gems" only become visible after peeling away several layers of noise,
one filter at a time. Each filter is a deliberate judgment set from the data
(counts and distributions), not a guessed number.

| Layer | Noise | How it's filtered |
|------|-------|-------------------|
| 1 | **Structural** — misaligned columns from the broken header | Fixed at the source before any analysis (see above) |
| 2 | **Small-sample** — 3 reviews at 100% isn't better than 5,000 at 96% | Review floor: `(Positive + Negative) >= 2000` |
| 3 | **Popularity** — raw positive counts just rank the biggest games | Measure quality as a **percentage**, independent of size |
| 4 | **Mainstream** — a cheap, well-loved blockbuster isn't "hidden" | Keep only low ownership tiers (under ~200k owners) |
| 5 | **Missing data** — the `0 - 0` owners tier means "no estimate," not zero | Excluded explicitly |
| 6 | **Stale records** — delisted entries with corrupted values | Documented (see Validation), not silently kept |

Threshold tuning was evidence-driven — counting how many games survived each
combination until the list was a credible, browsable size:
`5,175 → 2,494 → 728 → 429 → 175`.

**Final criteria:** 2,000+ reviews, 95%+ positive rating, price ≤ $20, and a
low ownership tier (under ~200k, excluding `0 - 0`). **175 games qualify**; the
analysis showcases the top 25 by approval rating.

## Scope & Assumptions

Every filter left *out* is also a decision. This analysis is **language-agnostic**
— it does **not** filter on `Supported languages`, so the results include titles
that may be Chinese- or Japanese-only. As written, the list answers *"the
best-reviewed cheap, low-ownership games on Steam **globally**"* — not *"...that
a specific audience can play."* An English-only filter
(`AND "Supported languages" LIKE '%English%'`) is included, commented out, in the
query file for anyone who needs to scope results to an English-speaking audience.

Stating the audience assumption is deliberate: a "hidden gem" is only a gem to a
player who can actually understand it.

## Validation

Results were checked four ways before being trusted:

1. **Known-record check** — verified the column fix against a game whose true
   values were known (Supipara).
2. **Monotonicity check** — each stricter filter must return *fewer* games; a
   stricter test once returning *more* rows exposed a mis-run query.
3. **Count-before-trust** — checked how many games each filter returned before
   reading any names.
4. **Reality check** — compared final titles against real-world knowledge. This
   caught data artifacts the numbers alone would not:
   - *Batman: Arkham City* listed as **free** (Price = 0) with only ~2,075
     reviews — a stale/delisted entry, not a real free game.
   - *Portal 2* in the `0 - 20000` owners tier with **153,381 reviews** — more
     reviews than the owner ceiling allows, i.e. a corrupted record.
   - *GTA V Legacy* priced at 0 for the same reason.

**Takeaway:** `Price = 0` does not always mean free, and an ownership tier can be
wrong. A record can be internally valid yet contradict reality — human validation
is the last essential filter, and documenting what you find is what makes the
analysis trustworthy.

## How to Build the Database (step by step)

New to databases? This section assumes **zero prior setup**. By the end you'll
have a working SQLite database you can run the queries against.

### What you're building, in plain terms

- **SQLite** is a database that lives in a single file on your computer — no
  server, no install, no account. The whole database is one `.db` file.
- **DB Browser for SQLite** is a free app that lets you *see* that file like a
  spreadsheet and run SQL against it. Think of SQLite as the engine and DB
  Browser as the dashboard.
- A **CSV** is just a text file where commas separate columns. We load the CSV
  *into* SQLite so we can query it with SQL instead of scrolling a giant file.

### Step 0 — Install DB Browser for SQLite (one time)

1. Go to **https://sqlitebrowser.org/dl/**
2. Download the build for your OS (Windows/macOS) and install it like any app.
3. That's it — SQLite itself is bundled in, nothing else to install.

### Step 1 — Download the data

Download `games.csv` from the Kaggle dataset:
**https://www.kaggle.com/datasets/fronkongames/steam-games-dataset**
(A free Kaggle account is required to download. The file is ~380 MB.)

> ⚠️ **Do not open the CSV in Excel to "check" it first.** Excel can silently
> reformat dates, drop leading zeros, and re-save the file in a way that changes
> its structure. Leave the raw file untouched — we inspect it with tools that
> only *read*, never *edit*.

### Step 2 — Fix the broken header (in a COPY)

The raw file has the header defect described above. **Never edit the raw file in
place** — make a corrected copy so the original stays reproducible:

1. Make a duplicate of `games.csv` and name it `steam_clean.csv`.
2. Open **only the first line** of `steam_clean.csv` and find `DiscountDLC count`.
3. Change it to `Discount,DLC count` (add the missing comma).
4. Save. The header now has 40 names to match the 40 columns of data.

<details>
<summary>Prefer to do it without opening the file? (optional one-liner)</summary>

```bash
# Reads the raw file, fixes only the header, writes a clean copy. Data untouched.
sed '1s/DiscountDLC count/Discount,DLC count/' games.csv > steam_clean.csv
```
</details>

### Step 3 — Create the database

1. Open **DB Browser for SQLite**.
2. Click **New Database** and save it as `steam_games.db`.
3. When it pops up a "define table" dialog, click **Cancel** — we'll load the
   table from the CSV instead (easier and more reliable for a big file).

### Step 4 — Import the CSV

1. Menu: **File → Import → Table from CSV file…**
2. Select your `steam_clean.csv`.
3. In the import dialog:
   - **Table name:** `games_raw`
   - ✅ Check **"Column names in first line"**
   - Leave field/quote settings at their defaults (comma-separated, `"` quotes).
4. Click **OK**. DB Browser reads the whole file and builds the table — this
   works no matter how many rows the file has.

### Step 5 — Save

Click **Write Changes** in the top toolbar. (DB Browser does **not** auto-save;
nothing is written to the `.db` file until you do this.)

### Step 6 — Verify before you trust it ✅

Go to the **Execute SQL** tab, paste this, and hit ▶ Run:

```sql
SELECT AppID, Name, Positive, Negative, Price
FROM games_raw
WHERE AppID = 496350;
-- Expected: Positive = 252, Negative = 3, Price = 5.24
```

If you see **Positive = 252, Negative = 3, Price = 5.24**, the header fix worked
and every column is aligned. If `Positive` shows `0` and `Negative` shows `252`,
the header wasn't fixed — go back to Step 2.

You're now ready to run the analysis in [`queries/hidden_gems.sql`](queries/hidden_gems.sql).

### Troubleshooting

| Symptom | Likely cause | Fix |
|--------|--------------|-----|
| `no such table: games_raw` | Import didn't run, or table named differently | Re-do Step 4; confirm the table name is exactly `games_raw` |
| Verify query shows `Positive = 0` | Header not fixed | Redo Step 2 (the missing comma) and re-import |
| `MAX(Positive)` is a flat, tiny number | Columns misaligned | Same as above — the header fix didn't take |
| Numbers won't sort/compare correctly | Column imported as text | In the CSV import dialog, set numeric columns to Integer/Real, or wrap them in `CAST(col AS INTEGER)` in your query |
| Changes disappear after closing | Forgot to save | Click **Write Changes** (Step 5) |

## Files

| File | Description |
|------|-------------|
| `queries/*.sql` | Analysis queries |
| `handoff_bundle/steam_sample.csv` | 500-row sample of the cleaned data |
| `README.md` | This file |

Full data files and `steam_games.db` are excluded via `.gitignore` — rebuild
them locally using the steps above.

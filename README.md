# Steam Hidden Gems — SQL Analysis

A SQL analysis of the Steam game catalog to surface **"hidden gems"**: highly
rated games that haven't reached a mainstream audience. Built with SQLite and
DB Browser for SQLite.

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
position, every field after that point loads into the wrong column.

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

## How to Rebuild the Database

1. Download `games.csv` from the [Kaggle link](https://www.kaggle.com/datasets/fronkongames/steam-games-dataset).
2. Fix the header: change `DiscountDLC count` to `Discount,DLC count`
   (add the missing comma). Save as `steam_clean.csv`.
3. Open DB Browser for SQLite → **New Database** → save as `steam_games.db`.
4. **File → Import → Table from CSV file** → select `steam_clean.csv`.
   - Table name: `games_raw`
   - Check **"Column names in first line"**
5. Click **Write Changes** to save.
6. Verify the import:
   ```sql
   SELECT AppID, Name, Positive, Negative, Price
   FROM games_raw
   WHERE AppID = 496350;
   -- Expected: Positive = 252, Negative = 3, Price = 5.24
   ```

## Files

| File | Description |
|------|-------------|
| `queries/*.sql` | Analysis queries |
| `handoff_bundle/steam_sample.csv` | 500-row sample of the cleaned data |
| `README.md` | This file |

Full data files and `steam_games.db` are excluded via `.gitignore` — rebuild
them locally using the steps above.

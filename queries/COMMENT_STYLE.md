# SQL Teaching-Comment Style (CANON)

This is the required commenting style for every `.sql` file in this project
(`hidden_gems.sql`, `hidden_gems_joins.sql`, and any future ones). It exists so
the queries double as a learning resource. Follow it exactly. Do not invent a
different format.

The reference implementation is `hidden_gems.sql`. When in doubt, copy how it
already reads.

---

## The rule in one sentence

Every query is preceded by (1) a boxed **WHY** header and (2) a **read-out-loud
comment block that paraphrases each SQL clause in order** — and the SQL itself is
left CLEAN, with no comments inside the query body.

---

## The four required parts, in order

### 1. Boxed header with WHY
A full-width box, the step name, and a `WHY` that gives the analytical/business
reason for asking the question (not what the SQL does — the reason it exists).

```
-- ============================================================
-- STEP 4: Each game's positive review PERCENTAGE (quality)
-- WHY: Raw counts favor popular games; a hidden gem is about how
--      WELL-LOVED a game is, not how many reviewed it. Percentage
--      measures quality independent of size.
-- ============================================================
```

### 2. Read-out-loud block ABOVE the query
One line per SQL clause, in the exact order the clauses appear, each line
starting with that clause keyword. This is a plain-English paraphrase a beginner
can read top to bottom:

```
--SELECT Name, Positive, Negative, and a CALCULATED % positive column:
--FROM the games_raw table
--WHERE the game has at least 500 total reviews
--ORDER BY pct_positive DESC, then Positive DESC (tiebreaker)
--LIMIT the first 25 rows
```

### 3. Sub-bullets under SELECT for every function / calculation
Indented under the `--SELECT` line, one line per function or calculated piece,
in reading order, each saying what it does in plain words:

```
--SELECT Name, Positive, Negative, and a CALCULATED % positive column:
--   Positive / (Positive + Negative) * 100  =  % of reviews that are positive
--   CAST(... AS REAL) = treat as a decimal so division keeps decimals
--   ROUND(..., 1)     = round to 1 decimal place
--   AS pct_positive   = name (alias) the new column
```

For a nested calculation (like `ROUND(100.0 * SUM(CASE WHEN ...) / COUNT(*), 2)`),
list each function on its own sub-bullet in the order a person reads it, still as
sub-bullets under SELECT — NOT as inline comments inside the query.

### 4. The clean query
The SQL itself has NO inline comments. All teaching lives in the block above it.

```
SELECT Name, Positive, Negative,
       ROUND(CAST(Positive AS REAL) / (Positive + Negative) * 100, 1) AS pct_positive
FROM games_raw
WHERE (Positive + Negative) >= 500
ORDER BY pct_positive DESC, Positive DESC
LIMIT 25;
```

---

## Full worked example (this is the target)

```
-- ============================================================
-- STEP 4: Each game's positive review PERCENTAGE (quality)
-- WHY: Raw counts favor popular games; a hidden gem is about how
--      WELL-LOVED a game is, not how many reviewed it. Percentage
--      measures quality independent of size. The 500-review floor
--      removes tiny-sample noise; the tiebreaker ranks more-
--      reviewed games above equally-rated smaller ones.
-- ============================================================
--SELECT Name, Positive, Negative, and a CALCULATED % positive column:
--   Positive / (Positive + Negative) * 100  =  % of reviews that are positive
--   CAST(... AS REAL) = treat as a decimal so division keeps decimals
--   ROUND(..., 1)     = round to 1 decimal place
--   AS pct_positive   = name (alias) the new column
--FROM the games_raw table
--WHERE the game has at least 500 total reviews
--ORDER BY pct_positive DESC, then Positive DESC (tiebreaker)
--LIMIT the first 25 rows
SELECT Name, Positive, Negative,
       ROUND(CAST(Positive AS REAL) / (Positive + Negative) * 100, 1) AS pct_positive
FROM games_raw
WHERE (Positive + Negative) >= 500
ORDER BY pct_positive DESC, Positive DESC
LIMIT 25;
```

---

## Standing conventions

- **Comment the WHY, not just the WHAT.** The header says why the question
  matters; the read-out-loud block says what each clause does.
- **Teach a function the first ~3 times it appears, then phase out.** Once
  `ROUND`/`CAST` have been explained a few times, stop re-explaining them.
- **Keep a functions/keywords glossary at the top of the file** (see the
  "SQL FUNCTIONS & KEYWORDS USED" box in `hidden_gems.sql`). New file, new
  keywords (JOIN, GROUP BY, etc.) get added there.
- **Big-picture sections get their own boxes**, same width: the data-quality
  story, filtering-the-noise, scope & limitations, validation, best practices.
- **Document data defects and limitations openly** rather than hiding them.
- **Read a nested calculation inside-out** when explaining it (innermost
  function first), but still as sub-bullets under SELECT, never inline.
- **Never put comments inside the query body.** The query stays clean.
- **Voice:** plain English, calm, beginner-facing. No em-dashes in prose.

---

## What NOT to do (past mistakes)

- Do NOT put `-- like this` comments on the same line as SQL inside the query.
- Do NOT invent an "inside-out breakdown" format that isn't the clause-by-clause
  read-out-loud block above.
- Do NOT hand over bare SQL with no comments, ever.
- Do NOT skip the WHY header.
```

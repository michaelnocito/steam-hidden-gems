-- ############################################################
-- #  STEAM HIDDEN GEMS -- SQL ANALYSIS                       #
-- #  Find highly-rated games that never went mainstream.     #
-- #  Data: Kaggle "Steam Games Dataset" (fronkongames)       #
-- #  Tools: SQLite + DB Browser for SQLite                   #
-- ############################################################

-- ============================================================
-- ABOUT THIS FILE (read me first)
-- This analysis is written to be followed by someone learning
-- SQL and data analysis. Each query has:
--   WHY  -- the reason the question is being asked
--   a plain-English "read out loud" of what the SQL does
-- The sections below document HOW the data was cleaned, HOW we
-- filtered out noise, HOW we scoped the question, and HOW we
-- validated the results -- the reasoning matters as much as the
-- final query.
-- ============================================================

-- ============================================================
-- HOW TO STUDY THIS FILE (most important step -- IF you're learning)
-- These wall-to-wall comments are a LEARNING SCAFFOLD, not how you
-- comment real work. Two modes:
--   * LEARNING: keep the "read out loud" comments and rehearse them
--     (method below).
--   * PORTFOLIO / INDUSTRY: strip them to standard LIGHT comments --
--     intent + anything non-obvious. A comment on every obvious line
--     is a red flag in professional code.
--
-- LEARNING METHOD -- rehearse, don't just retype:
--   1. Take one small section at a time.
--   2. Type and quietly SAY the read-out-loud comment
--      (--SELECT the game's name, --WHERE at least 2,000 reviews...).
--   3. Repeat the section until you can say the narration out loud
--      SMOOTHLY, no stumbling -- that fluency means it clicked;
--      stumbling shows the exact gap to revisit.
--   4. THEN read/run the SQL; it now reads as the answer to a
--      sentence you can already say.
--   5. LEVEL UP: hide the SQL and rebuild the query from the comment.
-- WHY IT WORKS (real learning science):
--   * Self-explanation -- narrating a step in your own words deepens
--     understanding (smooth = you get it; halting = the gap).
--   * Generation effect -- producing beats reading (Slamecka & Graf
--     1978; ~d=0.40).
--   * Retrieval practice -- recalling beats re-reading, 61% vs 40%
--     at one week (Roediger & Karpicke 2006) -- why step 5 matters.
--   Full write-up: "How to Actually Learn From This" in README.
-- ============================================================

-- ============================================================
-- THE DATA-QUALITY STORY: a broken header in the source file
--
-- SYMPTOM: An early sanity check -- MAX(Positive) -- returned a
--   suspiciously flat 100 across all 125,000+ games. Real Steam
--   review counts reach the millions, so this was implausible.
--
-- DIAGNOSIS: We validated ONE known record (AppID 496350,
--   "Supipara") against the raw file. The database showed
--   Positive = 0, Negative = 252, but the source row was
--   actually Positive = 252, Negative = 3. Every column after
--   "Price" was shifted one position to the right.
--
-- ROOT CAUSE: The source CSV's HEADER row lists 39 columns, but
--   every DATA row has 40. A missing comma had fused two columns
--   -- "Discount" and "DLC count" -- into one ("DiscountDLC
--   count"). Because a database aligns data to headers BY
--   POSITION, one missing name pushed every later value into the
--   wrong column. (Confirmed by re-downloading from Kaggle: the
--   defect ships from the source, it was not introduced locally.)
--
-- FIX: We added the missing comma in a CLEANED COPY of the file
--   (steam_clean.csv), leaving the raw file untouched, then
--   re-imported. Verified against the known record afterward.
--
-- LESSON: A result that looks impossible is usually a DATA
--   problem, not a query problem. Always ask "is my logic wrong,
--   or is my data wrong?" -- and check a trusted record to tell.
-- ============================================================

-- ============================================================
-- FILTERING THE NOISE (the heart of this analysis)
--
-- Raw data is noisy. "Hidden gems" only become visible after
-- peeling away several layers of noise, one filter at a time:
--
--   1. STRUCTURAL noise -- misaligned columns from the broken
--      header. Fixed at the source (see story above) BEFORE any
--      analysis. Nothing downstream is trustworthy until this is.
--
--   2. SMALL-SAMPLE noise -- a game with 3 reviews at 100% is
--      not "better" than one with 5,000 at 96%. Fixed with a
--      review floor: WHERE (Positive + Negative) >= 2000.
--
--   3. POPULARITY noise -- raw positive counts just rank the
--      biggest games. Fixed by measuring QUALITY as a percentage
--      (Positive / total), independent of size.
--
--   4. MAINSTREAM noise -- a cheap, well-loved BLOCKBUSTER is
--      not "hidden." Fixed by keeping only low ownership tiers
--      (under ~200k owners) via the "Estimated owners" column.
--
--   5. MISSING-DATA noise -- the "0 - 0" owners tier means "no
--      estimate available," not "zero owners." Excluded, because
--      missing data must not be treated as a real value.
--
--   6. STALE-RECORD noise -- delisted / replaced store entries
--      that carry corrupted values (see VALIDATION below). These
--      can't be auto-removed from this data alone, so they are
--      DOCUMENTED rather than silently kept or dropped.
--
-- Each filter is a deliberate judgment, set by looking at counts
-- and distributions in the data -- never a number guessed blind.
-- ============================================================

-- ============================================================
-- SCOPE & LIMITATIONS (what this analysis does NOT filter -- on purpose)
--
-- LANGUAGE (intentionally NOT filtered):
--   This analysis ranks games on rating, price, and ownership
--   only. It does NOT filter on "Supported languages" or "Full
--   audio languages". As a result the list is LANGUAGE-AGNOSTIC
--   and includes titles that may be, e.g., Chinese- or
--   Japanese-only (several appear in the top 25).
--
--   WHY THIS MATTERS: a "hidden gem" is only a gem to a player
--   who can understand it. The right filter depends on the
--   AUDIENCE the analysis serves:
--     * Global / platform-wide view -> no language filter (as here).
--     * English-speaking players     -> add:
--           AND "Supported languages" LIKE '%English%'
--     * A specific market            -> filter to that language.
--
--   This is a deliberate scoping choice, not an oversight. As
--   written, the list answers "best-reviewed cheap, low-owner
--   games on Steam GLOBALLY" -- NOT "...that a given audience can
--   play." A ready-to-use English filter is included (commented
--   out) in the final queries below.
--
-- PRINCIPLE: every filter you leave OUT is also a decision. State
-- the audience assumption so results are never quietly misread.
-- ============================================================

-- ============================================================
-- VALIDATION STEPS (how we checked the results are real)
--
--   A. KNOWN-RECORD CHECK -- verified the column fix against a
--      game whose true values we knew (Supipara: 252 / 3 / 5.24).
--
--   B. MONOTONICITY CHECK -- while tuning thresholds, each
--      stricter filter must return FEWER games. When a stricter
--      test once returned MORE rows (429 > 178), we knew a query
--      had been mis-run in the GUI, and re-ran it. A stricter
--      filter returning more rows is logically impossible.
--
--   C. COUNT-BEFORE-TRUST -- checked HOW MANY games each filter
--      returned (5,175 -> 728 -> 429 -> 175) to land on a
--      browsable, credible list size before reading names.
--
--   D. REALITY CHECK on the final lists -- confirmed titles
--      against real-world knowledge. This caught artifacts the
--      numbers alone would not:
--        * "Batman: Arkham City" appeared as FREE (Price = 0)
--          with only ~2,075 reviews. The real game is paid and
--          far more reviewed -> a stale/delisted entry.
--        * "Portal 2" appeared in the "0 - 20000 owners" tier
--          with 153,381 reviews -- more reviews than the owner
--          ceiling, which is impossible -> a corrupted record.
--        * "GTA V Legacy" showed Price = 0 for the same reason.
--
--   TAKEAWAY: Price = 0 does NOT always mean free, and an
--   ownership tier can be wrong. A record can be internally
--   valid yet contradict reality. Human validation is the last,
--   essential filter -- and documenting what you found (rather
--   than hiding it) is what makes the analysis trustworthy.
-- ============================================================

-- ============================================================
-- BEST PRACTICES USED IN THIS PROJECT
--   * Never edit raw data in place -- clean into a COPY, so the
--     original is always reproducible.
--   * Keep the raw file, the cleaned file, and the queries all
--     in version control; large data stays out of git (.gitignore).
--   * Set thresholds from evidence (counts/distributions), not guesses.
--   * Comment the WHY, not just the WHAT.
--   * State scope and audience assumptions explicitly.
--   * Validate against a known record AND against reality.
--   * Document data defects and limitations openly.
-- ============================================================

-- ============================================================
-- SQL FUNCTIONS & KEYWORDS USED (quick reference)
--   SELECT ...        choose which columns to display
--   FROM <table>      which table to pull from
--   WHERE ...         keep only rows meeting a condition
--   AND               combine conditions (ALL must be true)
--   ORDER BY ... DESC sort results (DESC = highest first)
--   LIMIT n           return only the first n rows
--   AS <name>         give a column a custom name (an "alias")
--   COUNT(*)          count rows; * means "every row"
--   GROUP BY ...      collapse rows sharing a value into one summary row
--   IN (a, b, c)      match any value in a list (shorthand for many ORs)
--   LIKE '%text%'     match rows whose text CONTAINS "text" (% = anything)
--   CAST(x AS REAL)   treat x as a decimal (9/10 = 0.9, not 0)
--   ROUND(x, 1)       round x to 1 decimal place
-- ============================================================


-- ============================================================
-- STEP 1: Verify the clean-file fix worked
-- WHY: Before trusting ANY analysis, confirm the column fix by
--      checking one known record against the raw source. If this
--      row is right, the whole table is aligned.
--      Expected: Positive = 252, Negative = 3, Price = 5.24
-- ============================================================
--SELECT (display) the AppID, Name, Positive, Negative, Price columns
--FROM (pull from) the games_raw table
--WHERE (keep only) the row whose AppID is 496350 ("Supipara")
SELECT AppID, Name, Positive, Negative, Price
FROM games_raw
WHERE AppID = 496350;


-- ============================================================
-- STEP 2: View the raw data
-- WHY: Look at real rows before analyzing -- column names, value
--      formats, and quirks (e.g. "Estimated owners" is a range
--      string like "0 - 20000"; Price uses 0.0 for free games).
-- ============================================================
--SELECT ALL columns -- the * means "every column"
--FROM the games_raw table
--LIMIT the output to the first 10 rows
SELECT * FROM games_raw
LIMIT 10;


-- ============================================================
-- STEP 3: Top 10 games by RAW positive review count
-- WHY: A baseline. Sorting by raw Positive count just surfaces
--      the biggest blockbusters -- the OPPOSITE of hidden. It
--      confirms the data is aligned and shows what "mainstream"
--      looks like, so gems can be contrasted against it.
-- ============================================================
--SELECT the Name, Positive, Negative, Price columns
--FROM the games_raw table
--ORDER BY Positive, DESC (highest first)
--LIMIT to the first 10 rows
SELECT Name, Positive, Negative, Price
FROM games_raw
ORDER BY Positive DESC
LIMIT 10;


-- ============================================================
-- STEP 4: Each game's positive review PERCENTAGE (quality)
-- WHY: Raw counts favor popular games; a hidden gem is about how
--      WELL-LOVED a game is, not how many reviewed it. Percentage
--      measures quality independent of size. The 500-review floor
--      removes tiny-sample noise; the tiebreaker (Positive DESC)
--      ranks more-reviewed games above equally-rated smaller ones.
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


-- ============================================================
-- STEP 5: Threshold tuning -- count how many games qualify
-- WHY: Before trusting a list, check HOW MANY rows it returns. A
--      gems list should be browsable. We raise the bars in steps
--      and record each count, then pick the combination that
--      gives a credible size. (Each stricter test must return
--      FEWER games -- a built-in sanity check.)
-- RESULTS:  85% / 500 rev / <=$20 ....... 5,175  (too many)
--           90% / 1,000 rev / <=$20 ..... 2,494
--           95% / 2,000 rev / <=$20 ....... 728
--           95% / 5,000 rev / <=$15 ....... 429
--           + low-ownership filter ........ 175  (final, Step 6b)
-- ============================================================
--SELECT a COUNT of all matching rows -- COUNT(*) counts every row
--   AS qualifying_games = name the result
--FROM the games_raw table
--WHERE at least 500 reviews AND 85%+ positive AND Price <= 20
SELECT COUNT(*) AS qualifying_games
FROM games_raw
WHERE (Positive + Negative) >= 500
  AND CAST(Positive AS REAL) / (Positive + Negative) * 100 >= 85
  AND Price <= 20;


-- ============================================================
-- STEP 6: What ownership tiers exist? (explore before filtering)
-- WHY: "Hidden" means relatively few owners, but "Estimated
--      owners" is a RANGE STRING, not a number. First we list the
--      distinct tiers and how many games are in each, to decide
--      which count as "not yet mainstream" (and to spot the
--      "0 - 0" = missing-data tier we must exclude).
-- ============================================================
--SELECT the distinct "Estimated owners" values and a COUNT per tier
--   GROUP BY = collapse rows sharing an "Estimated owners" value
--              into ONE summary row, so COUNT is counted per tier
--FROM the games_raw table
--ORDER BY the count, DESC (most common tiers first)
SELECT "Estimated owners", COUNT(*) AS games_in_tier
FROM games_raw
GROUP BY "Estimated owners"
ORDER BY COUNT(*) DESC;


-- ============================================================
-- STEP 6b: HIDDEN GEMS -- the finished list (paid + free, <=$20)
-- WHY: The final answer. 175 games clear all four criteria
--      (see Step 5). We rank by approval %, break ties by review
--      count, and show the top 25 as the showcase.
--   Criteria: 2,000+ reviews, 95%+ positive, Price <= $20,
--             low ownership tier (under ~200k, excluding "0 - 0").
--   NOTE: "Portal 2" can appear here as a stale record (153k
--         reviews in a "0 - 20000" tier -- impossible). See the
--         VALIDATION section; it is a documented data artifact.
--   To restrict to English-supporting games, un-comment the
--   LIKE line below (see SCOPE & LIMITATIONS).
-- ============================================================
--SELECT Name, Price, "Estimated owners", and the calculated pct_positive
--FROM the games_raw table
--WHERE at least 2,000 reviews AND 95%+ positive AND Price <= 20
--   AND "Estimated owners" is one of the low tiers -- IN (list)
--       matches any value in the list (shorthand for many ORs)
--ORDER BY pct_positive DESC, then Positive DESC (tiebreaker)
--LIMIT the top 25 rows
SELECT Name,
       Price,
       "Estimated owners",
       ROUND(CAST(Positive AS REAL) / (Positive + Negative) * 100, 1) AS pct_positive
FROM games_raw
WHERE (Positive + Negative) >= 2000
  AND CAST(Positive AS REAL) / (Positive + Negative) * 100 >= 95
  AND Price <= 20
  AND "Estimated owners" IN (
        '0 - 20000',
        '20000 - 50000',
        '50000 - 100000',
        '100000 - 200000'
      )
  -- AND "Supported languages" LIKE '%English%'   -- un-comment for English-only
ORDER BY pct_positive DESC, Positive DESC
LIMIT 25;


-- ============================================================
-- STEP 6c: HIDDEN GEMS -- FREE games only (13 games)
-- WHY: Same criteria, filtered to free-to-play (Price = 0) --
--      the most reachable gems of all. Fewer results is expected:
--      "free" tends to drive ownership UP, so truly hidden free
--      gems are rare.
--   VALIDATION NOTE: one result, "Batman: Arkham City", is a
--   stale/delisted entry incorrectly priced at 0 -- documented,
--   not a real free game.
--   To restrict to English-supporting games, un-comment the
--   LIKE line below.
-- ============================================================
--SELECT Name, Price, "Estimated owners", and the calculated pct_positive
--FROM the games_raw table
--WHERE at least 2,000 reviews AND 95%+ positive AND Price = 0 (free)
--   AND "Estimated owners" is one of the low tiers (IN a list)
--ORDER BY pct_positive DESC, then Positive DESC (tiebreaker)
--LIMIT the top 25 rows
SELECT Name,
       Price,
       "Estimated owners",
       ROUND(CAST(Positive AS REAL) / (Positive + Negative) * 100, 1) AS pct_positive
FROM games_raw
WHERE (Positive + Negative) >= 2000
  AND CAST(Positive AS REAL) / (Positive + Negative) * 100 >= 95
  AND Price = 0
  AND "Estimated owners" IN (
        '0 - 20000',
        '20000 - 50000',
        '50000 - 100000',
        '100000 - 200000'
      )
  -- AND "Supported languages" LIKE '%English%'   -- un-comment for English-only
ORDER BY pct_positive DESC, Positive DESC
LIMIT 25;

-- ############################################################
-- #  STEAM HIDDEN GEMS -- PART 2: JOINS                       #
-- #  "Which hidden gems do players actually keep PLAYING?"    #
-- #  Data 1: Kaggle "Steam Games Dataset" (fronkongames)      #
-- #  Data 2: Kaggle "Game Recommendations on Steam"           #
-- #          (antonkozyriev) -- player reviews + hours played #
-- #  Tools: SQLite + DB Browser for SQLite                    #
-- ############################################################

-- ============================================================
-- ABOUT THIS FILE (read me first)
-- Part 1 (hidden_gems.sql) answered "which games ARE hidden
-- gems?" using ONE table. That list ranks games on rating,
-- price, and ownership -- but it can't say whether people
-- actually STICK with those games, because a review COUNT and a
-- review PERCENTAGE don't tell you how many HOURS anyone played.
--
-- That information lives in a DIFFERENT dataset, in a DIFFERENT
-- table. A JOIN is how you pull two tables together on a shared
-- key so you can ask a question neither table can answer alone.
--
-- Like Part 1, every query has:
--   WHY  -- the reason the question is being asked
--   a plain-English "read out loud" of what the SQL does
-- The reasoning matters as much as the final query.
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
-- THE SETUP: adding a SECOND table to the same database
--
-- A JOIN needs two tables living in ONE database file. So far the
-- database has one table, "games_raw". We add a second.
--
-- STEPS (in DB Browser for SQLite):
--   1. Download "Game Recommendations on Steam" from Kaggle
--      (antonkozyriev). We only need recommendations.csv.
--      NOTE: Kaggle hands you a .zip (e.g. "archive.zip") that
--      also contains games.csv, users.csv, and a metadata JSON we
--      do NOT need. Right-click the zip -> Extract, then use ONLY
--      recommendations.csv. Heads-up: it is ~2 GB (~41M rows), so
--      the import takes a while and the .db grows to several GB --
--      the INDEX step below is what keeps queries fast.
--   2. Open your EXISTING hidden-gems .db file (the one that
--      already contains games_raw). Do NOT make a new database --
--      both tables must share one file to be JOIN-able.
--   3. File -> Import -> "Table from CSV file..." -> pick
--      recommendations.csv. Name the new table:  recommendations
--      Tick "Column names in first line". Import.
--   4. Write Changes (Ctrl+S) so the import is saved.
--
-- WHAT THE NEW TABLE HOLDS (one row per PLAYER REVIEW):
--   app_id          the game being reviewed  (this is the KEY)
--   is_recommended  did that player thumbs-up the game? (true/false)
--   hours           how many hours that player has played it
--   helpful, funny  how many others found the review helpful/funny
--   user_id         who wrote it   review_id  the review's own id
--
-- THE KEY THAT LINKS THEM:
--   games_raw.AppID  ==  recommendations.app_id
--   Both are the same Steam "AppID" number, just named slightly
--   differently in each source. That shared number is the hinge
--   every JOIN below swings on.
-- ============================================================

-- ============================================================
-- CONFIRMED SO FAR (facts we verified before writing queries)
--   * The recommendations columns are REAL, not assumed -- we read
--     the file header directly. Exact columns, in order:
--       app_id, helpful, funny, date, is_recommended, hours,
--       user_id, review_id
--   * is_recommended is stored as the lowercase TEXT 'true'/'false'
--     -- NOT the numbers 1/0. Every query that counts recommends
--     tests = 'true' for exactly this reason (see Step 4 / limits).
--   * Snapshot date: the review rows are dated ~August 2024. The
--     games_raw source is a DIFFERENT snapshot, so the two describe
--     the same games at different moments -- stated in LIMITATIONS.
--   * Size: recommendations is ~2 GB / ~41M rows. That is WHY the
--     index below exists and why the first join can feel slow.
-- ============================================================

-- ============================================================
-- CHOOSING SIGNALS: what we USE and what we CUT (and why)
--
-- Part 1 taught "filtering the noise" for ROWS. The same discipline
-- applies to COLUMNS: a table hands you several columns, but not all
-- of them are trustworthy signals. Deciding which to lean on -- and
-- being able to DEFEND cutting the rest -- is the analytical work.
--
-- The recommendations table gives us these signals per review:
--
--   USE:
--     hours          -- how long the player played. Direct evidence
--                       of engagement; the core of "do people keep
--                       PLAYING it?". This is our headline signal.
--     is_recommended -- the player's thumbs up/down. A clean quality
--                       vote, and every review has one.
--
--   CUT (documented below, not silently dropped):
--     helpful, funny -- votes OTHER users cast on the review itself.
--                       We CUT these as analysis signals. Here is
--                       how we saw it and why the cut is defensible.
--
-- HOW WE SAW IT: the first 10 rows showed helpful/funny almost all
--   0. A peek is not proof, so we did NOT trust the eyeball -- we
--   asked the WHOLE 41M-row table one aggregate question instead
--   (see STEP 1b). It measured:
--     * only ~21% of reviews have ANY helpful vote (so ~79% are 0)
--     * average helpful = ~3.2, but MAX = 36,212
--
-- WHY THE CUT IS DEFENSIBLE:
--   1. SPARSE -- ~79% of rows are 0, so the column is mostly empty.
--   2. SKEWED -- a few viral reviews (36k votes) drag the average
--      far above the typical review (0). An average over data this
--      lopsided describes almost none of the actual reviews.
--   3. WRONG SUBJECT -- helpful/funny measure how good the REVIEW
--      TEXT is, not how good the GAME is. They are a signal about
--      writing, not about the product we are ranking.
--   Any one of these is a reason to be cautious; together they make
--   helpful/funny unfit as a quality signal for THIS question.
--
-- THE LESSON (same as Part 1): every column you leave OUT is a
--   decision. Look, measure instead of guess, then state the cut
--   and the reason -- so no one wonders whether you just missed it.
-- ============================================================

-- ============================================================
-- PERFORMANCE NOTE (why the first query might feel slow)
--
-- games_raw has ~125k rows -- small. recommendations has MILLIONS
-- of rows (one per review). Joining millions of rows is real work.
-- To make every JOIN below fast, we build an INDEX on the key
-- column first -- a lookup shortcut so SQLite can find all reviews
-- for a game instantly instead of scanning the whole table.
--
-- Run this ONCE, then Write Changes. It may take a minute; after
-- that, every join query is quick.
-- ============================================================
--CREATE an INDEX named idx_rec_appid
--ON the recommendations table, over its app_id column
CREATE INDEX IF NOT EXISTS idx_rec_appid ON recommendations(app_id);


-- ============================================================
-- HOW A JOIN THINKS (the mental model)
--
-- Picture two sheets on a table. games_raw has one row per GAME.
-- recommendations has many rows per game (one per review). A JOIN
-- lines them up by matching AppID to app_id, so each game row is
-- paired with its review rows.
--
--   INNER JOIN  -- keep ONLY rows that match in BOTH tables.
--                  A game with no reviews in the second table
--                  simply DISAPPEARS from the result.
--
--   LEFT JOIN   -- keep EVERY row from the LEFT (first) table,
--                  matched or not. Where the right table has no
--                  match, its columns come back empty (NULL).
--                  This is how you FIND WHAT'S MISSING.
--
-- Rule of thumb: use INNER when you only care about pairs that
-- exist; use LEFT when "no match" is itself an answer you want.
-- ============================================================

-- ============================================================
-- NEW SQL KEYWORDS USED IN THIS FILE (quick reference)
--   JOIN / INNER JOIN   pair rows from two tables that match
--   LEFT JOIN           keep all left-table rows; NULL where none match
--   ON <a> = <b>        the matching condition (which columns line up)
--   <table> AS <alias>  short nickname for a table (e.g. g, r) so
--                       you can write g.Name instead of games_raw.Name
--   g.column            "dot" notation -- which table a column is from
--   COUNT(r.review_id)  count matched rows PER GROUP (per game here)
--   AVG(x)              average of x across the group
--   SUM(<condition>)    add up a true/false test -> counts the TRUEs
--   GROUP BY g.AppID    collapse all a game's review rows into one summary
--   HAVING <cond>       like WHERE, but filters GROUPS after aggregating
--   IS NULL             true when a value is empty (no match was found)
--   CREATE VIEW         save a query as a reusable virtual table
-- ============================================================


-- ============================================================
-- STEP 1: Peek at the new table
-- WHY: Before joining anything, look at real rows first. Confirm
--      the column names we will rely on (app_id, is_recommended,
--      hours) and see HOW is_recommended is stored -- in this
--      dataset it is the text 'true'/'false', not 1/0, which
--      decides how we filter on it later.
-- ============================================================
--SELECT every column (* means "all columns")
--FROM the recommendations table
--LIMIT the output to the first 10 rows (just a peek, not a sample)
SELECT * FROM recommendations
LIMIT 10;


-- ============================================================
-- STEP 1b: Measure the sparse columns instead of eyeballing them
-- WHY: The peek in STEP 1 showed helpful/funny almost all 0. But a
--      peek only shows the TOP of the file, not a fair sample -- on
--      41M rows you judge a column by asking the WHOLE table one
--      aggregate question, not by scrolling more rows. This measures
--      how empty and how skewed "helpful" really is, so the choice
--      to CUT it (see "CHOOSING SIGNALS" above) rests on evidence.
-- RESULTS (our run):  ~21.12% of reviews have any helpful vote,
--                     average helpful = 3.2, MAX helpful = 36,212.
--                     -> mostly 0, with a few viral outliers = a
--                        sparse, skewed column we do not rank on.
-- ============================================================
--SELECT three CALCULATED whole-table numbers:
--   pct_with_any_helpful = what % of reviews have helpful > 0
--     CASE WHEN helpful > 0 THEN 1 ELSE 0 END = write 1 if the row
--        has any votes, else 0 (a yes/no turned into a number)
--     SUM(...)   = add those 1s up = how many rows had votes
--     COUNT(*)   = count every row (* means "every row")
--     SUM / COUNT * 100.0 = share of rows with votes, as a percent
--        (the .0 forces decimal math, not whole-number division)
--     ROUND(..., 2) = round to 2 decimal places
--     AS pct_with_any_helpful = name (alias) the column
--   max_helpful = MAX(helpful) = the biggest single value (tail top)
--   avg_helpful = ROUND(AVG(helpful), 2) = the average, to 2 decimals
--FROM the recommendations table (no LIMIT -- we want ALL rows)
SELECT
  ROUND(100.0 * SUM(CASE WHEN helpful > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_with_any_helpful,
  MAX(helpful) AS max_helpful,
  ROUND(AVG(helpful), 2) AS avg_helpful
FROM recommendations;


-- ============================================================
-- STEP 2: Do the two tables actually share keys? (sanity check)
-- WHY: A JOIN is worthless if the keys don't match. Before
--      trusting any join, confirm that AppIDs in games_raw really
--      appear as app_ids in recommendations. We count how many
--      games have at least one matching review. If this comes back
--      0, the key columns don't line up and nothing else is valid.
-- ============================================================
--SELECT a COUNT of DISTINCT games that have a match
--FROM games_raw (nicknamed g)
--INNER JOIN recommendations (nicknamed r) where g.AppID = r.app_id
SELECT COUNT(DISTINCT g.AppID) AS games_with_reviews
FROM games_raw AS g
JOIN recommendations AS r ON g.AppID = r.app_id;


-- ============================================================
-- STEP 3: INNER JOIN, up close -- one game and its reviews
-- WHY: See the join in its simplest form before aggregating.
--      Pick ONE known gem and list its individual player reviews
--      (hours + thumbs-up). One game row on the left is paired
--      with MANY review rows on the right -- that's one-to-many.
--      (Swap the AppID for any game you want to inspect.)
-- ============================================================
--SELECT the game's Name, and each review's hours + is_recommended
--FROM games_raw g  JOIN recommendations r  ON g.AppID = r.app_id
--WHERE the game is AppID 1562430 ("Patrick's Parabox", a top-25 gem)
--ORDER BY hours DESC   LIMIT 20 reviews
SELECT g.Name, r.hours, r.is_recommended
FROM games_raw AS g
JOIN recommendations AS r ON g.AppID = r.app_id
WHERE g.AppID = 1562430
ORDER BY r.hours DESC
LIMIT 20;


-- ============================================================
-- STEP 4: Aggregate the reviews -- one summary row per game
-- WHY: Individual reviews are noise; we want a per-GAME summary.
--      GROUP BY collapses all of a game's review rows into one
--      row so we can compute, per game: how many reviews, the
--      average hours played, and the % that recommended it.
--      This is the core "join + group" pattern.
-- ============================================================
--SELECT the game Name, plus THREE calculated per-game numbers:
--   COUNT(r.review_id)                        = number of reviews
--   ROUND(AVG(r.hours),1)                     = average hours played
--   % recommended = 100 * (recommended reviews / all reviews)
--      SUM(r.is_recommended = 'true') counts the TRUE rows
--      CAST(... AS REAL) keeps the division a decimal
--FROM games_raw g  JOIN recommendations r  ON g.AppID = r.app_id
--GROUP BY g.AppID (one output row per game)
--ORDER BY avg hours, DESC   LIMIT 20
SELECT g.Name,
       COUNT(r.review_id) AS num_reviews,
       ROUND(AVG(r.hours), 1) AS avg_hours,
       ROUND(100.0 * SUM(CASE WHEN r.is_recommended = 'true' THEN 1 ELSE 0 END)
             / CAST(COUNT(r.review_id) AS REAL), 1) AS pct_recommended
FROM games_raw AS g
JOIN recommendations AS r ON g.AppID = r.app_id
GROUP BY g.AppID, g.Name
ORDER BY avg_hours DESC
LIMIT 20;


-- ============================================================
-- STEP 5: Save the Part-1 hidden gems as a reusable VIEW
-- WHY: The join queries below only care about our 175 hidden gems,
--      not all 125k games. Rather than paste the long gem-defining
--      WHERE clause into every query, we save it ONCE as a VIEW --
--      a named, virtual table we can SELECT from like any other.
--      (This is the exact criteria from Part 1, Step 6b.)
-- ============================================================
--CREATE a VIEW named hidden_gems that IS the Part-1 gem query
--   (2,000+ reviews, 95%+ positive, Price <= 20, low ownership)
CREATE VIEW IF NOT EXISTS hidden_gems AS
SELECT AppID,
       Name,
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
      );


-- ============================================================
-- STEP 6: THE PAYOFF -- hidden gems people actually KEEP PLAYING
-- WHY: This is the whole reason for Part 2. Part 1 found games that
--      are well-RATED and obscure. Now we join those gems to real
--      playtime and keep only the ones with high average hours --
--      "sleeper hits" a devoted audience sinks serious time into.
--      A high rating with high hours is a much stronger signal than
--      a high rating alone.
--   HAVING (not WHERE) because we filter on AVG(hours), which only
--   exists AFTER the rows are grouped. WHERE runs too early for that.
-- ============================================================
--SELECT the gem's Name, Price, its % positive (from the view),
--   its review count and AVG hours (from the joined reviews)
--FROM the hidden_gems view (g)  JOIN recommendations (r) ON AppID
--GROUP BY the game  (one row per gem)
--HAVING at least 50 matched reviews (so the average is trustworthy)
--ORDER BY avg hours DESC   -- the stickiest gems first
SELECT g.Name,
       g.Price,
       g.pct_positive,
       COUNT(r.review_id) AS num_reviews,
       ROUND(AVG(r.hours), 1) AS avg_hours
FROM hidden_gems AS g
JOIN recommendations AS r ON g.AppID = r.app_id
GROUP BY g.AppID, g.Name, g.Price, g.pct_positive
HAVING COUNT(r.review_id) >= 50
ORDER BY avg_hours DESC
LIMIT 25;

-- ------------------------------------------------------------
-- WHAT THIS REVEALED (our run) -- the payoff, read as findings:
--   * POSTER CHILD: Tales of Maj'Eyal -- $3.49, 95.1% positive,
--     2,498 reviews, ~174 avg hours. A cheap, obscure roguelike a
--     devoted crowd sinks weekends into. That single row IS the
--     thesis of Part 2: well-rated + obscure + genuinely sticky.
--   * THE GENRES MAKE SENSE: the list is dominated by VISUAL NOVELS
--     (Umineko, Riddle Joker, Summer Pockets, Muv-Luv, STEINS;GATE 0,
--     NEKOPARA) and DEEP RPGs/ROGUELIKES (Trails in the Sky SC, Bug
--     Fables, Epic Battle Fantasy 4) -- genres built for long
--     playtime, so high avg hours is a real signal, not an artifact.
--   * THE FLOOR WORKED: smallest sample here is ~99 reviews. None of
--     Step 4's 1-review junk ("Angry Cat", 5 reviews) survived,
--     because HAVING COUNT >= 50 removed it.
--   * CONTRAST WITH STEP 4: there, raw avg-hours put Dota 2 / CS2 on
--     top at ~429 hours -- but those are mega-popular, the OPPOSITE
--     of hidden. Filtering to the gems VIEW first is what turns
--     "most-played games" into "most-played SLEEPER games".
-- ------------------------------------------------------------


-- ============================================================
-- STEP 7: LEFT JOIN -- which gems are MISSING from the review data?
-- WHY: The two datasets are separate snapshots, so not every gem
--      will appear in the recommendations table. "Which gems have
--      NO matching reviews?" is a real question -- and the classic
--      job-interview use of a LEFT JOIN: keep every gem, attach
--      reviews where they exist, then keep only the gems where the
--      review side came back EMPTY (NULL). This "anti-join" is how
--      you find what's ABSENT -- something an INNER JOIN can never
--      show you, because it drops the non-matches entirely.
-- ============================================================
--SELECT the gem's Name and pct_positive
--FROM hidden_gems (g)  LEFT JOIN recommendations (r) ON AppID
--   -- LEFT JOIN keeps ALL gems, even those with zero reviews
--WHERE r.app_id IS NULL  -- keep only the gems that found NO match
--ORDER BY pct_positive DESC
SELECT g.Name, g.pct_positive
FROM hidden_gems AS g
LEFT JOIN recommendations AS r ON g.AppID = r.app_id
WHERE r.app_id IS NULL
ORDER BY g.pct_positive DESC;


-- ============================================================
-- STEP 8: The two views, side by side -- rating vs. playtime
-- WHY: A LEFT JOIN + aggregate gives the fullest picture: EVERY
--      gem, with its playtime where we have it and a clear blank
--      where we don't. This is the table you'd hand to a
--      storefront team: "here are our gems, how loved they are,
--      and how much people actually play them." Gems missing from
--      the review data show 0 reviews / NULL hours -- honestly,
--      instead of vanishing.
-- ============================================================
--SELECT gem Name, pct_positive, review count, avg hours
--FROM hidden_gems (g)  LEFT JOIN recommendations (r) ON AppID
--GROUP BY the game
--ORDER BY avg hours DESC (NULLs -- the un-matched gems -- sort last)
SELECT g.Name,
       g.pct_positive,
       COUNT(r.review_id) AS num_reviews,
       ROUND(AVG(r.hours), 1) AS avg_hours
FROM hidden_gems AS g
LEFT JOIN recommendations AS r ON g.AppID = r.app_id
GROUP BY g.AppID, g.Name, g.pct_positive
ORDER BY avg_hours DESC;


-- ============================================================
-- VALIDATION & LIMITATIONS (staying honest, like Part 1)
--
--   A. TWO DATASETS, TWO SNAPSHOTS -- games_raw and
--      recommendations were collected by different people at
--      different times. Some gems won't appear in the reviews at
--      all (that's Step 7), and hours/recommend rates reflect the
--      review dataset's date, not games_raw's. State this; don't
--      imply the two were measured together.
--
--   B. PARTIAL OVERLAP IS EXPECTED -- Step 2 tells you how many
--      gems actually matched. If it's a small fraction, say so;
--      the playtime story only covers the matched gems.
--
--   C. PLAYTIME IS SKEWED -- a few 900-hour super-fans drag AVG
--      up. AVG(hours) is a starting signal, not proof. A median
--      would be sturdier (SQLite has no built-in median -- a noted
--      limitation, not something to fake).
--
--   D. is_recommended IS TEXT -- it's the string 'true'/'false'
--      here, not 1/0. Filtering r.is_recommended = 1 would silently
--      match nothing. Always check how a boolean is actually stored
--      (Step 1) before you trust a count built on it.
--
--   E. THE 50-REVIEW FLOOR (Step 6) is the same small-sample logic
--      as Part 1's review floor: an average over 3 reviews is not a
--      trustworthy number. Set from judgment, stated openly.
--
--   F. HOURS IS CAPPED AT 1000 -- we spotted it in STEP 3: The
--      Witcher 3's top rows marched 999.9, 999.8, 999.7... and
--      MAX(hours) across the whole table is exactly 1000.0. So any
--      player past ~1000 hours is pinned to the ceiling, which pulls
--      AVG(hours) DOWN for very "sticky" games. We MEASURED the
--      blast radius before worrying: only ~3,024 rows (0.01%) sit at
--      the cap, and it bites hardest on blockbusters with swarms of
--      mega-players -- NOT on our low-ownership gems, which rarely
--      have them. So we note it and move on. (Lesson: notice the
--      oddity, measure it, size the concern -- don't panic OR ignore.)
--
--   PRINCIPLE (unchanged from Part 1): a join makes it easy to
--   combine data that was never meant to be combined. That power is
--   exactly why you must state where the two sources came from and
--   where they don't line up.
-- ============================================================

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
-- WHY: Before joining anything, look at real rows -- confirm the
--      column names (app_id, is_recommended, hours) and see how
--      is_recommended is stored (the text 'true'/'false', not 1/0,
--      in this dataset -- worth knowing before we filter on it).
-- ============================================================
--SELECT ALL columns  FROM the recommendations table  first 10 rows
SELECT * FROM recommendations
LIMIT 10;


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
--   PRINCIPLE (unchanged from Part 1): a join makes it easy to
--   combine data that was never meant to be combined. That power is
--   exactly why you must state where the two sources came from and
--   where they don't line up.
-- ============================================================

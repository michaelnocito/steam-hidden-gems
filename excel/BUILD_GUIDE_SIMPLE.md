# Steam Hidden Gems -> Excel (beginner-friendly build)

You'll recreate the dashboard in `dashboard_preview.html` inside Excel.
Everything is explained as we go. Do it top to bottom, one small step at a time.

**What you need:** Excel for Windows (Microsoft 365 or Excel 2019+).

**Your data file (copy this exact path):**
`C:\Users\Mike\Projects\apk-portfolio-hidden-gems\excel\steam_hidden_gems.csv`

There is also a ready-made workbook with the same data already loaded as a table:
`C:\Users\Mike\Projects\apk-portfolio-hidden-gems\excel\steam_hidden_gems.xlsx`
You can start from that and skip Step 1 if Power Query gives you trouble, but do
try Power Query first. Loading data with it is a real skill employers look for.

One row = one game.

---

## The question this dashboard answers

Not "which games are cheap and good." That's a list, not an analysis.

The question is: **765 games on Steam are genuinely loved (95%+ positive with 2,000+
reviews). Only 175 of them stayed small. Why do some loved games get found and
others don't?**

The answer, which the hero chart shows: the hidden ones aren't cheaper, shorter, or
worse reviewed. They're the same product with one fifth the audience. Keep that
sentence in mind while you build, because every chart is there to support it.

---

## First, the words you'll see (30-second glossary)

- **Table** = a range Excel treats as one named unit. Formulas can say `Games[Price]` instead of `D2:D82957`.
- **Power Query** = Excel's built-in import tool. It connects to a file, lets you clean the data, then loads it. The connection is refreshable, which a plain copy-paste is not.
- **PivotTable** = a drag-and-drop summary of a table (count of gems by genre, for example). No formulas needed.
- **PivotChart** = a chart drawn straight from a PivotTable. It updates when the pivot updates.
- **Calculated field** = a formula you add *inside* a PivotTable, so the pivot can show something the raw data doesn't have (like a rate).
- **Slicer** = a strip of clickable filter buttons wired to a PivotTable. Click "Adventure" and everything connected to it filters.
- **Named range** = a name you give one cell (like `GemCount`) so formulas and titles can refer to it readably.
- **Array formula** = a formula that works across a whole column at once. `MEDIAN(IF(...))` is one. On older Excel you finish it with Ctrl+Shift+Enter instead of Enter.

That's the whole vocabulary. You'll use each one once below.

---

## Step 1 - Load the data with Power Query

1. Open a blank workbook.
2. Ribbon: **Data > Get Data > From Text/CSV**.
3. In the file box paste the full path:
   `C:\Users\Mike\Projects\apk-portfolio-hidden-gems\excel\steam_hidden_gems.csv`
4. In the preview window click **Transform Data** (not Load). This opens the Power Query editor.
5. Check the column types in the header row: `Price` and `PctPositive` should show a decimal icon (1.2), `TotalReviews` and `IsHiddenGem` a whole-number icon (123), `Name` and `PrimaryGenre` a text icon (ABC). If one is wrong, click its icon and pick the right type.
6. Ribbon (still in Power Query): **Home > Close & Load**. Excel loads all 82,956 rows as a green-striped table on a new sheet.
7. Click anywhere in the table, then ribbon **Table Design**: change the table name (far left box) to `Games`. Rename the sheet tab to `data`.

*Why bother with Power Query? If the CSV ever changes, Data > Refresh All re-imports it. That refreshable connection is the difference between "pasted some data" and "built a small pipeline."*

---

## Step 2 - Your columns, in everyday terms

You don't need to build these; they're already in the file:

| Column | What it is |
|---|---|
| Name | the game |
| PrimaryGenre | its main genre (Adventure, Action...) |
| PriceBand | price bucket ($0-5, $5-10, $10-20, Free) |
| Price | price in dollars |
| TotalReviews | how many reviews it has |
| PctPositive | % of reviews that are positive |
| MedianPlaytimeHrs | typical hours played |
| EstOwnersMid | rough number of owners |
| IsHiddenGem | 1 = it's a hidden gem, 0 = it isn't |

**Hidden gem** already means: 2,000+ reviews, 95%+ positive, price <= $20, under ~200k owners.

---

## Step 3 - Add one helper column

You need a flag for "this game has enough reviews to be taken seriously." You'll use
it in Step 6 to turn counts into rates.

1. On the `data` sheet, click the first empty cell to the right of the last header. Type `IsProven` and press Enter. Excel extends the table automatically.
2. In the first cell under it, type: `=IF([@TotalReviews]>=2000,1,0)`
3. Press Enter. Excel fills the whole column down by itself, because it's a table.

That's 4,892 proven games out of 82,956. Everything else has too few reviews for its
rating to mean much. (Sanity-check yours with
`=SUM(Games[IsProven])` in a spare cell.)

---

## Step 4 - The dashboard sheet and the KPI row

1. New sheet, rename it `dashboard`.
2. Ribbon: **View** > untick **Gridlines**. (A dashboard on a plain white canvas instantly looks intentional.)
3. In four cells across the top (say B2, D2, F2, H2) enter these formulas. Type them, don't type the answers:
   - Games with reviews: `=COUNT(Games[AppID])`
   - Genuinely loved games: `=COUNTIFS(Games[PctPositive],">=95",Games[TotalReviews],">=2000")`
   - Stayed hidden: `=COUNTIFS(Games[PctPositive],">=95",Games[TotalReviews],">=2000",Games[IsHiddenGem],1)`
   - Audience gap: leave this one for Step 5, it needs the medians first.
4. Under each number put a small grey label (B3: `Games with reviews`, etc.).
5. Expected values: **82,956 / 765 / 175**. If yours match, the data loaded correctly.
6. Make the gem count reusable: select the cell with the 175, click the **Name Box** (left of the formula bar), type `GemCount`, press Enter. That's your named range.

---

## Step 5 - The hero chart: the discovery gap

This is the chart that makes the whole dashboard worth looking at. It compares the
175 loved-but-hidden games against the 590 loved games that broke out, and shows
they're the same games with wildly different audiences.

**5a. Build the comparison table.** On a new sheet called `helper`, lay out this
block. Every number is a formula. The pattern never changes, so you'll write it once
and adapt it five times.

|   | A | B (Hidden) | C (Broke out) |
|---|---|---|---|
| 1 | Measure | Hidden | Broke out |
| 2 | Median owners | formula | formula |
| 3 | Median % positive | formula | formula |
| 4 | Median price | formula | formula |
| 5 | Median playtime | formula | formula |

For B2 (median owners, hidden) type:

```
=MEDIAN(IF((Games[PctPositive]>=95)*(Games[TotalReviews]>=2000)*(Games[IsHiddenGem]=1),Games[EstOwnersMid]))
```

Press Enter. If you get an error or a strange number, press F2 then **Ctrl+Shift+Enter**
instead. Older Excel needs that to run an array formula.

*How to read it: each condition in brackets returns TRUE or FALSE. Multiplying them
together gives 1 only where all three are true. `IF` then hands `MEDIAN` just those
rows. It's an AND filter written as multiplication.*

For C2, copy B2 and change the last condition to `=0`.
For rows 3, 4 and 5, copy the pair across and swap `Games[EstOwnersMid]` for
`Games[PctPositive]`, `Games[Price]`, then `Games[MedianPlaytimeHrs]`.

**Check your numbers before you chart anything:**

| Measure | Hidden | Broke out |
|---|---|---|
| Median owners | 150,000 | 750,000 |
| Median % positive | 97.0 | 96.5 |
| Median price | $5.99 | $4.99 |
| Median playtime (hrs) | 4.9 | 5.1 |

If those match, you've proven the finding yourself rather than taking my word for it.

**5b. Finish the KPI row.** Back on `dashboard`, the fourth KPI is the gap:
`=helper!C2/helper!B2` formatted to one decimal with an `x` after it. It reads **5.0x**.

**5c. Chart it.** Select just the two median-owners numbers with their labels
(`Hidden` and `Broke out`), then **Insert > Charts > Bar > Clustered Bar**.
- Make the Hidden bar orange, the Broke out bar blue.
- Right-click a bar > **Add Data Labels**, format them with a thousands separator.
- Delete the legend and the vertical gridlines. Title it `The discovery gap`.
- Under the chart, paste the small comparison table from 5a (rows 3-5) so the
  "matched on everything else" point is visible right next to the gap.

**5d. Write the takeaway on the dashboard.** Add a text box:
*Games that stayed hidden aren't cheaper, shorter, or worse reviewed than the ones
that broke out. They're the same product with one fifth the audience.*

A chart with the conclusion written next to it is the single biggest difference
between a student dashboard and a professional one.

---

## Step 6 - Which genres actually produce gems (a rate, not a count)

Here's the trap this chart avoids. Counted raw, Adventure has 75 gems and Action has
51, so Action looks like a strong second. But Steam has 35,149 Action games and only
17,486 Adventure ones. The count is mostly measuring how big each genre is.

Divide by the number of proven games in each genre and Action falls from second to
fifth. That division is the entire point of the chart, and it's the clearest signal
in this workbook that you thought about the denominator.

1. Click inside the `Games` table > **Insert > PivotTable** > place it on the `helper` sheet. (Pivots stay off the dashboard; only their charts go there.)
2. Drag **PrimaryGenre** to Rows. Drag **IsProven** to Values, and **IsHiddenGem** to Values. Both should read *Sum of*, which counts the 1s.
3. Now the calculated field. With the pivot selected: **PivotTable Analyze > Fields, Items & Sets > Calculated Field**.
   - Name: `GemRate`
   - Formula: `= IsHiddenGem / IsProven`
   - Click Add, then OK. A third column appears. Format it as a percentage with one decimal.
4. Drop the noisy rows. A genre with 8 proven games can show a wild rate off almost no data. Click the Rows dropdown > **Value Filters > Greater Than**, pick *Sum of IsProven*, enter **100**. Seven genres survive.
5. Sort by GemRate, largest to smallest: right-click any rate > **Sort > Largest to Smallest**.
6. Click in the pivot > **PivotTable Analyze > PivotChart** > **Bar** (horizontal). Delete the legend and the field buttons. Move it to `dashboard`, bottom left.
7. Title it `Which genres actually produce gems`, and add a subtitle text box: *Share of proven games (2,000+ reviews) that stayed hidden gems.*

**Check your numbers:**

| Genre | Rate | Gems / proven |
|---|---|---|
| Adventure | 8.1% | 75 of 924 |
| Casual | 7.2% | 26 of 363 |
| Indie | 3.8% | 14 of 366 |
| RPG | 2.2% | 4 of 180 |
| Action | 2.0% | 51 of 2,564 |
| Simulation | 1.0% | 2 of 194 |
| Strategy | 0.8% | 1 of 122 |

Add a text note next to the chart: *Counted raw, Action looks like the second-best
genre with 51 gems. As a rate it drops to fifth. Action is simply the biggest
category on Steam, not the one most likely to hide something good.*

---

## Step 7 - Gems by price, plus the slicers

1. Second PivotTable on `helper`: **PriceBand** to Rows, **IsHiddenGem** to Values (Sum of).
2. **Leave this one in price order** (Free, $0-5, $5-10, $10-20). Don't sort by value. Price bands have a natural sequence, and scrambling them to make a tidy descending staircase makes the chart harder to read, not easier. Knowing when *not* to sort is worth as much as knowing how to.
3. PivotChart it as a bar, move to `dashboard`, bottom right. Expected: 13 / 68 / 52 / 42.
4. Click inside either PivotTable > **PivotTable Analyze > Insert Slicer** > tick **PrimaryGenre** and **PriceBand** > OK.
5. Wire each slicer to BOTH pivots: right-click the slicer > **Report Connections** > tick both PivotTables.
6. Move the slicers to the top of `dashboard`, under the KPI row. Clicking "Adventure" now filters both charts at once.

---

## Step 8 - The Top Gems table

1. On `helper`, build a small block of the top 8 gems by PctPositive. Use formulas so the lookup skill is visible:
   - Type ranks 1 through 8 down a column (say A20:A27).
   - Next to rank 1: `=LARGE(IF(Games[IsHiddenGem]=1,Games[PctPositive]),A20)` and fill down. Ctrl+Shift+Enter if your Excel asks.
   - Pull the name: `=INDEX(Games[Name],MATCH(1,(Games[PctPositive]=B20)*(Games[IsHiddenGem]=1),0))`
   - Pull Reviews and Price the same way, swapping `Games[Name]` for `Games[TotalReviews]` and `Games[Price]`.
2. Copy the finished 8-row block onto `dashboard`, right side.
3. Select the % Positive column of that block > **Home > Conditional Formatting > Data Bars** > a solid orange bar.
4. Expected top game: **A Castle Full of Cats, 99.4% positive, 4,009 reviews, $2.39.**

---

## Step 9 - One screen, final polish

1. A dynamic title in B1: `="Steam Hidden Gems - "&TEXT(GemCount,"#,##0")&" great games nobody found"`. Make it 16-18pt bold. It updates itself when the data refreshes.
2. Under it, a smaller subtitle text box stating the question: *765 games on Steam are genuinely loved. Only 175 stayed small. Why do some get found and others don't?*
3. Arrange everything to fit one screen at 100% zoom: title, KPI row, slicers, discovery gap chart left, Top Gems right, genre rate and price charts along the bottom. Match `dashboard_preview.html`.
4. Consistent colors throughout: hidden gems orange, everything else blue or grey. Same font sizes on both bar charts.
5. Add a small text box with the definition: *Hidden gem = 2,000+ reviews, 95%+ positive, price <= $20, under ~200k owners.*
6. Save as `steam_hidden_gems_dashboard.xlsx` in the same folder (keep the data-only workbook untouched as your clean starting point).

---

## Quick self-check before you call it done

- [ ] Data loaded through Power Query (Data > Queries & Connections shows the query)
- [ ] KPI cells are formulas, not typed numbers (click one; the formula bar should show COUNT or COUNTIFS, not a number)
- [ ] KPIs read 82,956 / 765 / 175 / 5.0x
- [ ] Discovery gap chart shows 150,000 vs 750,000, with the matched comparison beside it
- [ ] The takeaway sentence is written on the dashboard, not just in your head
- [ ] Genre chart shows a **rate**, not a raw count, and Adventure leads at 8.1%
- [ ] The pivot has a calculated field named GemRate
- [ ] Price bands are in price order, not sorted by value
- [ ] Clicking a slicer button filters both bar charts
- [ ] INDEX/MATCH appears in the Top Gems block
- [ ] Data bars on the Top Gems % column
- [ ] Title is a formula (starts with `=`)
- [ ] Gridlines hidden, everything on one screen

If something looks off, open `dashboard_preview.html` next to Excel and compare.

---

## If someone asks you about this in an interview

Two things in here are worth saying out loud, because they're the parts a beginner
usually misses:

**"I turned the genre count into a rate."** Raw counts tracked genre size, not gem
density. Dividing by proven games in each genre reversed the ranking and changed the
conclusion. Denominators matter.

**"I compared the hidden games to a matched group."** Instead of just describing the
175 gems, I compared them against the 590 equally-loved games that broke out. Same
ratings, same prices, same playtime, five times the audience. That comparison is what
turns a list into a finding.

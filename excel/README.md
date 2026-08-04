# Steam Hidden Gems: an Excel dashboard

**Author:** Michael Nocito
**Tools:** Excel (PivotTables, PivotCharts, COUNTIF and AVERAGEIF)
**Data:** 82,956 Steam games

175 games on Steam are rated as highly as the famous ones. They cost the same.
They reach one twenty-first of the players.

This dashboard finds them and shows why the usual explanations do not hold.

![The dashboard: four headline numbers, a chart comparing audience size, a chart of hidden rates by genre, and the top 15 games by rating](images/dashboard.png)

---

## The four numbers

| | |
|---|---|
| Games analysed | 82,956 |
| Genuinely loved | 765 |
| Stayed hidden | 175 |
| Audience gap | 21.2x |

"Genuinely loved" means 2,000 or more reviews and 95% or better positive. The
review count matters. A game with nine reviews and a perfect score tells you
nothing.

Of those 765 loved games, 175 never found an audience. That is 22.9%. Roughly
one in four games that people love stays unknown.

---

## The question

A list of good cheap games is not analysis. Anyone can sort a spreadsheet.

The question worth asking is why some loved games get found and others do not.
There are two possible answers.

The first: hidden games are worse. Cheaper, shorter, lower rated. If that is
true, staying unknown makes sense and there is nothing to explain.

The second: they are the same. If that is true, quality does not explain
anything, and being found is mostly luck.

Four numbers decide it.

---

## What I found

| | Price | Rating | Hours played | Audience |
|---|---|---|---|---|
| Loved and found | $7.67 | 96.6% | 10.8 | 2,458,263 |
| Loved and hidden | $7.11 | 97.0% | 7.9 | 116,000 |

The hidden games cost 56 cents less. They are rated slightly higher. They run
about three quarters as long.

Then the audience column falls off a cliff.

**Same product, one twenty-first of the players.** That is the finding.

---

## The obvious objection

The first thing anyone says to this is that hidden games must be niche genres.

So I checked. Each genre is measured against its own loved games, not against
the other genres.

| Genre | Share that stayed hidden |
|---|---|
| Adventure | 32.2% |
| Casual | 25.5% |
| Indie | 20.3% |
| Action | 16.9% |

Genre matters some. Adventure games hide almost twice the share that action
games do.

It does not explain the finding away. Every genre hides a large chunk of its
own best work. The lowest is action at 16.9%, and that is still one in six.

Eight other genres exist in this data. Each has between 1 and 18 loved games.
I left them out. Below about 20 games a percentage is noise, and I would rather
show four numbers I trust than twelve I do not.

---

## What I threw away

I also cut the data by price band. Games over $20 showed a 0% hidden rate. A
clean result, and a chartable one.

It is worthless.

"Hidden gem" is defined in this data as costing $20 or less. A game over $20
cannot be one. The chart would have been my own filter reflected back at me,
dressed up as a discovery.

The tell was how clean it was. Real findings are messy. 32% against 17% is
messy. 0% against 21% is too tidy to be true, and tidiness is the warning.

So there is no price chart on this dashboard. The check that produced nothing
was still worth running.

---

## What I checked before publishing

**The averages are pulled up by a few huge hits.** Average audience for found
games is 2.46 million, but the middle game sits at 750,000. On middle values
the gap is 5x rather than 21x. Both are real. The 21x is the average gap, and
the 5x is the typical gap. I lead with the average and I say this here so
nobody has to catch me at it.

**The segment counts were checked against the source before anything was
built.** 175 hidden, 590 found, 82,191 outside the loved group. They add to
82,956.

**One column was corrupt and I nearly shipped it.** Excel opened the file
assuming the wrong alphabet, so 4,685 of the 82,956 game names came in as
symbols. Nothing errored. Two of them reached my top 15 list before I noticed.
The names were re-exported with the correct setting and pasted back over the
old column.

---

## Why it looks like this

Every choice on the page was a decision, and most of them could have gone the
other way. Here is what I picked and what I turned down.

### Four numbers across the top, not eight

A number earns a spot only if it changes what you do next. Four fit on one
line and get read. Eight become a wall and get skipped.

I chose total games, loved games, hidden games, and the gap. The first three
build the funnel. The fourth is the finding.

The gap reads `21.2x` rather than `2,458,263 vs 116,000`. A ratio survives
being glanced at. Two seven-digit numbers do not.

It is formatted, not typed. The cell still holds 21.19191993 and can still be
used in a formula. Typing "21.2x" would have turned a number into text.

### The hero chart is two bars

Two averages, side by side. I considered a scatter of every loved game with
audience against rating, which would have been prettier and shown the spread.

I turned it down because the finding is a comparison of two groups. A scatter
makes the reader find the pattern. Two bars hand it over.

**The tall bar is grey and the tiny one is coloured.** That looks backwards
until you ask what the chart is about. The story is not that famous games are
big. It is that the hidden ones are almost nothing next to them. Colour goes
on the subject, not the biggest shape.

The vertical axis is gone and the exact numbers sit on the bars instead. An
axis lets you estimate a value. A label tells you it. Keeping both asks the
reader to do the same job twice.

The legend is gone too, because there is only one series to name.

### The genre chart is percentages, not counts

Action has 302 loved games and Indie has 69. Counted, Action wins everything
and the chart just shows which genres are popular.

As a share of each genre's own loved games, every row asks the same question
of itself. That is the only version that answers whether genre explains
anything.

It is sorted highest to lowest. An unsorted bar chart makes the reader rank
the bars. A sorted one hands them the ranking.

**This chart keeps its legend** while the first one lost its own. Two series
that are not self-explaining need naming. One series does not. The rule is
whether the reader needs it, not consistency for its own sake.

Only four genres appear. Eight more exist, each with between 1 and 18 loved
games. A percentage from 12 games is noise dressed as a finding.

### The table is 15 rows sorted by rating

Fifteen fits beside the charts without scrolling. Twenty would push the page
taller than a screen.

Sorted by rating rather than review count, because the claim is about quality,
not popularity. Sorting by reviews would quietly re-introduce the fame the
whole project is about removing.

Price is in there because it is the objection. Anyone can say these games are
obscure because they are cheap. The column shows they are not.

### The page itself

Gridlines and row and column headings are switched off. A grid says
spreadsheet. Without it the same content reads as a page.

The workings live on a separate sheet. Four PivotTables feed this page and
none of them are on it. An answer sheet with the arithmetic still showing is
harder to trust, not easier.

Charts sit on the left and the list on the right, because the argument comes
before the payoff. You are meant to believe the gap before you get the names.

### What I took off, and why

| Removed | Reason |
|---|---|
| The price band chart | Circular. Gems are defined as under $20, so the result was my own filter |
| The vertical axis on chart one | Data labels do the job exactly rather than approximately |
| The legend on chart one | One series does not need naming |
| Data labels on the grey bars | Labelling the context invites reading the number that does not matter |
| Grand total rows | Averaging averages produces a number that means nothing |
| Field buttons | Editing controls, not part of the picture |
| Gridlines and headings | They say spreadsheet |

The general rule behind all of it: everything on a page competes for the same
attention. Anything not carrying meaning is taking attention from something
that is.

## How it is built

Everything reads from one Excel Table named `Games`, so the numbers update if
the data does.

One added column tags every row as found, hidden, or outside the loved group.
Every chart and count works off that tag.

The four headline numbers are formulas, not typed. The audience gap is one
line: average audience of found games divided by average audience of hidden
ones.

Four PivotTables feed the page. Each chart has its own, so filtering one
cannot silently change another.

---

## Files

| File | What it is |
|---|---|
| `steam_hidden_gems_dashboard.xlsx` | The dashboard |
| `steam_hidden_gems.csv` | The source data, 82,956 rows |
| `BUILD_GUIDE_SIMPLE.md` | Build it yourself, step by step |

The SQL that produced this data is in [`../queries/`](../queries/), and the
full analysis is in the [main README](../README.md).

---

## Build it yourself

`BUILD_GUIDE_SIMPLE.md` walks the whole thing from the raw file to the finished
page. It assumes you have opened Excel before and nothing else.

Download the data, follow it, and change one threshold at the end. Move the 95%
bar to 98% and see which games drop out. Then decide whether you would have
dropped them.

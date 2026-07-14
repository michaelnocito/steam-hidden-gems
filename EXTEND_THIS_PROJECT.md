# Extend This Project (No New Skills Required)

Reading a finished analysis teaches you a little. Changing one and watching
the results move teaches you a lot more — learning science calls it the
generation effect: producing an answer beats reading one. Every idea below
uses only tools already used in this repo (`WHERE`, `LIKE`, `CAST`,
`GROUP BY`, `ORDER BY`, CASE, and the join patterns in
`queries/hidden_gems_joins.sql`). If you followed the walkthrough, you can
do all of it.

The method for each idea: predict what will happen first, run it, compare.
The gap between your prediction and the result is where the learning is.

## Change the definition of a gem

1. **Stricter love.** The gem view requires 95%+ positive reviews. Raise it
   to 98%. How many gems survive? Which ones drop out — and would you have
   dropped them?
2. **Change the fame ceiling.** Gems are capped at 200,000 estimated
   owners. Add the next owner band and rerun. Does the list feel less
   "hidden"? Where would YOU draw the line, and why?
3. **Free gems only.** Filter to `Price = 0`. Free games live and die by
   reviews alone — does the gem signal still work when there's no
   price-vs-quality tradeoff?

## Slice the gems by a column you haven't used yet

4. **By genre.** `Genres` holds comma-separated values, so
   `WHERE Genres LIKE '%Strategy%'` finds every strategy gem. Build a
   top-10 gem list for your favorite genre.
5. **By language.** `Supported languages` works the same way — find the
   gems playable in Spanish, or Japanese, or any language you care about.
   (This is the same skill as genre filtering; the payoff is realizing
   that.)
6. **By platform.** `Linux = 'True'` narrows to Linux gems — a genuinely
   underserved list the internet would thank you for.
7. **By era.** `Release date` is text, but `LIKE '%2023%'` works. Are
   recent years producing more gems, or is the backlog where the treasure
   is?

## Ask a new question of the same data

8. **Gems per genre.** `GROUP BY` a genre flag and count gems in each
   bucket. Which genre hides the most treasure relative to its size?
9. **The playtime test.** `Average playtime forever` is a devotion signal
   reviews can't fake. Sort your gems by it. Do the most-loved gems also
   hold players the longest — and what does it mean when they don't?
10. **Price bands.** Use a CASE ladder to bucket gems into free / under $5 /
    under $10 / under $20, then count each band. Where do gems actually
    live on the price axis?

## Make it yours

The real graduation exercise: pick a question this README never asked,
write the query yourself, and add your finding to your own fork's README
with one sentence on why the threshold you picked is defensible. That last
sentence — defending a number — is the analyst skill everything here has
been building toward.

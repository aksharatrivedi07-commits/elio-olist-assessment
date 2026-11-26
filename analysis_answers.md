# Part B: analysis and recommendation

All numbers below come from the tables in `olist.marts`. The queries are in `sql/analytics_queries.sql`.

## B1. Commercial insights

### Insight 1: Late deliveries cost about two stars, and Rio is where it hurts most

About 7% of delivered orders arrive after the date the customer was promised. Those orders average 2.26 stars. Orders that arrive on time average 4.11, and orders that turn up a week or more early average 4.23.

| Delivery | Orders | Avg review |
|---|---|---|
| Late | 6,534 | 2.26 |
| On time (0-6 days early) | 13,796 | 4.11 |
| Early (7+ days early) | 76,140 | 4.23 |

I expected some drop, but not one this big. A late order loses almost two full stars, which is roughly the gap between a happy customer and a complaint.

The problem isn't spread evenly. Rio de Janeiro is the second biggest market in the data (12,351 orders), and 12.1% of its deliveries are late. São Paulo, the biggest, is late 4.5% of the time. Maranhão has the worst rate of all (17.4%, z-score 2.25), but with only 720 orders, so Rio is the one worth fixing first.

How I got there: I compared the actual delivery date with the estimated date shown at checkout, counting each order once so orders with several items didn't count twice. For the state comparison I used a z-score across states with at least 500 orders.

Why it matters: on a marketplace, reviews feed into ranking and trust. Losing two stars on roughly 1 in 14 orders is a reputation cost Olist pays on every late parcel.

### Insight 2: Almost nobody comes back, and what they buy first matters more than how it went

Only 2.19% of customers ever place a second order on a later day.

My first assumption was that a good first experience brings people back. In this data it doesn't, at least not in any way I could measure. On my first measure of repeat buying, customers who gave their first order 1 star came back at about the same rate as those who gave 5 stars (3.15% vs 3.21%). Delivery speed made only a small difference too.

What did make a difference was the category of the first purchase:

| First purchase | Customers | Came back |
|---|---|---|
| Furniture & decor | 6,029 | 2.92% |
| Bed, bath & table | 8,885 | 2.87% |
| All customers | 95,388 | 2.19% |
| Electronics | 2,491 | 1.41% |

People whose first order was furniture or bedding come back about a third more often than average, and twice as often as people who started with electronics. That fits intuition. Someone furnishing a flat keeps buying; someone who bought a games console usually doesn't need another one.

Two things had to be right for this to hold up. First, Olist creates a new `customer_id` for every order, so counting customers with it makes everyone look like a one-off buyer. I built the customer table on `customer_unique_id` instead. Second, a lot of "repeat" orders were placed on the same day as the first, which is really one shopping trip split into two orders. Once I only counted orders on a later day, the repeat rate fell from 3.1% to 2.19%.

I also got this query wrong the first time. It counted customers with several orders more than once, which pushed every repeat rate up. I noticed because the customer totals didn't match an earlier query, and fixed the join.

Why it matters: a loyalty scheme aimed at "repeat customers" is aimed at about 2 people in 100. The money is in turning more first-time buyers into second-time buyers, and home buyers are the most promising place to start.

## B2. Recommendation: a "complete the room" email for first-time home buyers

**Who.** Customers whose first order was in furniture & decor or bed, bath & table, and whose order arrived on time. That's about 14,900 customers in this dataset. I'd leave out anyone whose first order was late. Insight 1 says they're probably unhappy, and a sales email is the wrong next message for them; they should get a service follow-up instead.

**What.** One personalised email about four weeks after delivery, showing items that go with what they bought. Someone who bought bedding sees towels and cushions, and someone who bought a shelf sees decor. No discount.

I did consider offering free shipping, but the maths didn't work. About 2.9% of this group come back anyway, and Olist would be paying their shipping too. With a modest lift, the cost of the offer is likely to be bigger than the commission Olist earns on the extra orders. An email with no discount costs almost nothing per person, so whatever lift it produces is profit.

**Expected impact (rough).** Today, 2.9% of the segment buy again. If the email adds one percentage point, that's about 100 extra orders per 10,000 customers. With a first order averaging around 115 BRL, that's roughly 11,500 BRL of extra sales per 10,000 customers. The one-point lift is my assumption, not a forecast. It would bring the segment roughly up to the best-performing category (fashion bags, 3.8%). Olist's actual income is its commission on those sales, so I'd confirm the take rate with the client rather than guess it.

**How we'd know it worked.** Randomly split the eligible customers in half. One half gets the email and the other half gets nothing. The main measure is the share of each half that places a second order on a later day within 60 days of their first delivery. I'd take a first look at 8 weeks, and keep an eye on unsubscribes in case the email annoys people.

There's one catch I want to be upfront about. To reliably spot a one-point lift from a 2.9% starting rate, you need roughly 4,500 customers in each half, so about 9,000 in total. At this dataset's pace (around 600 new home buyers a month) that would take over a year. On Olist's full live volume it would be much quicker. If it isn't, I'd run the email for all first-time buyers with on-time deliveries, matching the products to whatever they bought, and report the home group separately.

## B3. Assumptions, caveats and data quality

These are the things I'd tell a client up front rather than bury:

- I treated `customer_unique_id` as one real person. That's how Olist defines it, but I can't check it.
- Newer customers had less time to come back. Someone whose first order was in mid 2018 had only a few months left in the data, so repeat rates understate loyalty for recent customers.
- Home buyers coming back more often doesn't prove the category causes it. They might just be different kinds of people. That's exactly why I'm recommending a test with a control group rather than a full rollout.
- Some reviews cover several orders and some orders have several reviews. I kept the latest review for each order.
- "First purchase category" means the category of the most expensive item in the first order. A customer's state is the one on their most recent order.
- 13 products have no English category name, so they're shown in Portuguese. Around 700 customers have orders with no items (cancelled early), and they aren't in the item-level table.
- The four-week timing comes from the median gap between first and second orders (28.5 days). That figure still included same-day orders, so the real gap is probably longer. I'd check it again before launch.
- Money is in BRL with no inflation adjustment, and the dataset is a sample of Olist's business, so absolute numbers need scaling to real volumes.

The three data quality checks I'd want running in production:

1. **Key and relationship tests on every run.** These are already built (56 dbt tests): every key is unique and not null, and every item, payment and review links to a real order. Snowflake doesn't enforce these itself, so without the tests nothing stops a duplicate or orphaned row from slipping in.
2. **Freshness and row counts on the raw load.** If `_loaded_at` is older than expected, or a table suddenly has far fewer rows than last time, something should raise an alert. A half-loaded file is the failure most likely to go unnoticed.
3. **Basic business rules.** Price above zero, review scores between 1 and 5, and no order marked delivered without a delivery date. These catch upstream problems that would quietly skew the delivery and revenue numbers this analysis depends on.

## B4. Client memo

**To:** CFO / COO
**Re:** What the Olist data tells us, and what to do next

We've loaded two years of Olist marketplace data, about 99,000 orders, into Snowflake and organised it into clean tables that are checked automatically every time they update.

Two things stood out.

First, late deliveries are costing reputation. About 7% of orders arrive late, and those orders average 2.3 stars against just over 4 for everything else. Rio de Janeiro, the second largest market, is late 12% of the time, nearly three times the São Paulo rate.

Second, very few customers come back. Only about 2 in 100 place a second order. The exception is people whose first purchase is for the home, like furniture or bedding. They return about a third more often than average and twice as often as electronics buyers.

My suggestion is a small, cheap test. Home buyers whose order arrived on time get one email about four weeks later showing items that go with what they bought, with no discount. Half get it and half don't, so we see the real effect. Each extra point of return rate is worth roughly 11,500 BRL in sales per 10,000 customers.

## B5. LLM use case (bonus)

The review comments are free text in Portuguese, and at this volume nobody reads them. I'd use Snowflake Cortex to tag each comment with a reason (late, wrong item, damaged, poor quality, other), so the delivery problem in Insight 1 can be broken down further.

A manager could ask: "Why are customers in Rio giving 1-star reviews this month?" The system would pull that month's 1 and 2 star reviews for Rio orders, along with days late and product category from `fct_order_items`. It would answer with counts per reason and a few real example comments, for instance that most mention late delivery and a smaller share mention the wrong item.

The main risk is the model getting labels wrong or summarising things that aren't in the comments, plus costs creeping up if every review gets reprocessed. I'd limit it to a fixed list of labels, check a sample of 200 by hand before trusting the output, and only classify new reviews each day. Running it inside Snowflake also means customer text never leaves the platform.
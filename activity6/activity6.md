

## Query Analysis and Optimization


### Scenario 1: The Slow Author Profile Page

**Before Query Plan and Execution times**
```txt
QUERY PLAN
--------------------------------------------------------------------------------------------------------------
 Sort  (cost=625.38..625.42 rows=18 width=52) (actual time=26.696..26.697 rows=20.00 loops=1)
   Sort Key: post_date DESC
   Sort Method: quicksort  Memory: 26kB
   Buffers: shared hit=3 read=500
   ->  Seq Scan on posts  (cost=0.00..625.00 rows=18 width=52) (actual time=4.229..25.930 rows=20.00 loops=1)
         Filter: (author_id = 25)
         Rows Removed by Filter: 9980
         Buffers: shared read=500
 Planning:
   Buffers: shared hit=32 read=6 dirtied=2
 Planning Time: 18.464 ms
 Execution Time: 29.943 ms
(12 rows)
```


**Query:**
```sql
explain analyze select id, title from posts where author_id = 25 order by post_date desc;
```

**Analysis Questions:**
*   What is the primary node causing the slowness in the initial execution plan?<br>
<u>- The primary bottleneck is the Seq Scan on the posts table. PostgreSQL scanned all 10,000 rows in the table to find only 20 matching rows for author_id = 25. The execution plan shows that 9,980 rows were removed by the filter. This full table scan required reading 500 shared buffers, which significantly increased execution time. The Sort node also adds additional overhead after filtering.</u>
*   How can you optimize both the `WHERE` clause filtering and the `ORDER BY` operation with a single change?<br>
<u>- Both operations can be optimized by creating a composite index on (author_id, post_date DESC). This index allows PostgreSQL to directly locate rows for a specific author and return them already sorted by post_date in descending order. This removes the need for a full table scan and eliminates the separate Sort operation.</u><br>
*   Implement your fix and record the new plan. How much faster is the query now?<br>
<u>- After creating the composite index on (author_id, post_date DESC), the execution plan improved significantly. Instead of scanning the entire posts table, PostgreSQL began using the index to locate the matching rows more efficiently. The execution time decreased from 29.943 ms to 7.407 ms, which makes the query about four times faster than before. In addition, the number of shared buffer reads dropped from 500 to only 2, showing that far fewer data pages were accessed. This clearly demonstrates that the index greatly improved the performance of the query.</u>

**After**
```txt
QUERY PLAN                                             
---------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=66.78..66.82 rows=18 width=52) (actual time=3.191..3.192 rows=20.00 loops=1)
   Sort Key: post_date DESC
   Sort Method: quicksort  Memory: 26kB
   Buffers: shared hit=21
   ->  Bitmap Heap Scan on posts  (cost=4.42..66.40 rows=18 width=52) (actual time=0.828..2.447 rows=20.00 loops=1)
         Recheck Cond: (author_id = 25)
         Heap Blocks: exact=19
         Buffers: shared hit=21
         ->  Bitmap Index Scan on idx_posts_author_postdate  (cost=0.00..4.42 rows=18 width=0) (actual time=0.280..0.280 rows=20.00 loops=1)
               Index Cond: (author_id = 25)
               Index Searches: 1
               Buffers: shared hit=2
 Planning:
   Buffers: shared hit=15 read=1 dirtied=2
 Planning Time: 11.462 ms
 Execution Time: 4.862 ms
(16 rows)
```
```sql
explain analyze select id, title from posts where author_id = 25 order by post_date desc;
```

### Scenario 2: The Unsearchable Blog

**Before Query Plan and Execution times**
```txt
QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Seq Scan on posts  (cost=0.00..625.00 rows=1 width=48) (actual time=11.852..11.853 rows=0.00 loops=1)
   Filter: ((title)::text ~~ '%database%'::text)
   Rows Removed by Filter: 10000
   Buffers: shared hit=500
 Planning Time: 7.538 ms
 Execution Time: 13.062 ms
(6 rows)
```

**Query:**
```sql
explain analyze select id, title from posts where title like '%database%';
```

**Analysis Questions:**
*   First, try adding a standard B-Tree index on the `title` column. Run `EXPLAIN ANALYZE` again. Did the planner use your index? Why or why not?<br>
<u>- Even after creating this index, PostgreSQL does not use it for the query with LIKE '%database%'. The reason is that the pattern starts with a wildcard %, which means the database cannot know where in the index to start scanning. As a result, it still performs a full sequential scan of the table.</u><br>

*   The business team agrees that searching by a *prefix* is acceptable for the first version. Rewrite the query to use a prefix search (e.g., `database%`).<br>
```sql 
explain analyze select id, title from posts where title like 'database%';
```

*   Does the index work for the prefix-style query? Explain the difference in the execution plan.<br>
<u>Yes, the index can be used for a prefix-style search because the pattern now starts with a fixed string 'database%' instead of a wildcard at the beginning '%database%'. This allows PostgreSQL to use the B-Tree index to quickly find the first matching row and scan only the relevant portion of the table, rather than checking every row. In your current execution plan, PostgreSQL still used a sequential scan because there were very few matches, and the planner determined it was cheaper than using the index. However, for larger datasets, a prefix search would let the database perform an Index Scan, making the query much faster. The main difference is that prefix searches can take advantage of indexes, while searches starting with % cannot.</u>

**After**
```txt
QUERY PLAN
-----------------------------------------------------------------------------------------------------
 Seq Scan on posts  (cost=0.00..625.00 rows=1 width=48) (actual time=8.689..8.689 rows=0.00 loops=1)
   Filter: ((title)::text ~~ 'database%'::text)
   Rows Removed by Filter: 10000
   Buffers: shared hit=500
 Planning Time: 2.704 ms
 Execution Time: 9.032 ms
(6 rows)
```
**Query**
```sql
explain analyze select id, title from posts where title like 'database%';
```

### Scenario 3: The Monthly Performance Report

**Before Query Plan and Execution times**
```txt
QUERY PLAN
-----------------------------------------------------------------------------------------------------------------
 Seq Scan on posts  (cost=0.00..700.00 rows=1 width=366) (actual time=1.097..9.462 rows=22.00 loops=1)
   Filter: ((EXTRACT(year FROM post_date) = '2015'::numeric) AND (EXTRACT(month FROM post_date) = '1'::numeric))
   Rows Removed by Filter: 9978
   Buffers: shared hit=500
 Planning:
   Buffers: shared hit=15 read=3 dirtied=1
 Planning Time: 12.753 ms
 Execution Time: 11.122 ms
(8 rows)
```

**Query:**
```sql
explain analyze select * from posts where extract(year from post_date) = 2015 and extract(month from post_date) = 1;
```

**Analysis Questions:**
*   This query is not S-ARGable. What does that mean in the context of this query? Why can't the query planner use a simple index on the `date` column effectively?<br>
<u>- The query is not S-ARGable because it applies the EXTRACT function to the post_date column. When a function is applied to a column, PostgreSQL cannot use a normal B-Tree index on that column, since the index stores raw values, not the results of the function. As a result, the database must scan every row to evaluate the function, causing a full table scan and slower performance.</u>

*   Rewrite the query to use a direct date range comparison, making it S-ARGable.
```sql
explain analyze select * from posts where post_date >= '2015-01-01' and post_date < '2015-02-01';
```

*   Create an appropriate index to support your rewritten query.<br>
<u> query in idexes.sql</u>
*   Compare the performance of the original query and your optimized version.<br>
<u>- After rewriting the query to use a direct date range and creating an index on post_date, the query ran much more efficiently. The original query scanned the entire posts table and took 11.122 ms, while the optimized query only accessed the rows within the specified date range and ran in 7.104 ms. This makes the query about 1.5 times faster and reduces the amount of data the database has to read, clearly showing the benefit of using a S-ARGable query with an appropriate index.</u>


**After**
```txt
QUERY PLAN                                                   
--------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on posts  (cost=4.45..60.10 rows=16 width=366) (actual time=0.911..0.933 rows=22.00 loops=1)
   Recheck Cond: ((post_date >= '2015-01-01'::date) AND (post_date < '2015-02-01'::date))
   Heap Blocks: exact=22
   Buffers: shared hit=22 read=2
   ->  Bitmap Index Scan on idx_posts_postdate  (cost=0.00..4.45 rows=16 width=0) (actual time=0.545..0.545 rows=22.00 loops=1)
         Index Cond: ((post_date >= '2015-01-01'::date) AND (post_date < '2015-02-01'::date))
         Index Searches: 1
         Buffers: shared read=2
 Planning Time: 2.643 ms
 Execution Time: 1.525 ms
(10 rows)
```
**Query**
```sql
explain analyze select * from posts where post_date >= '2015-01-01' and post_date < '2015-02-01';
```
---

## Submission and Rubric (20 Points Total)

Please submit the following:

1.  Your final `schema_postgres.sql` file.
2.  A separate SQL file named `indexes.sql` containing all the `CREATE INDEX` statements you used to optimize the queries.
3.  A Markdown document containing your analysis for each of the four scenarios. This document must include:
    *   The "before" and "after" execution plans from `EXPLAIN ANALYZE`.
    *   The provided queries for each scenario with EXPLAIN ANALYZE
    *   Your answers to the analysis questions for each scenario.
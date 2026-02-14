-- Scenario 1
create index idx_posts_author_postdate on posts (author_id, post_date desc);

-- Scenario 2
create index idx_posts_title on posts (title);

-- Scenario 3
create index idx_posts_postdate on posts (post_date);
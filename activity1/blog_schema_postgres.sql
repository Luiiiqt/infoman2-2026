-- PostgreSQL Schema for Week 1 Lab Activity

DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    comment TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Data Inserts

INSERT INTO users (username) VALUES
('alice'),
('bob'),
('charlie'),
('diana'),
('edward'),
('fiona'),
('george');

INSERT INTO posts (user_id, title, body) VALUES
(1, 'First Post!', 'This is the body of the first post.'),
(2, 'Bob''s Thoughts', 'A penny for my thoughts.'),
(3, 'Hello World', 'My first blog post here!'),
(4, 'Tech Talk', 'Let’s talk about databases.'),
(5, 'Daily Journal', 'Today was a productive day.'),
(6, 'Travel Notes', 'I love visiting new places.'),
(7, 'Random Ideas', 'Just sharing some random thoughts.');

INSERT INTO comments (post_id, user_id, comment) VALUES
(1, 2, 'Great first post, Alice!'),
(2, 1, 'Interesting thoughts, Bob.'),
(3, 1, 'Welcome to blogging!'),
(4, 3, 'Nice insights on tech.'),
(5, 4, 'Sounds like a good day!'),
(6, 5, 'Travel posts are the best.'),
(7, 6, 'Looking forward to more posts.');

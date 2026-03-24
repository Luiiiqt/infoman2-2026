# Lab Activity 10: PostgreSQL CRUD to MongoDB CRUD

**Goal:** Translate basic PostgreSQL CRUD commands into MongoDB CRUD commands.


**Tool:** `mongosh` (or MongoDB Compass shell).

---

## Part 1: Quick Mapping (Postgres -> MongoDB)

Complete this table in your `solution.md`.

| PostgreSQL | MongoDB Equivalent |
|---|---|
| `INSERT INTO posts ...` | `?` |
| `SELECT * FROM posts WHERE title='...'` | `?` |
| `UPDATE posts SET title='...' WHERE id=...` | `?` |
| `DELETE FROM posts WHERE id=...` | `?` |

---

## Part 2: Hands-on CRUD in MongoDB

Take a screenshot from Mongo shell after each command (or small command block) is executed.

### 2.1 Setup

Run:

```javascript
use devstream_db
db.posts.drop()
```

Insert one document:

```javascript
db.posts.insertOne({
  _id: 1,
  title: "Mastering MongoDB for Postgres Devs",
  content: "Intro guide",
  author_username: "db_wizard",
  category: "database",
  views: 10
})
```

### 2.2 Create

Insert one more post (`_id: 2`) with your own title and category.

### 2.3 Read

Write and run queries for:
1. Find all posts.
2. Find the post with `_id: 1`.
3. Show only `title` and `author_username` (exclude `_id`).

### 2.4 Update

Write and run updates for:
1. Change the title of `_id: 1` to `"MongoDB CRUD Basics"`.
2. Increase `views` of `_id: 1` by 1 using `$inc`.
3. Add `status: "published"` to all posts.

### 2.5 Delete

Write and run a command to delete the post with `_id: 2`.

---

## Part 3: Short Reflection (3-4 sentences)

Explain:
1. One thing that feels easier in MongoDB CRUD.
2. One thing that was clearer in PostgreSQL CRUD.

---

## Submission

Submit `solution.md` with:
1. Completed mapping table.
2. All MongoDB commands used.
3. Reflection.
4. Screenshots from Mongo shell showing command execution and results.
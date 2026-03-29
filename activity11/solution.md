# Activity 11: SQL to MongoDB & Advanced Querying - Answer Template

## Part 1: Relational to Document Modeling

### 1. Proposed JSON Schema (`posts` collection)
```json
// Provide your single document structure here
{
  "_id": ObjectId(),
  "title": "DevConnect",
  "body": "migrating a developer networking site from PostgreSQL to MongoDB.",
  "created_at": new Date(),
  "author": {
    "id": 1,
    "username": "luiii",
    "email": "luigi.hufana@lorma.edu",
    "bio": "mabangis"
  },
  "tags": [
    { "id": 1, "name": "mongosh" },
    { "id": 2, "name": "nosql" }
  ]
}
```

### 2. Strategic Choices
*   **Tags:** (Embed)
*   **Author:** (Embed)

### 3. Justification
> I chose to embed the tags because they’re small and directly tied to each post. Embedding them also avoids extra queries, which makes reading data faster. I did the same with the author information, so each post already includes the user details when it’s retrieved. This approach works well since the embedded data is small and doesn’t change often, keeping data access simple and efficient.

---

## Part 2: Querying with MQL Operators

```javascript
db.inventory.insertMany([
  { name: "Pro Laptop", category: "Electronics", price: 1200, tags: ["work","gaming"], specs: { RAM: 16, CPU: "i7" }, ratings: [5,4,5] },
  { name: "Budget Phone", category: "Electronics", price: 200, tags: ["mobile"], specs: { RAM: 4, CPU: "snapdragon" }, ratings: [3,2] },
  { name: "Mechanical Keyboard", category: "Peripherals", price: 150, tags: ["work","wireless"], specs: { Keys: 104 }, ratings: [5,5] },
  { name: "Smart Watch", category: "Electronics", price: 350, tags: ["mobile","wireless"], specs: { RAM: 2 }, ratings: [4,4,3] },
  { name: "Desk Lamp", category: "Home", price: 45, tags: ["office"], specs: {}, ratings: [5] },
  { name: "Gaming Monitor", category: "Peripherals", price: 450, tags: ["gaming","high-refresh"], specs: { Resolution: "4K", Refresh: "144Hz" }, ratings: [5,4] },
  { name: "USB-C Hub", category: "Accessories", price: 60, tags: ["work","connectivity"], specs: { Ports: 7 }, ratings: [4,3,4] },
  { name: "Ergonomic Mouse", category: "Peripherals", price: 85, tags: ["work","wireless"], specs: { DPI: 4000 }, ratings: [5,5,4] },
  { name: "External SSD", category: "Storage", price: 120, tags: ["backup","fast"], specs: { Capacity: "1TB" }, ratings: [5,4] },
  { name: "Web Cam", category: "Accessories", price: 110, tags: ["work","video"], specs: { Resolution: "1080p" }, ratings: [4,4] },
  { name: "NC Headphones", category: "Audio", price: 300, tags: ["travel","wireless"], specs: { Battery: "30h" }, ratings: [5,5,5] },
  { name: "Smart Bulb", category: "Home", price: 25, tags: ["lighting","wireless"], specs: { Color: "RGB" }, ratings: [3,4] },
  { name: "Router", category: "Networking", price: 180, tags: ["home","wireless"], specs: { Speed: "AX3000" }, ratings: [4,5] },
  { name: "Tablet", category: "Electronics", price: 650, tags: ["mobile","creative"], specs: { RAM: 8, Storage: "256GB" }, ratings: [5,4,4] },
  { name: "BT Speaker", category: "Audio", price: 90, tags: ["outdoor","wireless"], specs: { Waterproof: "IPX7" }, ratings: [4,4] }
])
```

### 1. Price Range
*Find all items priced between $100 and $500 (inclusive).*
```javascript
db.inventory.find ({
price: { $gte: 100, $lte: 500 }
})
```

### 2. Category Match
*Find all items that are in either the "Peripherals" or "Home" categories.*
```javascript
db.inventory.find({
  category: { $in: ["Peripherals","Home"] }
})
```

### 3. Tag Power
*Find all items that have **both** the "work" AND "wireless" tags.*
```javascript
db.inventory.find({
  tags: { $all: ["work","wireless"] }
})
```

### 4. Nested Check
*Find all items where the `specs.ram` is greater than 8GB.*
```javascript
db.inventory.find({
  "specs.RAM": { $gt: 8 }
})
```

### 5. High Ratings
*Find all items that have at least one `5` in their `ratings` array.*
```javascript
db.inventory.find({
  ratings: 5
})
```

---

## Screenshots
![](images/image.png)

### 1.
![](images/image1.png)

![](images/image2.png)

### 2.
![](images/image3.png)

### 3.
![](images/image4.png)

### 4.
![](images/image5.png)

### 5.
![](images/image6.png)

![](images/image7.png)
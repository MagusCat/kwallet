CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT '$',
        icon_key TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      );
CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        monthly_limit REAL NOT NULL,
        created_at TEXT NOT NULL
      );
CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 1
      );
CREATE TABLE kitty_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        level INTEGER NOT NULL,
        exp INTEGER NOT NULL,
        mood TEXT NOT NULL,
        happiness INTEGER NOT NULL,
        last_interacted TEXT NOT NULL
      );
CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      );

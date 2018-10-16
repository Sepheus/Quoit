module quoit.quoit;

import d2sqlite3 : Database;

struct SQLiteDB {
    Database db;
    alias db this;
    this(string connString) {
        db = Database(connString);
    }
}
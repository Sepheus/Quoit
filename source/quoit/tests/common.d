
module quoit.tests.common;

import quoit.record;

@Table("test_record")
class TestRecord : Record!TestRecord {

    mixin ActiveRecord!();

    @Id
    @AutoIncrement
    int id;

    @Column
    @MaxLength(5)
    string name;

    @Column
    int type;

    static this() {
        auto db = SQLiteDB(":memory:");
        db.run("CREATE TABLE test_record (id INTEGER PRIMARY KEY, name CHAR(5), type INTEGER)");
        setDBConnection(db);
    }

}

unittest {
    import std.stdio : writeln, writefln;
    // Test record create.
    auto record = new TestRecord;
    record.name = "Test";
    record.type = 1;
    record.create;
    assert(record.id != 0);

    // Fetch the created record.
    record = TestRecord.get(record.id);
    assert(record !is null);
    "Record name %s".writefln(record.name);
    assert(record.name == "Test");
    assert(record.type == 1);

    // Test record save.
    record.name = "Test2";
    record.type = 2;
    record.save;

    // Fetch the updated record.
    record = TestRecord.get(record.id);
    assert(record !is null);
    assert(record.name == "Test2");
    assert(record.type == 2);

    // Test record selective save.
    record.name = "Test3";
    record.type = 3;
    record.save("type");

    // Fetch the upated record.
    record = TestRecord.get(record.id);
    assert(record !is null);
    assert(record.name == "Test2");
    assert(record.type == 3);

    // Test record find.
    auto records = TestRecord.find(["name": "Test2"]);
    assert(records.length >= 1);
    assert(records[0].name == "Test2");
    assert(records[0].type == 3);


    auto record2 = new TestRecord;
    record2.name = "New";
    record2.type = 4;
    record2.create;

    // Test max-length.
    try {
        record.name = "Test123";
        record.save("name");

        // Should not be reached.
        assert(false);
    } catch(RecordException e) {
        // Success.
    }

    // Test not-null.
    try {
        record.name = null;
        record.save("name");

        // Should not be reached.
        assert(false);
    } catch(RecordException e) {
        // Success.
    }

    // Test record remove.
    record = records[0];
    record.remove;
    "Record ID: %s".writefln(record.id);

    // Check that the record doens't exist.
    try {
        record = TestRecord.get(record.id);

        // Should not be reached.
        assert(false);
    } catch(RecordException e) {
        // Success.
    }

    record.name = "Bob";
    record.type = 7;
    record.create;

}

@Table("users")
class UserRecord : Record!UserRecord
{

    mixin ActiveRecord!();

    static this()
    {
        // Connect to a database.
        auto db = SQLiteDB(":memory:");
        db.run("CREATE TABLE users (id INTEGER PRIMARY KEY, username CHAR(32), pass_hash CHAR(64), status CHAR(20), last_online BIGINT)");
        setDBConnection(db);
    }

    @Id
    @AutoIncrement
    uint id;

    @Column
    @MaxLength(32)
    string username;

    @Column("pass_hash")
    @MaxLength(64)
    string passwordHash;

    @Column
    @Nullable
    string status;

    @Column("last_online")
    ulong lastOnline;

}

void deleteUserById(uint id) {
    UserRecord user = UserRecord.get(id);
    user.remove;
}

void updateUserStatus(uint id, string status) {
    UserRecord user = UserRecord.get(id);
    user.status = status;
    user.save;
}

UserRecord[] findUsersWithStatus(string status) {
    return UserRecord.find(["status": status]);
}

unittest {
    auto user = new UserRecord;
    user.username = "Jenkins";
    user.passwordHash = "abc";
    user.status = "Exploring";
    user.lastOnline = 144141550;
    user.create;
    user.id.updateUserStatus("In Town");
}



/* - Compound Fields - */
/* - - - - - - - - - - */

@Compound
struct TestCompound {

    @Column
    @MaxLength(32)
    string name;

    @Column
    @Nullable
    @MaxLength(128)
    string address;

}

@Table("test_record2")
class TestRecord2 : Record!TestRecord2 {

    mixin ActiveRecord!();

    @Id
    @AutoIncrement
    int id;

    @Embedded
    TestCompound info;

}

unittest {

    // TODO

}

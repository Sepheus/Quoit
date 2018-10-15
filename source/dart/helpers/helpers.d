
module dart.helpers.helpers;

import std.variant;

import dart.record;
import dart.helpers.attributes;

class ColumnBindings {

    /**
     * The name of the column.
     **/
    string name;

    /**
     * The name of the bound field.
     **/
    string field;

    /**
     * Whether the column is an Id.
     **/
    bool isId = false;

    /**
     * Whether the column cannot be null.
     **/
    bool notNull = true;

    /**
     * Auto increment value of the column.
     **/
    bool autoIncrement = false;

    /**
     * The maximum length of the column.
     **/
    int maxLength = -1;

    /**
     * Gets the value of the field bound to this column.
     **/
    Variant delegate(Object) get;

    /**
     * Sets the value of the field bound to this column.
     **/
    void delegate(Object, Variant) set;

}

/**
 * Checks if a type is a table, and returns the table name.
 **/
static string getTableDefinition(Type)() {
    string result;
    // Search for @Column annotation.
    static foreach(annotation; __traits(getAttributes, Type)) {
        // Check if @Table is present.
        if(is(annotation == Table)) {
            result = Type.stringof;
        }
        // Check if @Table("name") is present.
        else if(is(typeof(annotation) == Table)) {
            result = annotation.name;
        }
        else {
            result = Type.stringof;
        }
    }

    // Not found.
    return result;
}

/**
 * Compile-time helper for finding columns.
 **/
static bool isColumn(Type, string member)() {
    bool result;
    // Search for @Column annotation.
    static foreach(annotation; __traits(getAttributes,
            __traits(getMember, Type, member))) {
        // Check is @Id is present (implicit column).
        if(is(annotation == Id)) {
            result = true;
        }
        // Check if @Column is present.
        else if(is(annotation == Column)) {
            result = true;
        }
        // Check if @Column("name") is present.
        else if (is(typeof(annotation) == Column)) {
            result = true;
        }
    }
    return result;
}

/**
 * Compile-time helper for finding columns.
 **/
static bool isJoinColumn(Type, string member)() {
    // Search for @JoinColumn annotation.
    foreach(annotation; __traits(getAttributes,
            __traits(getMember, Type, member))) {
        // Check if @JoinColumn is present.
        static if(is(annotation == JoinColumn)) {
            return true;
        }
        // Check if @JoinColumn("name", "mappedBy") is present.
        static if(is(typeof(annotation) == JoinColumn)) {
            return true;
        }
    }

    // Not found.
    return false;
}

/**
 * Determines the name of a column field.
 **/
static string getColumnDefinition(Type, string member)() {
    string result;
    // Search for @Column annotation.
    static foreach(annotation; __traits(getAttributes,
            __traits(getMember, Type, member))) {
        // Check if @Column is present.
        static if(is(annotation == Column)) {
            result = member;
        }
        // Check if @Column("name") is present.
        else static if(is(typeof(annotation) == Column)) {
            result = annotation.name;
        }
        else { 
            result = member;
        }
    }
    return result;
}

/**
 * Helper function template for create getter delegates.
 **/
static Variant delegate(Object)
        createGetDelegate(T, string member)(ColumnBindings info) {
    // Alias to target member, for type information.
    alias Type = typeof(__traits(getMember, T, member));

    // Create the get delegate.
    return delegate(Object local) {
        T record = cast(T)(local);

        // Check if null-assignable.
        static if(isAssignable!(Type, typeof(null))) {
            // Check that the value abides by null rules.
            if(info.notNull && !info.autoIncrement &&
                    __traits(getMember, record, member) is null) {
                throw new RecordException("Non-nullable value of " ~
                        member ~ " was null.");
            }
        }

        // Check for a length property.
        static if(hasMember!(Type, "length") || isArray!Type) {
            // Check that length doesn't exceed max.
            if(info.maxLength != -1 && __traits(getMember,
                    record, member).length > info.maxLength) {
                throw new RecordException("Value of " ~
                        member ~ " exceeds max length.");
            }
        }

        // Convert value to variant.
        static if(is(Type == Variant)) {
            return __traits(getMember, record, member);
        } else {
            return Variant(__traits(getMember, record, member));
        }
    };
}

/**
* Helper function template for create setter delegates.
**/
static void delegate(Object, Variant)
        createSetDelegate(T, string member)(ColumnBindings local) {
    // Alias to target member, for type information.
    alias Type = typeof(__traits(getMember, T, member));

    // Create the set delegate.
    return delegate(Object local, Variant v) {
        // Convert value from variant.
        static if(is(Type == Variant)) {
            auto value = v;
        } else {
            auto value = v.coerce!Type;
        }

        __traits(getMember, cast(T)(local), member) = value;
    };
}

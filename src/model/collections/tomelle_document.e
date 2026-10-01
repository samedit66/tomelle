note
    description: "Mutable TOML document."

class
    TOMELLE_DOCUMENT

inherit
    ANY
        redefine
            is_equal
        end

create
    make

feature {NONE} -- Initialization

    make
        do
            create root.make
            create representation_store.make
        ensure
            empty: is_empty
        end

feature -- Access

    root: TOMELLE_TABLE

    representation: STRING_32
            -- Lossless source text while pristine; ordered item text otherwise.
        do
            Result := representation_store.representation (root)
        end

    items: ITERABLE [TOMELLE_ITEM]
            -- Physical document items in source order.
        do
            Result := representation_store.items
        end

    item_count: INTEGER
        do
            Result := representation_store.item_count
        end

    value (a_path: TOMELLE_PATH): detachable TOMELLE_VALUE
        do
            Result := root.value (a_path)
        end

    value_at (a_key_expression: READABLE_STRING_GENERAL): detachable TOMELLE_VALUE
        require valid_expression: is_valid_key_expression (a_key_expression)
        do
            Result := root.value_at (a_key_expression)
        end

    table_at (a_key_expression: READABLE_STRING_GENERAL): TOMELLE_TABLE
        require table_value: attached {TOMELLE_TABLE} value_at (a_key_expression)
        do
            check attached {TOMELLE_TABLE} value_at (a_key_expression) as l_table then
                Result := l_table
            end
        end

    array_at (a_key_expression: READABLE_STRING_GENERAL): TOMELLE_ARRAY
        require array_value: attached {TOMELLE_ARRAY} value_at (a_key_expression)
        do
            check attached {TOMELLE_ARRAY} value_at (a_key_expression) as l_array then
                Result := l_array
            end
        end

feature -- Status report

    has (a_path: TOMELLE_PATH): BOOLEAN
        do
            Result := root.has (a_path)
        end
    has_at (a_key_expression: READABLE_STRING_GENERAL): BOOLEAN
        require valid_expression: is_valid_key_expression (a_key_expression)
        do
            Result := root.has_at (a_key_expression)
        end

    is_empty: BOOLEAN
        do
            Result := root.is_empty
        end

    can_put (a_path: TOMELLE_PATH): BOOLEAN
        require path_not_empty: a_path.count > 0
        do
            Result := model_builder.can_put (root, a_path)
        end

    can_put_at (a_key_expression: READABLE_STRING_GENERAL): BOOLEAN
        local l_path: TOMELLE_PATH
        do
            if key_syntax.is_valid_expression (a_key_expression) then
                create l_path.make_from_key_expression (a_key_expression)
                Result := can_put (l_path)
            end
        end

    is_valid_key_expression (a_expression: READABLE_STRING_GENERAL): BOOLEAN
        do
            Result := key_syntax.is_valid_expression (a_expression)
        end

feature -- General modification

    put (a_value: TOMELLE_VALUE; a_path: TOMELLE_PATH)
        require
            path_not_empty: a_path.count > 0
            path_compatible: can_put (a_path)
        do
            store_owned (a_value.cloned_value, a_path, expression_for_path (a_path))
        ensure
            stored: attached value (a_path)
        end

    put_at (a_value: TOMELLE_VALUE; a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        local l_path: TOMELLE_PATH
        do
            create l_path.make_from_key_expression (a_key_expression)
            put (a_value, l_path)
        end

    remove (a_path: TOMELLE_PATH)
        local
            i: INTEGER
            l_table: TOMELLE_TABLE
            l_value: detachable TOMELLE_VALUE
            l_removed_value: detachable TOMELLE_VALUE
            l_possible: BOOLEAN
        do
            is_modified := True
            l_removed_value := value (a_path)
            if a_path.count > 0 then
                l_table := root
                l_possible := True
                from i := 1 until i >= a_path.count or else not l_possible loop
                    l_value := l_table [a_path [i]]
                    if attached {TOMELLE_TABLE} l_value as l_nested_table then
                        l_table := l_nested_table
                    else
                        l_possible := False
                    end
                    i := i + 1
                end
                if l_possible then
                    l_table.remove (a_path [a_path.count])
                end
            end
            if attached l_removed_value as l_removed then
                remove_physical_value (l_removed)
            end
        ensure absent: not has (a_path)
        end

    remove_at (a_key_expression: READABLE_STRING_GENERAL)
        require valid_expression: is_valid_key_expression (a_key_expression)
        local l_path: TOMELLE_PATH
        do
            create l_path.make_from_key_expression (a_key_expression)
            remove (l_path)
        end

    wipe_out
        do
            root.wipe_out
            representation_store.wipe_out
            is_modified := True
        ensure
            empty: is_empty
        end

feature -- Typed modification

    put_string_at (a_value: READABLE_STRING_GENERAL; a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        local
            v: TOMELLE_STRING
        do
            create v.make (a_value)
            put_owned_at (v, a_key_expression)
        end
    put_integer_at (a_value: INTEGER_64; a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        local
            v: TOMELLE_INTEGER
        do
            create v.make (a_value)
            put_owned_at (v, a_key_expression)
        end
    put_float_at (a_value: REAL_64; a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        local
            v: TOMELLE_FLOAT
        do
            create v.make (a_value)
            put_owned_at (v, a_key_expression)
        end
    put_boolean_at (a_value: BOOLEAN; a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        local
            v: TOMELLE_BOOLEAN
        do
            create v.make (a_value)
            put_owned_at (v, a_key_expression)
        end
    put_local_date_at (a_value: TOMELLE_LOCAL_DATE; a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        local
            v: TOMELLE_LOCAL_DATE_VALUE
        do
            create v.make (a_value)
            put_owned_at (v, a_key_expression)
        end
    put_local_time_at (a_value: TOMELLE_LOCAL_TIME; a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        local
            v: TOMELLE_LOCAL_TIME_VALUE
        do
            create v.make (a_value)
            put_owned_at (v, a_key_expression)
        end
    put_local_date_time_at (a_value: TOMELLE_LOCAL_DATE_TIME; a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        local
            v: TOMELLE_LOCAL_DATE_TIME_VALUE
        do
            create v.make (a_value)
            put_owned_at (v, a_key_expression)
        end
    put_offset_date_time_at (a_value: TOMELLE_OFFSET_DATE_TIME; a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        local
            v: TOMELLE_OFFSET_DATE_TIME_VALUE
        do
            create v.make (a_value)
            put_owned_at (v, a_key_expression)
        end
    put_table_at (a_value: TOMELLE_TABLE; a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        do
            put_owned_at (a_value.cloned_value, a_key_expression)
        end
    put_array_at (a_value: TOMELLE_ARRAY; a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        do
            put_owned_at (a_value.cloned_value, a_key_expression)
        end

    make_table_at (a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        local
            t: TOMELLE_TABLE
        do
            create t.make
            put_table_at (t, a_key_expression)
        end
    make_array_at (a_key_expression: READABLE_STRING_GENERAL)
        require path_compatible: can_put_at (a_key_expression)
        local
            a: TOMELLE_ARRAY
        do
            create a.make
            put_array_at (a, a_key_expression)
        end

feature -- Copying

    independent_copy: TOMELLE_DOCUMENT
        do
            Result := document_copier.copy (Current)
        ensure
            independent: Result /= Current
            equivalent: Result.is_equal (Current)
        end

feature -- Comparison

    is_equal (other: like Current): BOOLEAN
        do
            Result := root.is_equal (other.root)
        end

feature {TOMELLE_DOCUMENT, TOMELLE_DOCUMENT_COPIER} -- Copy support

    source_text: detachable STRING_32
        do
            Result := representation_store.source_text
        end

    set_root (a_root: TOMELLE_TABLE)
        do
            root := a_root
        end

    append_item_copy (a_item: TOMELLE_ITEM)
        do
            representation_store.append_item_copy (a_item)
        end

    append_item_copy_with_value (a_entry: TOMELLE_ENTRY; a_value: TOMELLE_VALUE)
        do
            representation_store.append_item (a_entry.independent_copy_with_value (a_value))
        end

    set_modified (a_modified: BOOLEAN)
        do
            is_modified := a_modified
        end

feature {TOMELLE_DOCUMENT, TOMELLE_DOCUMENT_BUILDER} -- Parser construction

    set_source_text (a_source: READABLE_STRING_GENERAL)
        do
            representation_store.set_source_text (a_source, root)
            is_modified := False
        ensure
            pristine: not is_modified
        end

    append_item (a_item: TOMELLE_ITEM)
        do
            representation_store.append_item (a_item)
        ensure
            one_more: item_count = old item_count + 1
        end

feature {NONE} -- Implementation

feature -- Status report

    is_modified: BOOLEAN

    has_preserved_source: BOOLEAN
            -- Can the original text be emitted without hiding semantic mutations?
        do
            Result := not is_modified and then representation_store.has_preserved_source (root)
        end

    key_syntax: TOMELLE_KEY_SYNTAX
        once
            create Result.make
        end

    put_owned_at (a_value: TOMELLE_VALUE; a_expression: READABLE_STRING_GENERAL)
        local l_path: TOMELLE_PATH
        do
            create l_path.make_from_key_expression (a_expression)
            store_owned (a_value, l_path, a_expression)
        end

    put_owned (a_value: TOMELLE_VALUE; a_path: TOMELLE_PATH)
        do
            model_builder.put_owned (root, a_value, a_path)
        end

    store_owned (a_value: TOMELLE_VALUE; a_path: TOMELLE_PATH; a_expression: READABLE_STRING_GENERAL)
        local
            l_old: detachable TOMELLE_VALUE
            l_key: TOMELLE_KEY
            l_entry: TOMELLE_ENTRY
        do
            l_old := value (a_path)
            put_owned (a_value, a_path)
            if attached l_old as l_previous then
                replace_physical_value (l_previous, a_value)
            else
                create l_key.make_parsed (a_expression, a_expression, " = ")
                create l_entry.make (l_key, a_value)
                representation_store.append_item (l_entry)
            end
            is_modified := True
        end

    replace_physical_value (a_old, a_new: TOMELLE_VALUE)
        do
            representation_store.replace_value (a_old, a_new)
        end

    remove_physical_value (a_value: TOMELLE_VALUE)
        do
            representation_store.remove_value (a_value)
        end

    expression_for_path (a_path: TOMELLE_PATH): STRING_32
        local
            i: INTEGER
            l_key: TOMELLE_KEY
        do
            create Result.make_empty
            from i := 1 until i > a_path.count loop
                if i > 1 then Result.extend ('.') end
                create l_key.make (a_path [i])
                Result.append (l_key.representation)
                i := i + 1
            end
        end

    model_builder: TOMELLE_MODEL_BUILDER
        once
            create Result
        end

    representation_store: TOMELLE_DOCUMENT_REPRESENTATION
    document_copier: TOMELLE_DOCUMENT_COPIER
        once
            create Result
        end

end

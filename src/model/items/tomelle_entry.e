note
    description: "Key and value entry in a TOML container."

class
    TOMELLE_ENTRY

inherit
    TOMELLE_ITEM

create
    make,
    make_parsed

feature {NONE} -- Initialization

    make (a_key: TOMELLE_KEY; a_value: TOMELLE_VALUE)
        do
            initialize_item
            key := a_key
            value := a_value
        end

    make_parsed (a_key: TOMELLE_KEY; a_value: TOMELLE_VALUE;
        a_source, a_source_value: READABLE_STRING_GENERAL)
        local
            l_source, l_source_value: STRING_32
            l_value_index: INTEGER
        do
            make (a_key, a_value)
            l_source := a_source.as_string_32
            l_source_value := a_source_value.as_string_32
            source_representation := l_source.twin
            source_value_representation := a_value.representation
            source_value_text := l_source_value.twin
            l_value_index := l_source.substring_index (l_source_value, 1)
            if l_value_index > 0 then
                if l_value_index > 1 then
                    source_prefix := l_source.substring (1, l_value_index - 1)
                else
                    create source_prefix.make_empty
                end
                if l_value_index + l_source_value.count <= l_source.count then
                    source_suffix := l_source.substring (l_value_index + l_source_value.count, l_source.count)
                else
                    create source_suffix.make_empty
                end
            end
        end

feature -- Access

    key: TOMELLE_KEY
    value: TOMELLE_VALUE

    representation: STRING_32
        do
            if attached source_prefix as l_prefix and then attached source_suffix as l_suffix then
                create Result.make_empty
                Result.append (l_prefix)
                Result.append (value.representation)
                Result.append (l_suffix)
            elseif attached source_representation as l_source and then
                attached source_value_representation as l_value_source and then
                value.representation.same_string (l_value_source)
            then
                Result := l_source.twin
            else
                create Result.make_empty
                Result.append (trivia.indent)
                Result.append (key.representation)
                Result.append (key.separator)
                Result.append (value.representation)
                Result.append (trivia.suffix)
            end
        end

    as_string: STRING_32
            -- Compatibility alias for `representation`.
        do
            Result := representation
        end

feature -- Element change

    replace (a_value: TOMELLE_VALUE)
        local
            l_trivia: TOMELLE_TRIVIA
        do
            l_trivia := value.trivia.independent_copy
            value := a_value
            value.set_trivia (l_trivia)
        ensure
            replaced: value = a_value
        end

feature -- Copying

    independent_copy: TOMELLE_ENTRY
        do
            Result := independent_copy_with_value (value.cloned_value)
        ensure
            independent: Result /= Current
        end

feature {TOMELLE_DOCUMENT, TOMELLE_DOCUMENT_COPIER} -- Document copy support

    independent_copy_with_value (a_value: TOMELLE_VALUE): TOMELLE_ENTRY
            -- Copy this physical entry while linking it to `a_value`.
        do
            if attached source_representation as l_source then
                check attached source_value_text as l_source_value then
                    create Result.make_parsed (key.independent_copy, a_value, l_source, l_source_value)
                end
            else
                create Result.make (key.independent_copy, a_value)
            end
            Result.set_trivia (trivia)
        ensure
            linked: Result.value = a_value
        end

feature {NONE} -- Source state

    source_representation: detachable STRING_32
    source_value_representation: detachable STRING_32
    source_value_text: detachable STRING_32
    source_prefix: detachable STRING_32
    source_suffix: detachable STRING_32

end

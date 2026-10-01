note
    description: "Performs document-wide lexical validation before parsing."

class
    TOMELLE_SOURCE_VALIDATOR

inherit
    TOMELLE_SOURCE_VALIDATION_POLICY

feature -- Validation

    is_valid (a_source: STRING_32): BOOLEAN
        do
            Result := has_valid_control_characters (a_source) and then
                headers_close_on_same_line (a_source)
        end

    has_valid_control_characters (a_source: STRING_32): BOOLEAN
        local
            i: INTEGER
            c: NATURAL_32
        do
            Result := True
            from i := 1 until i > a_source.count or else not Result loop
                c := a_source.code (i)
                if c = 13 then
                    Result := i < a_source.count and then a_source.code (i + 1) = 10
                elseif c < 32 then
                    Result := c = 9 or c = 10
                else
                    Result := c /= 127 and c /= 0x2028 and c /= 0x2029 and c /= 0x3000
                end
                i := i + 1
            end
        end

    headers_close_on_same_line (a_source: STRING_32): BOOLEAN
        local
            l_lines: LIST [STRING_32]
            l_line: STRING_32
            l_depth: INTEGER
        do
            Result := True
            l_lines := a_source.split ('%N')
            from l_lines.start until l_lines.after or else not Result loop
                l_line := l_lines.item.twin
                l_line.left_adjust
                if l_depth = 0 and then not l_line.is_empty and then l_line [1] = '[' then
                    Result := l_line.has (']')
                elseif l_depth = 0 and then not l_line.is_empty and then
                    (l_line [1] = '%"' or else l_line [1] = '%'')
                then
                    Result := l_line.occurrences (l_line [1]) >= 2
                else
                    l_depth := l_depth + l_line.occurrences ('[') + l_line.occurrences ('{') -
                        l_line.occurrences (']') - l_line.occurrences ('}')
                end
                l_lines.forth
            end
        end

end

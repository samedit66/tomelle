note
    description: "Canonical identity for dotted TOML paths used by definition validation."

class
    TOMELLE_PATH_IDENTITY

feature -- Canonicalization

    canonical_expression (a_expression: STRING_32): STRING_32
        do
            Result := canonical_prefix (a_expression, (create {TOMELLE_PATH}.make_from_key_expression (a_expression)).count)
        end

    canonical_prefix (a_expression: STRING_32; a_count: INTEGER): STRING_32
        do
            Result := canonical_joined_prefix ((create {STRING_32}.make_empty), a_expression, a_count)
        end

    canonical_joined_prefix (a_section, a_expression: STRING_32; a_count: INTEGER): STRING_32
        local i, l_added: INTEGER; l_section_path, l_expression_path: TOMELLE_PATH; l_key: READABLE_STRING_32
        do
            create Result.make_empty
            if not a_section.is_empty then
                create l_section_path.make_from_key_expression (a_section)
                from i := 1 until i > l_section_path.count or else l_added = a_count loop
                    l_key := l_section_path [i]
                    Result.append (l_key.count.out); Result.extend (':'); Result.append (l_key); Result.extend (';')
                    l_added := l_added + 1; i := i + 1
                end
            end
            create l_expression_path.make_from_key_expression (a_expression)
            from i := 1 until i > l_expression_path.count or else l_added = a_count loop
                l_key := l_expression_path [i]
                Result.append (l_key.count.out); Result.extend (':'); Result.append (l_key); Result.extend (';')
                l_added := l_added + 1; i := i + 1
            end
        end

end

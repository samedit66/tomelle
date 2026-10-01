note
    description: "Reads TOML sources and decodes strict UTF-8."

class
    TOMELLE_SOURCE_READER

inherit
    TOMELLE_SOURCE_PROVIDER

feature -- Access

    is_readable (a_path: PATH): BOOLEAN
        local
            l_file: RAW_FILE
        do
            create l_file.make_with_path (a_path)
            Result := l_file.exists and then l_file.is_readable
        end

    decoded_file (a_path: PATH): detachable STRING_32
        require
            path_not_empty: not a_path.is_empty
        local
            l_file: RAW_FILE
        do
            create l_file.make_with_path (a_path)
            if l_file.exists and then l_file.is_readable then
                l_file.open_read
                l_file.read_stream (l_file.count)
                Result := decoded_utf_8 (l_file.last_string)
                l_file.close
            end
        rescue
            if attached l_file and then l_file.is_open_read then
                l_file.close
            end
            Result := Void
        end

    decoded_utf_8 (a_bytes: STRING_8): detachable STRING_32
        local
            i, n, c, c2, c3, c4, l_code: INTEGER
            l_valid: BOOLEAN
        do
            create Result.make (a_bytes.count)
            n := a_bytes.count
            l_valid := True
            from i := 1 until i > n or else not l_valid loop
                c := a_bytes.code (i).to_integer_32
                if c <= 127 then l_code := c
                elseif 194 <= c and c <= 223 and i + 1 <= n then
                    c2 := a_bytes.code (i + 1).to_integer_32
                    l_valid := 128 <= c2 and c2 <= 191
                    l_code := (c - 192) * 64 + c2 - 128
                    i := i + 1
                elseif 224 <= c and c <= 239 and i + 2 <= n then
                    c2 := a_bytes.code (i + 1).to_integer_32
                    c3 := a_bytes.code (i + 2).to_integer_32
                    l_valid := 128 <= c2 and c2 <= 191 and 128 <= c3 and c3 <= 191 and
                        (c /= 224 or else c2 >= 160) and (c /= 237 or else c2 <= 159)
                    l_code := (c - 224) * 4096 + (c2 - 128) * 64 + c3 - 128
                    i := i + 2
                elseif 240 <= c and c <= 244 and i + 3 <= n then
                    c2 := a_bytes.code (i + 1).to_integer_32
                    c3 := a_bytes.code (i + 2).to_integer_32
                    c4 := a_bytes.code (i + 3).to_integer_32
                    l_valid := 128 <= c2 and c2 <= 191 and 128 <= c3 and c3 <= 191 and 128 <= c4 and c4 <= 191 and
                        (c /= 240 or else c2 >= 144) and (c /= 244 or else c2 <= 143)
                    l_code := (c - 240) * 262144 + (c2 - 128) * 4096 + (c3 - 128) * 64 + c4 - 128
                    i := i + 3
                else l_valid := False end
                if l_valid and then syntax_rules.is_unicode_scalar (l_code.to_natural_64) then
                    Result.append_code (l_code.to_natural_32)
                else
                    l_valid := False
                end
                i := i + 1
            end
            if not l_valid then Result := Void end
        end

feature {NONE} -- Rules

    syntax_rules: TOMELLE_SYNTAX_RULES
        once
            create Result
        end

end

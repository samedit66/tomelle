note
    description: "Value-specific canonical rendering strategy."

class
    TOMELLE_VALUE_SERIALIZER

feature -- Rendering

    serialized (a_value: TOMELLE_VALUE): STRING_32
        do
            if attached {TOMELLE_STRING} a_value as l_string then
                Result := serialized_string (l_string.value)
            elseif attached {TOMELLE_INTEGER} a_value as l_integer then
                Result := l_integer.value.out
            elseif attached {TOMELLE_FLOAT} a_value as a_float then
                Result := a_float.canonical_text.twin
            elseif attached {TOMELLE_BOOLEAN} a_boolean then
                if a_boolean.value then Result := "true" else Result := "false" end
            elseif attached {TOMELLE_LOCAL_DATE_VALUE} a_date then
                Result := serialized_date (a_date.value)
            elseif attached {TOMELLE_LOCAL_TIME_VALUE} a_time then
                Result := serialized_time (a_time.value)
            elseif attached {TOMELLE_LOCAL_DATE_TIME_VALUE} a_date_time then
                Result := serialized_date (a_date_time.value.date) + "T" + serialized_time (a_date_time.value.time)
            elseif attached {TOMELLE_OFFSET_DATE_TIME_VALUE} a_offset then
                Result := serialized_offset_date_time (a_offset.value)
            elseif attached {TOMELLE_ARRAY} a_array then
                Result := serialized_array (a_array)
            else
                check attached {TOMELLE_TABLE} a_value as l_table then
                    Result := serialized_table (l_table)
                end
            end
        end

    serialized_array (a_array: TOMELLE_ARRAY): STRING_32
        local i: INTEGER
        do
            create Result.make_from_string ("[")
            from i := 1 until i > a_array.count loop
                if i > 1 then Result.append (", ") end
                Result.append (serialized (a_array [i]))
                i := i + 1
            end
            Result.extend (']')
        end

    serialized_table (a_table: TOMELLE_TABLE): STRING_32
        local l_first: BOOLEAN
        do
            create Result.make_from_string ("{")
            l_first := True
            across a_table.keys as l_key loop
                if l_first then l_first := False else Result.append (", ") end
                Result.append (serialized_key (l_key))
                Result.append (" = ")
                check attached a_table [l_key] as l_value then Result.append (serialized (l_value)) end
            end
            Result.extend ('}')
        end

    serialized_key (a_key: READABLE_STRING_GENERAL): STRING_32
        local l_text: STRING_32; i: INTEGER; l_bare: BOOLEAN
        do
            l_text := a_key.as_string_32
            l_bare := not l_text.is_empty
            from i := 1 until i > l_text.count or else not l_bare loop
                l_bare := ('a' <= l_text [i] and l_text [i] <= 'z') or ('A' <= l_text [i] and l_text [i] <= 'Z') or
                    ('0' <= l_text [i] and l_text [i] <= '9') or l_text [i] = '-' or l_text [i] = '_'
                i := i + 1
            end
            if l_bare then Result := l_text.twin else Result := serialized_string (l_text) end
        end

    serialized_string (a_text: READABLE_STRING_GENERAL): STRING_32
        local l_text: STRING_32; i: INTEGER
        do
            l_text := a_text.as_string_32
            create Result.make (l_text.count + 2)
            Result.extend ('%"')
            from i := 1 until i > l_text.count loop
                inspect l_text [i]
                when '%"' then Result.append ("\%"")
                when '\\' then Result.append ("\\\\")
                when '%N' then Result.append ("\\n")
                when '%R' then Result.append ("\\r")
                when '%T' then Result.append ("\\t")
                else Result.extend (l_text [i])
                end
                i := i + 1
            end
            Result.extend ('%"')
        end

    serialized_date (a_date: TOMELLE_LOCAL_DATE): STRING_32
        do Result := padded (a_date.year, 4) + "-" + padded (a_date.month, 2) + "-" + padded (a_date.day, 2) end

    serialized_time (a_time: TOMELLE_LOCAL_TIME): STRING_32
        do
            Result := padded (a_time.hour, 2) + ":" + padded (a_time.minute, 2) + ":" + padded (a_time.second, 2)
            if a_time.fractional_digit_count > 0 then
                Result.extend ('.')
                Result.append (padded (a_time.nanosecond, 9).substring (1, a_time.fractional_digit_count))
            end
        end

    serialized_offset_date_time (a_value: TOMELLE_OFFSET_DATE_TIME): STRING_32
        local l_absolute: INTEGER
        do
            Result := serialized_date (a_value.local_date_time.date) + "T" + serialized_time (a_value.local_date_time.time)
            if a_value.is_utc then Result.extend ('Z') else
                l_absolute := a_value.offset_minutes.abs
                if a_value.offset_minutes < 0 then Result.extend ('-') else Result.extend ('+') end
                Result.append (padded (l_absolute // 60, 2)); Result.extend (':'); Result.append (padded (l_absolute \\ 60, 2))
            end
        end

    padded (a_value, a_width: INTEGER): STRING_32
        do
            Result := a_value.out
            from until Result.count >= a_width loop Result.prepend_character ('0') end
        end

end

note
    description: "Ownership-preserving copy coordinator for TOML documents."

class
    TOMELLE_DOCUMENT_COPIER

feature -- Copying

    copy (a_document: TOMELLE_DOCUMENT): TOMELLE_DOCUMENT
        local l_root_copy: TOMELLE_TABLE
        do
            create Result.make
            l_root_copy := a_document.root.cloned_table
            Result.set_root (l_root_copy)
            across a_document.items as l_item loop
                if attached {TOMELLE_ENTRY} l_item as l_entry and then
                    attached cloned_counterpart (l_entry.value, a_document.root, l_root_copy) as l_value_copy
                then
                    Result.append_item_copy_with_value (l_entry, l_value_copy)
                else
                    Result.append_item_copy (l_item)
                end
            end
            if attached a_document.source_text as l_source then Result.set_source_text (l_source) end
            Result.set_modified (a_document.is_modified)
        ensure
            independent: Result /= a_document
            equivalent: Result.is_equal (a_document)
        end

feature {NONE} -- Matching

    cloned_counterpart (a_target, a_source, a_copy: TOMELLE_VALUE): detachable TOMELLE_VALUE
        local i: INTEGER
        do
            if a_source = a_target then Result := a_copy
            elseif attached {TOMELLE_TABLE} a_source as l_source_table and then
                attached {TOMELLE_TABLE} a_copy as l_copy_table then
                across l_source_table.entries as l_entry until Result /= Void loop
                    check attached l_copy_table [l_entry.key.value] as l_copy_value then
                        Result := cloned_counterpart (a_target, l_entry.value, l_copy_value)
                    end
                end
            elseif attached {TOMELLE_ARRAY} a_source as l_source_array and then
                attached {TOMELLE_ARRAY} a_copy as l_copy_array then
                from i := 1 until i > l_source_array.count or else Result /= Void loop
                    Result := cloned_counterpart (a_target, l_source_array [i], l_copy_array [i])
                    i := i + 1
                end
            end
        end

end

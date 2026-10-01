note
    description: "Physical, lossless representation owned by a TOML document."

class
    TOMELLE_DOCUMENT_REPRESENTATION

create
    make

feature {NONE} -- Initialization

    make
        do
            create internal_items.make (0)
        end

feature -- Access

    representation (a_root: TOMELLE_TABLE): STRING_32
        do
            if has_preserved_source (a_root) and then attached source_text as l_source then
                Result := l_source.twin
            else
                create Result.make_empty
                across internal_items as l_item loop Result.append (l_item.representation) end
            end
        end

    items: ITERABLE [TOMELLE_ITEM]
        do Result := internal_items end

    item_count: INTEGER
        do Result := internal_items.count end

    source_text: detachable STRING_32

    has_preserved_source (a_root: TOMELLE_TABLE): BOOLEAN
        do
            Result := attached source_text and then attached source_model_representation as l_original and then
                a_root.representation.same_string (l_original)
        end

feature -- Change

    append_item (a_item: TOMELLE_ITEM)
        do internal_items.extend (a_item) end

    set_source_text (a_source: READABLE_STRING_GENERAL; a_root: TOMELLE_TABLE)
        do
            source_text := a_source.as_string_32.twin
            source_model_representation := a_root.representation
        end

    replace_value (a_old, a_new: TOMELLE_VALUE)
        do
            across internal_items as l_item loop
                if attached {TOMELLE_ENTRY} l_item as l_entry and then l_entry.value = a_old then
                    l_entry.replace (a_new)
                end
            end
        end

    remove_value (a_value: TOMELLE_VALUE)
        do
            from internal_items.start until internal_items.after loop
                if attached {TOMELLE_ENTRY} internal_items.item as l_entry and then l_entry.value = a_value then
                    internal_items.remove
                else
                    internal_items.forth
                end
            end
        end

    wipe_out
        do
            internal_items.wipe_out
        end

    append_item_copy (a_item: TOMELLE_ITEM)
        local
            l_comment_copy: TOMELLE_COMMENT
            l_whitespace_copy: TOMELLE_WHITESPACE
            l_header_copy: TOMELLE_HEADER
        do
            if attached {TOMELLE_ENTRY} a_item as l_entry then
                internal_items.extend (l_entry.independent_copy)
            elseif attached {TOMELLE_COMMENT} a_item as l_comment then
                create l_comment_copy.make (l_comment.text)
                l_comment_copy.set_trivia (l_comment.trivia)
                internal_items.extend (l_comment_copy)
            elseif attached {TOMELLE_WHITESPACE} a_item as l_whitespace then
                create l_whitespace_copy.make (l_whitespace.text)
                l_whitespace_copy.set_trivia (l_whitespace.trivia)
                internal_items.extend (l_whitespace_copy)
            elseif attached {TOMELLE_HEADER} a_item as l_header then
                create l_header_copy.make (l_header.source, l_header.is_array)
                internal_items.extend (l_header_copy)
            end
        end

feature {NONE} -- Storage

    internal_items: ARRAYED_LIST [TOMELLE_ITEM]
    source_model_representation: detachable STRING_32

end

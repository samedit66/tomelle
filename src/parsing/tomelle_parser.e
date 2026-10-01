note
    description: "Stateless TOML parser returning an explicit outcome per call."

class
    TOMELLE_PARSER

create
    make,
    make_with_dependencies

feature -- Initialization

    make
        do
            create {TOMELLE_SOURCE_READER} source_reader
            create {TOMELLE_SOURCE_VALIDATOR} source_validator
            create {TOMELLE_DOCUMENT_BUILDING_POLICY} build_policy
        end

    make_with_dependencies (a_source_reader: TOMELLE_SOURCE_PROVIDER;
        a_source_validator: TOMELLE_SOURCE_VALIDATION_POLICY;
        a_build_policy: TOMELLE_DOCUMENT_BUILD_POLICY)
            -- Construct the parser with replaceable boundary policies.
        require
            source_reader_attached: a_source_reader /= Void
            source_validator_attached: a_source_validator /= Void
            build_policy_attached: a_build_policy /= Void
        do
            source_reader := a_source_reader
            source_validator := a_source_validator
            build_policy := a_build_policy
        end

feature -- Parsing

    parsed_string (a_source: READABLE_STRING_GENERAL): TOMELLE_PARSE_RESULT
        local
            l_source: STRING_32
        do
            if attached {STRING_32} a_source as l_string_32 then
                l_source := l_string_32
            else
                l_source := a_source.as_string_32
            end
            Result := parse_text (l_source, Void)
        end

    parsed_file (a_path: PATH): TOMELLE_PARSE_RESULT
        require
            path_not_empty: not a_path.is_empty
        local
            l_text: detachable STRING_32
            l_errors: TOMELLE_ERROR_COLLECTOR
            l_failed: BOOLEAN
        do
            if l_failed then
                create l_errors.make
                l_errors.add (error_codes.input_unreadable,
                    "Unable to read input file", a_path.name, 1, 1)
                create Result.make_failure (l_errors.errors)
            elseif source_reader.is_readable (a_path) then
                l_text := source_reader.decoded_file (a_path)
                if attached l_text as l_decoded then
                    Result := parse_text (l_decoded, a_path.name)
                else
                    create l_errors.make
                    l_errors.add (error_codes.invalid_utf_8,
                        "Input is not valid UTF-8", a_path.name, 1, 1)
                    create Result.make_failure (l_errors.errors)
                end
            else
                create l_errors.make
                l_errors.add (error_codes.input_unreadable,
                    "Input file is missing or unreadable", a_path.name, 1, 1)
                create Result.make_failure (l_errors.errors)
            end
        rescue
            l_failed := True
            retry
        end

feature -- Last outcome compatibility

    parse_string (a_source: READABLE_STRING_GENERAL)
            -- Parse into `last_result`; prefer stateless `parsed_string`.
        do
            last_result := parsed_string (a_source)
        end

    parse_file (a_path: PATH)
            -- Parse into `last_result`; prefer stateless `parsed_file`.
        require
            path_not_empty: not a_path.is_empty
        do
            last_result := parsed_file (a_path)
        end

    last_result: detachable TOMELLE_PARSE_RESULT

    is_parsed: BOOLEAN do Result := attached last_result end
    is_successful: BOOLEAN do Result := attached last_result as l_result and then l_result.is_successful end
    has_error: BOOLEAN do Result := attached last_result as l_result and then l_result.has_error end

    document: detachable TOMELLE_DOCUMENT
        do
            if attached last_result as l_result then Result := l_result.document end
        end

    error_count: INTEGER
        do
            if attached last_result as l_result then Result := l_result.error_count end
        end

    error (a_index: INTEGER): TOMELLE_PARSE_ERROR
        require valid_index: 1 <= a_index and a_index <= error_count
        do
            check attached last_result as l_result then Result := l_result.error (a_index) end
        end

    errors: ITERABLE [TOMELLE_PARSE_ERROR]
        do
            if attached last_result as l_result then
                Result := l_result.errors
            else
                create {ARRAYED_LIST [TOMELLE_PARSE_ERROR]} Result.make (0)
            end
        end

feature {NONE} -- Pipeline

    parse_text (a_source: STRING_32; a_source_name: detachable READABLE_STRING_GENERAL): TOMELLE_PARSE_RESULT
        local
            l_document: TOMELLE_DOCUMENT
            l_errors: TOMELLE_ERROR_COLLECTOR
        do
            create l_errors.make
            l_errors.set_source_name (a_source_name)
            create l_document.make
            if source_validator.is_valid (a_source) then
                build_policy.build (a_source, l_document, l_errors)
            else
                l_errors.add (error_codes.invalid_syntax,
                    "Invalid control character", Void, 1, 1)
            end
            if l_errors.has_error then
                create Result.make_failure (l_errors.errors)
            else
                create Result.make_success (l_document)
            end
        end

feature {NONE} -- Dependencies

    source_reader: TOMELLE_SOURCE_PROVIDER
    source_validator: TOMELLE_SOURCE_VALIDATION_POLICY
    build_policy: TOMELLE_DOCUMENT_BUILD_POLICY
    error_codes: TOMELLE_ERROR_CODE once create Result.default_create end

end

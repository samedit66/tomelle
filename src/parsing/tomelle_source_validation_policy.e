note
    description: "Abstraction for source-wide lexical validation."

deferred class
    TOMELLE_SOURCE_VALIDATION_POLICY

feature -- Validation

    is_valid (a_source: STRING_32): BOOLEAN
        deferred
        end

end

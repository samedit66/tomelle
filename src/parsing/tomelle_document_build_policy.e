note
    description: "Abstraction for constructing a document from parsed source."

deferred class
    TOMELLE_DOCUMENT_BUILD_POLICY

feature -- Building

    build (a_source: STRING_32; a_document: TOMELLE_DOCUMENT; a_errors: TOMELLE_ERROR_COLLECTOR)
        deferred
        end

end

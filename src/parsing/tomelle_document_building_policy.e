note
    description: "Default document-building policy adapter."

class
    TOMELLE_DOCUMENT_BUILDING_POLICY

inherit
    TOMELLE_DOCUMENT_BUILD_POLICY

feature -- Building

    build (a_source: STRING_32; a_document: TOMELLE_DOCUMENT; a_errors: TOMELLE_ERROR_COLLECTOR)
        local
            l_builder: TOMELLE_DOCUMENT_BUILDER
        do
            create l_builder.make (a_errors)
            l_builder.build (a_source, a_document)
        end

end

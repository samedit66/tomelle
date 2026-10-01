note
    description: "Abstraction for acquiring decoded TOML source."

deferred class
    TOMELLE_SOURCE_PROVIDER

feature -- Access

    is_readable (a_path: PATH): BOOLEAN
        deferred
        end

    decoded_file (a_path: PATH): detachable STRING_32
        deferred
        end

end

# Define Greenplum feature macros
#
function(define_greenplum_features IN_VERSION OUT_FEATURES)
    if(NOT ${IN_VERSION} VERSION_LESS "4.1")
        list(APPEND ${OUT_FEATURES} __HAS_ORDERED_AGGREGATES__)
    endif()

    if(NOT ${IN_VERSION} VERSION_LESS "4.3")
        list(APPEND ${OUT_FEATURES} __HAS_FUNCTION_PROPERTIES__)
    endif()

    # Pass values to caller
    set(${OUT_FEATURES} "${${OUT_FEATURES}}" PARENT_SCOPE)
endfunction(define_greenplum_features)

function(add_gppkg GPDB_VERSION GPDB_VARIANT GPDB_VARIANT_SHORT)
    file(WRITE "${CMAKE_BINARY_DIR}/deploy/gppkg/Version_${IN_PORT_VERSION}.cmake" "
    file(MAKE_DIRECTORY
        \"\${CMAKE_CURRENT_BINARY_DIR}/${IN_PORT_VERSION}/BUILD\"
        \"\${CMAKE_CURRENT_BINARY_DIR}/${IN_PORT_VERSION}/SPECS\"
        \"\${CMAKE_CURRENT_BINARY_DIR}/${IN_PORT_VERSION}/RPMS\"
        \"\${CMAKE_CURRENT_BINARY_DIR}/${IN_PORT_VERSION}/gppkg\"
    )
    set(GPDB_VERSION \"${GPDB_VERSION}\")
    set(GPDB_VARIANT \"${GPDB_VARIANT}\")
    set(GPDB_VARIANT_SHORT \"${GPDB_VARIANT_SHORT}\")

    configure_file(
        pdltools.spec.in
        \"\${CMAKE_CURRENT_BINARY_DIR}/${IN_PORT_VERSION}/SPECS/pdltools.spec\"
    )
    configure_file(
        gppkg_spec.yml.in
        \"\${CMAKE_CURRENT_BINARY_DIR}/${IN_PORT_VERSION}/gppkg/gppkg_spec.yml\"
    )
    if(GPPKG_BINARY AND RPMBUILD_BINARY)
        add_custom_target(gppkg_${PORT_VERSION_UNDERSCORE}
            COMMAND cmake -E create_symlink \"\${PDLTOOLS_GPPKG_RPM_SOURCE_DIR}\"
                \"\${CPACK_PACKAGE_FILE_NAME}-gppkg\"
            COMMAND \"\${RPMBUILD_BINARY}\" -bb SPECS/pdltools.spec
            COMMAND cmake -E rename "RPMS/\${PDLTOOLS_GPPKG_RPM_FILE_NAME}"
                "gppkg/\${PDLTOOLS_GPPKG_RPM_FILE_NAME}"
            COMMAND \"\${GPPKG_BINARY}\" --build gppkg
            DEPENDS \"${CMAKE_BINARY_DIR}/\${CPACK_PACKAGE_FILE_NAME}.rpm\"
            WORKING_DIRECTORY \"\${CMAKE_CURRENT_BINARY_DIR}/${IN_PORT_VERSION}\"
            COMMENT \"Generating Greenplum ${IN_PORT_VERSION} gppkg installer...\"
            VERBATIM
        )
    else(GPPKG_BINARY AND RPMBUILD_BINARY)
        add_custom_target(gppkg_${PORT_VERSION_UNDERSCORE}
            COMMAND cmake -E echo \"Could not find gppkg and/or rpmbuild.\"
                \"Please rerun cmake.\"
        )
    endif(GPPKG_BINARY AND RPMBUILD_BINARY)
    
    # Unfortunately, we cannot set a dependency to the built-in package target,
    # i.e., the following does not work:
    # add_dependencies(gppkg package)
    
    add_dependencies(gppkg gppkg_${PORT_VERSION_UNDERSCORE})
    ")
endfunction(add_gppkg)


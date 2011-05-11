LIST(LENGTH ALL_PUBLIC_HEADER_FILES LEN_HEADER_FILES)
MESSAGE(STATUS "Processing ToolKit: ${TOOLKIT} (${TOOLKIT_MODULES}) len = ${LEN_HEADER_FILES}")
SET(TOOLKIT_SOURCE_FILES)
SET(TOOLKIT_HEADER_FILES)
IF(DEFINED TOOLKIT_INCLUDE_DIRECTORIES)
	INCLUDE_DIRECTORIES(${TOOLKIT_INCLUDE_DIRECTORIES})
ENDIF(DEFINED TOOLKIT_INCLUDE_DIRECTORIES)
FOREACH(MODULE ${TOOLKIT_MODULES})
	SET(PUBLIC_HEADER_FILES)
	# add all .cxx/*.c files for each module
	FILE(GLOB SOURCE_FILES
		${${PROJECT_NAME}_SOURCE_DIR}/src/${MODULE}/*.cxx
		${${PROJECT_NAME}_SOURCE_DIR}/src/${MODULE}/*.c
		${${PROJECT_NAME}_SOURCE_DIR}/drv/${MODULE}/*.cxx
		${${PROJECT_NAME}_SOURCE_DIR}/drv/${MODULE}/*.c)

	# Makes the configure process really long
	STRING(REGEX MATCHALL "${${PROJECT_NAME}_SOURCE_DIR}/inc/${MODULE}[\\._]+[^;]*"  REGEX_RESULT "${ALL_PUBLIC_HEADER_FILES}")
	LIST(APPEND PUBLIC_HEADER_FILES ${REGEX_RESULT})
	STRING(REGEX MATCHALL "${${PROJECT_NAME}_SOURCE_DIR}/inc/Handle_${MODULE}[\\._]+[^;]*"  REGEX_RESULT "${ALL_PUBLIC_HEADER_FILES}")
	LIST(APPEND PUBLIC_HEADER_FILES ${REGEX_RESULT})
	LIST(LENGTH PUBLIC_HEADER_FILES LEN_HEADER_FILES)
	IF (${LEN_HEADER_FILES} GREATER 0)
		LIST(REMOVE_ITEM ALL_PUBLIC_HEADER_FILES ${PUBLIC_HEADER_FILES})
	ENDIF (${LEN_HEADER_FILES} GREATER 0)
	FILE(GLOB HEADER_FILES
		${${PROJECT_NAME}_SOURCE_DIR}/src/${MODULE}/*.hxx
		${${PROJECT_NAME}_SOURCE_DIR}/src/${MODULE}/*.lxx
		${${PROJECT_NAME}_SOURCE_DIR}/src/${MODULE}/*.gxx
		${${PROJECT_NAME}_SOURCE_DIR}/src/${MODULE}/*.h
		${${PROJECT_NAME}_SOURCE_DIR}/drv/${MODULE}/*.hxx
		${${PROJECT_NAME}_SOURCE_DIR}/drv/${MODULE}/*.ixx
		${${PROJECT_NAME}_SOURCE_DIR}/drv/${MODULE}/*.jxx
		${${PROJECT_NAME}_SOURCE_DIR}/drv/${MODULE}/*.h)

	IF (WIN32)
		# For compilers under Windows a define must be set per file to correctly set the export macro
		SET_SOURCE_FILES_PROPERTIES(${SOURCE_FILES} PROPERTIES COMPILE_FLAGS "-D__${MODULE}_DLL")
	ENDIF(WIN32)

	SOURCE_GROUP(${MODULE} FILES ${SOURCE_FILES})
	SOURCE_GROUP(${MODULE} FILES ${PUBLIC_HEADER_FILES} ${HEADER_FILES})

	# append these source files to the list of source files of the toolkit
	SET(TOOLKIT_SOURCE_FILES ${TOOLKIT_SOURCE_FILES} ${SOURCE_FILES})
	LIST(APPEND TOOLKIT_HEADER_FILES ${PUBLIC_HEADER_FILES} ${HEADER_FILES})
	# required include paths
	INCLUDE_DIRECTORIES(${${PROJECT_NAME}_SOURCE_DIR}/src/${MODULE} ${${PROJECT_NAME}_SOURCE_DIR}/drv/${MODULE})
ENDFOREACH(MODULE ${TOOLKIT_MODULES})
# To keep track of those files we have eliminated we must set the scope of this variable to PARENT_SCOPE
SET(ALL_PUBLIC_HEADER_FILES ${ALL_PUBLIC_HEADER_FILES} PARENT_SCOPE)
ADD_LIBRARY(${TOOLKIT} ${${PROJECT_NAME}_LIBRARY_TYPE} ${TOOLKIT_SOURCE_FILES} ${TOOLKIT_HEADER_FILES})
# TODO Add current toolkit header files into a source group?
# Add target specific locations of *.lxx and *.ixx files
SET_TARGET_PROPERTIES(${TOOLKIT} PROPERTIES
	SOVERSION ${${PROJECT_NAME}_ABI_SOVERSION}
	VERSION ${${PROJECT_NAME}_ABI_VERSION}
)

# Set dependencies for thit ToolKit
IF ( NOT "${TOOLKIT}" STREQUAL "TKernel" )
	LIST(REMOVE_DUPLICATES TOOLKIT_DEPENDS)
ENDIF ( NOT "${TOOLKIT}" STREQUAL "TKernel" )
TARGET_LINK_LIBRARIES(${TOOLKIT} ${TOOLKIT_DEPENDS} ${TOOLKIT_LIBS} ${WIN32_LIBS})

IF(TOOLKIT_LIBS_OPTIMIZED)
	FOREACH(lib ${TOOLKIT_LIBS_OPTIMIZED})
		TARGET_LINK_LIBRARIES(${TOOLKIT} optimized ${lib})
	ENDFOREACH(lib ${TOOLKIT_LIBS_OPTIMIZED})
ENDIF(TOOLKIT_LIBS_OPTIMIZED)

IF(TOOLKIT_LIBS_DEBUG)
	FOREACH(lib ${TOOLKIT_LIBS_DEBUG})
		TARGET_LINK_LIBRARIES(${TOOLKIT} debug ${lib})
	ENDFOREACH(lib ${TOOLKIT_LIBS_DEBUG})
ENDIF(TOOLKIT_LIBS_DEBUG)

IF(TOOLKIT_DEPENDS)
	ADD_DEPENDENCIES(${TOOLKIT} ${TOOLKIT_DEPENDS})
ENDIF(TOOLKIT_DEPENDS)

###########
# INSTALL #
###########
SET(TOOLKIT_INSTALL_BIN_DIR ${${PROJECT_NAME}_INSTALL_BIN_DIR})

IF(CMAKE_CONFIGURATION_TYPES)
	SET(TOOLKIT_INSTALL_BIN_DEBUG_DIR ${${PROJECT_NAME}_INSTALL_BIN_DEBUG_DIR})
ENDIF(CMAKE_CONFIGURATION_TYPES)	

IF(TOOLKIT_IS_PRIVATE)
	SET(TOOLKIT_INSTALL_LIB_DIR ${${PROJECT_NAME}_INSTALL_PACKAGE_LIB_DIR})
	IF(CMAKE_CONFIGURATION_TYPES)
		SET(TOOLKIT_INSTALL_LIB_DEBUG_DIR ${${PROJECT_NAME}_INSTALL_PACKAGE_LIB_DEBUG_DIR})
	ENDIF(CMAKE_CONFIGURATION_TYPES)	
ELSE(TOOLKIT_IS_PRIVATE)
	SET(TOOLKIT_INSTALL_LIB_DIR ${${PROJECT_NAME}_INSTALL_LIB_DIR})
	IF(CMAKE_CONFIGURATION_TYPES)
		SET(TOOLKIT_INSTALL_LIB_DEBUG_DIR ${${PROJECT_NAME}_INSTALL_PACKAGE_LIB_DEBUG_DIR})
	ENDIF(CMAKE_CONFIGURATION_TYPES)
	SET_TARGET_PROPERTIES(${TOOLKIT} PROPERTIES INSTALL_RPATH "${${PROJECT_NAME}_INSTALL_LIB_DIR}")
ENDIF(TOOLKIT_IS_PRIVATE)

IF(WIN32 AND CMAKE_CONFIGURATION_TYPES)
	# In win32 put the .dll in the bin folder
	INSTALL(TARGETS ${TOOLKIT} EXPORT ${PROJECT_NAME}-targets
		RUNTIME DESTINATION ${TOOLKIT_INSTALL_BIN_DIR} CONFIGURATIONS Release RelWithDebInfo MinSizeRel COMPONENT RuntimeLibraries
		LIBRARY DESTINATION ${TOOLKIT_INSTALL_LIB_DIR} CONFIGURATIONS Release RelWithDebInfo MinSizeRel COMPONENT RuntimeLibraries
		ARCHIVE DESTINATION ${TOOLKIT_INSTALL_LIB_DIR} CONFIGURATIONS Release RelWithDebInfo MinSizeRel COMPONENT Development
		)
	INSTALL(TARGETS ${TOOLKIT} EXPORT ${PROJECT_NAME}-targets
		RUNTIME DESTINATION ${TOOLKIT_INSTALL_BIN_DEBUG_DIR} CONFIGURATIONS "Debug" COMPONENT RuntimeLibraries
		LIBRARY DESTINATION ${TOOLKIT_INSTALL_LIB_DEBUG_DIR} CONFIGURATIONS "Debug" COMPONENT RuntimeLibraries
		ARCHIVE DESTINATION ${TOOLKIT_INSTALL_LIB_DEBUG_DIR} CONFIGURATIONS "Debug" COMPONENT Development
		)
		
	IF(MSVC AND ${PROJECT_NAME}_INSTALL_PDB_FILES )
		INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/RelWithDebInfo/${TOOLKIT}.pdb DESTINATION ${TOOLKIT_INSTALL_LIB_DIR} CONFIGURATIONS RelWithDebInfo)
		INSTALL(FILES ${CMAKE_CURRENT_BINARY_DIR}/Debug/${TOOLKIT}${CMAKE_DEBUG_POSTFIX}.pdb DESTINATION ${TOOLKIT_INSTALL_LIB_DEBUG_DIR} CONFIGURATIONS Debug)
	ENDIF(MSVC AND ${PROJECT_NAME}_INSTALL_PDB_FILES )
ELSE(WIN32 AND CMAKE_CONFIGURATION_TYPES)
	INSTALL(TARGETS ${TOOLKIT} EXPORT ${PROJECT_NAME}-targets
		RUNTIME DESTINATION ${TOOLKIT_INSTALL_BIN_DIR} COMPONENT RuntimeLibraries
		LIBRARY DESTINATION ${TOOLKIT_INSTALL_LIB_DIR} COMPONENT RuntimeLibraries
		ARCHIVE DESTINATION ${TOOLKIT_INSTALL_LIB_DIR} COMPONENT Development
		)
ENDIF(WIN32 AND CMAKE_CONFIGURATION_TYPES)




# Distributed under "The Unlicense" License. See http://unlicense.org/ for details.

#.rst:
# FindACIS
# --------
#
# CMake module to find Spatial Corp.'s 3D ACIS Modeler Solid Modeling Kernel includes and libraries
#
# Author:
#   Onur Rauf Bingol (orbingol@gmail.com)
#
# Variables for User Override:
#   ACIS_ROOT               - Users can set this variable to ACIS root directory to make CMake path finding process easy
#
# Advanced Variables:
#   ACIS_INCLUDE_DIR        - Directory containing the ACIS headers
#   ACIS_LIBRARY_RELEASE    - Directory containing the release version of the ACIS library
#   ACIS_LIBRARY_DEBUG      - Directory containing the debug version of the ACIS library
#
# Basic Variables:
#   ACIS_FOUND              - TRUE if ACIS library is found by this CMake module
#   ACIS_INCLUDE_DIRS       - Points to the location of ACIS headers. Use it with include_directories()
#   ACIS_LIBRARIES          - Points to the debug and release version of ACIS dynamic libraries
#   ACIS_LINK_LIBRARIES     - This variable points tp both ACIS and Threads libraries (ACIS requires Threads library to run)
#
#   ACIS_REDIST_DEBUG       - Points to the SpaACISd.dll file
#   ACIS_REDIST_RELEASE     - Points to the SpaACIS.dll / libSpaACIS.so file
#


#
# Pre-processing
#

# Load required CMake modules
include( SelectLibraryConfigurations )
include( FindPackageHandleStandardArgs )
include( CMakeFindDependencyMacro OPTIONAL RESULT_VARIABLE _CMakeFDM_Found )

# Required CMake Flags when NOT using Visual Studio
if( NOT MSVC )
  set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11" )
endif()

#
# Set up the paths
#

# Prepare library search paths
set( _ACIS_SEARCH_PATHS )

# Users can set ACIS_ROOT before calling find_package() for custom ACIS install directories
if( ACIS_ROOT )
  set( _ACIS_SEARCH_ROOT PATHS ${ACIS_ROOT} NO_DEFAULT_PATH )
  list( APPEND _ACIS_SEARCH_PATHS _ACIS_SEARCH_ROOT )
endif()

# Use the environmental variable A3DT to find ACIS path
if( DEFINED ENV{A3DT} )
  set( _ACIS_SEARCH_NORMAL PATHS "$ENV{A3DT}" )
  list( APPEND _ACIS_SEARCH_PATHS _ACIS_SEARCH_NORMAL )
endif()

# Use some approximated directories to find ACIS path
set( _ACIS_SEARCH_HINTDIRS
    "$ENV{PROGRAMFILES}/Spatial/acis"
    "/opt/acis"
    "/opt/r26" # for ACIS R26
    "/opt/2017" # for ACIS R2017
    "/opt/2018" # for ACIS R2018
    "/opt/20" # for ACIS R20xx
    )
foreach( hintdir ${_ACIS_SEARCH_HINTDIRS} )
  file( GLOB acisdirs ${hintdir} ${hintdir}*/ )
  foreach( dir ${acisdirs} )
    if( IS_DIRECTORY ${dir} )
      set( _ACIS_SEARCH_HINTPATH PATHS ${dir} )
      list( APPEND _ACIS_SEARCH_PATHS _ACIS_SEARCH_HINTPATH )
    endif()
  endforeach()
endforeach()

#
# Find ACIS headers
#

# Loop through the search paths to find "acis.hxx" header file
foreach( search ${_ACIS_SEARCH_PATHS} )
  find_path( ACIS_INCLUDE_DIR NAMES acis.hxx ${${search}} PATH_SUFFIXES include )
endforeach()

# Set INCLUDE_DIRS variable
set( ACIS_INCLUDE_DIRS ${ACIS_INCLUDE_DIR} )

# Get ACIS root directory and use it to find ARCH and libraries
get_filename_component( _ACIS_ROOT_DIR ${ACIS_INCLUDE_DIR} PATH )

#
# Find ACIS architecture (ARCH)
#

# If ARCH is set, use it by default
if( DEFINED ENV{ARCH} )
  set( ACIS_ARCH "$ENV{ARCH}" )
else()
  # If no environmental variables are set for ACIS ARCH, try to find it manually
  if( WIN32 )
    file( GLOB acisarchs RELATIVE ${_ACIS_ROOT_DIR} "${_ACIS_ROOT_DIR}/NT_VC*DLL" )
    foreach( arch ${acisarchs} )
      if( IS_DIRECTORY ${_ACIS_ROOT_DIR}/${arch} )
        set( ACIS_ARCH ${arch} )
      endif()
    endforeach()
  endif()
  if( UNIX AND NOT APPLE )
    set( ACIS_ARCH "linux_a64" )
  endif()
  if( APPLE )
    set( ACIS_ARCH "macos_b64" )
  endif()
endif()

# Use ACIS ARCH as the version string
set( ACIS_VERSION_STRING ${ACIS_ARCH} )

#
# Find ACIS library
#

# Note: ACIS_LIBRARY is set by SELECT_LIBRARY_CONFIGURATIONS()
if( NOT ACIS_LIBRARY )
  find_library( ACIS_LIBRARY_DEBUG NAMES SpaACISd PATHS ${_ACIS_ROOT_DIR} PATH_SUFFIXES ${ACIS_ARCH}D/code/lib ${ACIS_ARCH}/code/bin )
  find_library( ACIS_LIBRARY_RELEASE NAMES SpaACIS PATHS ${_ACIS_ROOT_DIR} PATH_SUFFIXES ${ACIS_ARCH}/code/lib ${ACIS_ARCH}/code/bin )
endif()

# Use SELECT_LIBRARY_CONFIGURATIONS() to find the debug and optimized ACIS library
select_library_configurations( ACIS )

#
# Find other required packages and libraries
#

# Process components
if( ACIS_FIND_COMPONENTS )
  foreach( component ${ACIS_FIND_COMPONENTS} )
    string( TOUPPER ${component} _COMPONENT )
    set( ACIS_USE_${_COMPONENT} ON )
  endforeach()
endif()


# Find "3D ACIS-HOOPS Bridge" component bundled with the ACIS package
if( ACIS_USE_HBRIDGE )
  # Note: ACIS_HBRIDGE_LIBRARY is set by SELECT_LIBRARY_CONFIGURATIONS()
  if( NOT ACIS_HBRIDGE_LIBRARY )
    find_library( ACIS_HBRIDGE_LIBRARY_DEBUG NAMES SpaHBridged PATHS ${_ACIS_ROOT_DIR} PATH_SUFFIXES ${ACIS_ARCH}D/code/lib ${ACIS_ARCH}/code/bin )
    find_library( ACIS_HBRIDGE_LIBRARY_RELEASE NAMES SpaHBridge PATHS ${_ACIS_ROOT_DIR} PATH_SUFFIXES ${ACIS_ARCH}/code/lib ${ACIS_ARCH}/code/bin )
  endif()

  # Use SELECT_LIBRARY_CONFIGURATIONS() to find the debug and optimized DLLs
  select_library_configurations( ACIS_HBRIDGE )

  # This is required by FPHSA()
  if( ACIS_HBRIDGE_LIBRARY AND ACIS_INCLUDE_DIR )
    set( ACIS_HBRIDGE_FOUND ON )
  endif()

  # These are some internal variables and they should be muted
  mark_as_advanced(
      ACIS_HBRIDGE_LIBRARY_RELEASE
      ACIS_HBRIDGE_LIBRARY_DEBUG
  )
endif()

# Find "Precise Hidden Line Removal V5" component bundled with the ACIS package
if( ACIS_USE_PHLV5 )
  # Note: ACIS_PHLV5_LIBRARY is set by SELECT_LIBRARY_CONFIGURATIONS()
  if( NOT ACIS_PHLV5_LIBRARY )
    find_library( ACIS_PHLV5_LIBRARY_DEBUG NAMES SpaPhlV5d PATHS ${_ACIS_ROOT_DIR} PATH_SUFFIXES ${ACIS_ARCH}D/code/lib ${ACIS_ARCH}/code/bin )
    find_library( ACIS_PHLV5_LIBRARY_RELEASE NAMES SpaPhlV5 PATHS ${_ACIS_ROOT_DIR} PATH_SUFFIXES ${ACIS_ARCH}/code/lib ${ACIS_ARCH}/code/bin )
  endif()

  # Use SELECT_LIBRARY_CONFIGURATIONS() to find the debug and optimized DLLs
  select_library_configurations( ACIS_PHLV5 )

  # This is required by FPHSA()
  if( ACIS_PHLV5_LIBRARY AND ACIS_INCLUDE_DIR )
    set( ACIS_PHLV5_FOUND ON )
  endif()

  # These are some internal variables and they should be muted
  mark_as_advanced(
      ACIS_PHLV5_LIBRARY_RELEASE
      ACIS_PHLV5_LIBRARY_DEBUG
  )
endif()

# Find "Defeaturing" component bundled with the ACIS package
if( ACIS_USE_DEFEATURE )
  # Note: ACIS_DEFEATURE_LIBRARY is set by SELECT_LIBRARY_CONFIGURATIONS()
  if( NOT ACIS_DEFEATURE_LIBRARY )
    find_library( ACIS_DEFEATURE_LIBRARY_DEBUG NAMES SPADefeatured PATHS ${_ACIS_ROOT_DIR} PATH_SUFFIXES ${ACIS_ARCH}D/code/lib ${ACIS_ARCH}/code/bin )
    find_library( ACIS_DEFEATURE_LIBRARY_RELEASE NAMES SPADefeature PATHS ${_ACIS_ROOT_DIR} PATH_SUFFIXES ${ACIS_ARCH}/code/lib ${ACIS_ARCH}/code/bin )
  endif()

  # Use SELECT_LIBRARY_CONFIGURATIONS() to find the debug and optimized DLLs
  select_library_configurations( ACIS_DEFEATURE )

  # This is required by FPHSA()
  if( ACIS_DEFEATURE_LIBRARY AND ACIS_INCLUDE_DIR )
    set( ACIS_DEFEATURE_FOUND ON )
  endif()

  # These are some internal variables and they should be muted
  mark_as_advanced(
      ACIS_DEFEATURE_LIBRARY_RELEASE
      ACIS_DEFEATURE_LIBRARY_DEBUG
  )
endif()

# Find "Advanced Deformable Modeling" component bundled with the ACIS package
if( ACIS_USE_ADMHUSK )
  # Note: ACIS_ADMHUSK_LIBRARY is set by SELECT_LIBRARY_CONFIGURATIONS()
  if( NOT ACIS_ADMHUSK_LIBRARY )
    find_library( ACIS_ADMHUSK_LIBRARY_DEBUG NAMES admhuskd PATHS ${_ACIS_ROOT_DIR} PATH_SUFFIXES ${ACIS_ARCH}D/code/lib ${ACIS_ARCH}/code/bin )
    find_library( ACIS_ADMHUSK_LIBRARY_RELEASE NAMES admhusk PATHS ${_ACIS_ROOT_DIR} PATH_SUFFIXES ${ACIS_ARCH}/code/lib ${ACIS_ARCH}/code/bin )
  endif()

  # Use SELECT_LIBRARY_CONFIGURATIONS() to find the debug and optimized DLLs
  select_library_configurations( ACIS_ADMHUSK )

  # This is required by FPHSA()
  if( ACIS_ADMHUSK_LIBRARY AND ACIS_INCLUDE_DIR )
    set( ACIS_ADMHUSK_FOUND ON )
  endif()

  # These are some internal variables and they should be muted
  mark_as_advanced(
      ACIS_ADMHUSK_LIBRARY_RELEASE
      ACIS_ADMHUSK_LIBRARY_DEBUG
  )
endif()

#
# Post-processing
#
find_package_handle_standard_args(
    ACIS
    FOUND_VAR ACIS_FOUND
    REQUIRED_VARS ACIS_LIBRARIES ACIS_INCLUDE_DIR
    HANDLE_COMPONENTS
    FAIL_MESSAGE "Cannot find ACIS!"
)

if( ACIS_FOUND )
  # ACIS requires the Threads library with we might need some extra tricks for older CMake versions
  enable_language( C )
  if( _CMakeFDM_FOUND )
    find_dependency( Threads REQUIRED )
  else()
    find_package( Threads REQUIRED )
  endif()

  # Add imported targets - 3D ACIS Modeler
  if( NOT TARGET ACIS::ACIS )
    add_library( ACIS::ACIS UNKNOWN IMPORTED )
    set_target_properties( ACIS::ACIS PROPERTIES
        INTERFACE_LINK_LIBRARIES "Threads::Threads" )
    if( ACIS_INCLUDE_DIRS )
      set_target_properties( ACIS::ACIS PROPERTIES
          INTERFACE_INCLUDE_DIRECTORIES "${ACIS_INCLUDE_DIRS}" )
    endif()
    if( EXISTS "${ACIS_LIBRARY}" )
      set_target_properties( ACIS::ACIS PROPERTIES
          IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
          IMPORTED_LOCATION "${ACIS_LIBRARY}" )
    endif()
    if( EXISTS "${ACIS_LIBRARY_RELEASE}" )
      set_property( TARGET ACIS::ACIS APPEND PROPERTY
          IMPORTED_CONFIGURATIONS RELEASE )
      set_target_properties( ACIS::ACIS PROPERTIES
          IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
          IMPORTED_LOCATION_RELEASE "${ACIS_LIBRARY_RELEASE}" )
    endif()
    if( EXISTS "${ACIS_LIBRARY_DEBUG}" )
      set_property( TARGET ACIS::ACIS APPEND PROPERTY
          IMPORTED_CONFIGURATIONS DEBUG )
      set_target_properties( ACIS::ACIS PROPERTIES
          IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "CXX"
          IMPORTED_LOCATION_DEBUG "${ACIS_LIBRARY_DEBUG}" )
    endif()
  endif()

  # Add imported targets - 3D ACIS-HOOPS Bridge
  if( ACIS_HBRIDGE_FOUND )
    if( NOT TARGET ACIS::HBRIDGE )
      add_library( ACIS::HBRIDGE UNKNOWN IMPORTED )
      set_target_properties( ACIS::HBRIDGE PROPERTIES
          INTERFACE_LINK_LIBRARIES "ACIS::ACIS" )
      if( ACIS_INCLUDE_DIRS )
        set_target_properties( ACIS::HBRIDGE PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${ACIS_INCLUDE_DIRS}" )
      endif()
      if( EXISTS "${ACIS_HBRIDGE_LIBRARY}" )
        set_target_properties( ACIS::HBRIDGE PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
            IMPORTED_LOCATION "${ACIS_HBRIDGE_LIBRARY}" )
      endif()
      if( EXISTS "${ACIS_HBRIDGE_LIBRARY_RELEASE}" )
        set_property( TARGET ACIS::HBRIDGE APPEND PROPERTY
            IMPORTED_CONFIGURATIONS RELEASE )
        set_target_properties( ACIS::HBRIDGE PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
            IMPORTED_LOCATION_RELEASE "${ACIS_HBRIDGE_LIBRARY_RELEASE}" )
      endif()
      if( EXISTS "${ACIS_HBRIDGE_LIBRARY_DEBUG}" )
        set_property( TARGET ACIS::HBRIDGE APPEND PROPERTY
            IMPORTED_CONFIGURATIONS DEBUG )
        set_target_properties( ACIS::HBRIDGE PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "CXX"
            IMPORTED_LOCATION_DEBUG "${ACIS_HBRIDGE_LIBRARY_DEBUG}" )
      endif()
    endif()
  endif()

  # Add imported targets - Precise Hidden Line Removal V5
  if( ACIS_PHLV5_FOUND )
    if( NOT TARGET ACIS::PHLV5 )
      add_library( ACIS::PHLV5 UNKNOWN IMPORTED )
      set_target_properties( ACIS::PHLV5 PROPERTIES
          INTERFACE_LINK_LIBRARIES "ACIS::ACIS" )
      if( ACIS_INCLUDE_DIRS )
        set_target_properties( ACIS::PHLV5 PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${ACIS_INCLUDE_DIRS}" )
      endif()
      if( EXISTS "${ACIS_PHLV5_LIBRARY}" )
        set_target_properties( ACIS::PHLV5 PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
            IMPORTED_LOCATION "${ACIS_PHLV5_LIBRARY}" )
      endif()
      if( EXISTS "${ACIS_PHLV5_LIBRARY_RELEASE}" )
        set_property( TARGET ACIS::PHLV5 APPEND PROPERTY
            IMPORTED_CONFIGURATIONS RELEASE )
        set_target_properties( ACIS::PHLV5 PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
            IMPORTED_LOCATION_RELEASE "${ACIS_PHLV5_LIBRARY_RELEASE}" )
      endif()
      if( EXISTS "${ACIS_PHLV5_LIBRARY_DEBUG}" )
        set_property( TARGET ACIS::PHLV5 APPEND PROPERTY
            IMPORTED_CONFIGURATIONS DEBUG )
        set_target_properties( ACIS::PHLV5 PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "CXX"
            IMPORTED_LOCATION_DEBUG "${ACIS_PHLV5_LIBRARY_DEBUG}" )
      endif()
    endif()
  endif()

  # Add imported targets - Defeaturing
  if( ACIS_DEFEATURE_FOUND )
    if( NOT TARGET ACIS::DEFEATURE )
      add_library( ACIS::DEFEATURE UNKNOWN IMPORTED )
      set_target_properties( ACIS::DEFEATURE PROPERTIES
          INTERFACE_LINK_LIBRARIES "ACIS::ACIS" )
      if( ACIS_INCLUDE_DIRS )
        set_target_properties( ACIS::DEFEATURE PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${ACIS_INCLUDE_DIRS}" )
      endif()
      if( EXISTS "${ACIS_DEFEATURE_LIBRARY}" )
        set_target_properties( ACIS::DEFEATURE PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
            IMPORTED_LOCATION "${ACIS_DEFEATURE_LIBRARY}" )
      endif()
      if( EXISTS "${ACIS_DEFEATURE_LIBRARY_RELEASE}" )
        set_property( TARGET ACIS::DEFEATURE APPEND PROPERTY
            IMPORTED_CONFIGURATIONS RELEASE )
        set_target_properties( ACIS::DEFEATURE PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
            IMPORTED_LOCATION_RELEASE "${ACIS_DEFEATURE_LIBRARY_RELEASE}" )
      endif()
      if( EXISTS "${ACIS_DEFEATURE_LIBRARY_DEBUG}" )
        set_property( TARGET ACIS::DEFEATURE APPEND PROPERTY
            IMPORTED_CONFIGURATIONS DEBUG )
        set_target_properties( ACIS::DEFEATURE PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "CXX"
            IMPORTED_LOCATION_DEBUG "${ACIS_DEFEATURE_LIBRARY_DEBUG}" )
      endif()
    endif()
  endif()

  # Add imported targets - Advanced Deformable Modeling
  if( ACIS_ADMHUSK_FOUND )
    if( NOT TARGET ACIS::ADMHUSK )
      add_library( ACIS::ADMHUSK UNKNOWN IMPORTED )
      set_target_properties( ACIS::ADMHUSK PROPERTIES
          INTERFACE_LINK_LIBRARIES "ACIS::ACIS" )
      if( ACIS_INCLUDE_DIRS )
        set_target_properties( ACIS::ADMHUSK PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${ACIS_INCLUDE_DIRS}" )
      endif()
      if( EXISTS "${ACIS_ADMHUSK_LIBRARY}" )
        set_target_properties( ACIS::ADMHUSK PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
            IMPORTED_LOCATION "${ACIS_ADMHUSK_LIBRARY}" )
      endif()
      if( EXISTS "${ACIS_ADMHUSK_LIBRARY_RELEASE}" )
        set_property( TARGET ACIS::ADMHUSK APPEND PROPERTY
            IMPORTED_CONFIGURATIONS RELEASE )
        set_target_properties( ACIS::ADMHUSK PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
            IMPORTED_LOCATION_RELEASE "${ACIS_ADMHUSK_LIBRARY_RELEASE}" )
      endif()
      if( EXISTS "${ACIS_ADMHUSK_LIBRARY_DEBUG}" )
        set_property( TARGET ACIS::ADMHUSK APPEND PROPERTY
            IMPORTED_CONFIGURATIONS DEBUG )
        set_target_properties( ACIS::ADMHUSK PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "CXX"
            IMPORTED_LOCATION_DEBUG "${ACIS_ADMHUSK_LIBRARY_DEBUG}" )
      endif()
    endif()
  endif()
endif()

# Set a variable to be used for linking ACIS and Threads to the project
set( ACIS_LINK_LIBRARIES ${ACIS_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT} )

if( ACIS_HBRIDGE_FOUND )
  set( ACIS_LINK_LIBRARIES ${ACIS_LINK_LIBRARIES} ${ACIS_HBRIDGE_LIBRARIES} )
endif()

if( ACIS_PHLV5_FOUND )
  set( ACIS_LINK_LIBRARIES ${ACIS_LINK_LIBRARIES} ${ACIS_PHLV5_LIBRARIES} )
endif()

if( ACIS_DEFEATURE_FOUND )
  set( ACIS_LINK_LIBRARIES ${ACIS_LINK_LIBRARIES} ${ACIS_DEFEATURE_LIBRARIES} )
endif()

if( ACIS_ADMHUSK_FOUND )
  set( ACIS_LINK_LIBRARIES ${ACIS_LINK_LIBRARIES} ${ACIS_ADMHUSK_LIBRARIES} )
endif()

# Set somes variables which point to the ACIS dynamic libraries (.dll/.so)
if( WIN32 )
  # ACIS itself
  set( ACIS_REDIST_DEBUG ${_ACIS_ROOT_DIR}/${ACIS_ARCH}D/code/bin/SpaACISd.dll )
  set( ACIS_REDIST_RELEASE ${_ACIS_ROOT_DIR}/${ACIS_ARCH}/code/bin/SpaACIS.dll )
  # 3D ACIS-HOOPS Bridge
  if( ACIS_HBRIDGE_FOUND )
    # TO-DO: We might need to add the HOOPS DLL file to the list
    set( ACIS_REDIST_DEBUG ${ACIS_REDIST_DEBUG} ${_ACIS_ROOT_DIR}/${ACIS_ARCH}D/code/bin/SpaHBridged.dll )
    set( ACIS_REDIST_RELEASE ${ACIS_REDIST_RELEASE} ${_ACIS_ROOT_DIR}/${ACIS_ARCH}D/code/bin/SpaHBridge.dll )
  endif()
  # Precise Hidden Line Removal
  if( ACIS_PHLV5_FOUND )
    set( ACIS_REDIST_DEBUG ${ACIS_REDIST_DEBUG} ${_ACIS_ROOT_DIR}/${ACIS_ARCH}D/code/bin/SpaPhlV5d.dll )
    set( ACIS_REDIST_RELEASE ${ACIS_REDIST_RELEASE} ${_ACIS_ROOT_DIR}/${ACIS_ARCH}D/code/bin/SpaPhlV5.dll )
  endif()
  # Defeaturing
  if( ACIS_DEFEATURE_FOUND )
    set( ACIS_REDIST_DEBUG ${ACIS_REDIST_DEBUG} ${_ACIS_ROOT_DIR}/${ACIS_ARCH}D/code/bin/SpaDefeatured.dll )
    set( ACIS_REDIST_RELEASE ${ACIS_REDIST_RELEASE} ${_ACIS_ROOT_DIR}/${ACIS_ARCH}D/code/bin/SpaDefeature.dll )
  endif()
  # Defeaturing
  if( ACIS_ADMHUSK_FOUND )
    set( ACIS_REDIST_DEBUG ${ACIS_REDIST_DEBUG} ${_ACIS_ROOT_DIR}/${ACIS_ARCH}D/code/bin/admhuskd.dll )
    set( ACIS_REDIST_RELEASE ${ACIS_REDIST_RELEASE} ${_ACIS_ROOT_DIR}/${ACIS_ARCH}D/code/bin/admhusk.dll )
  endif()
else()
  # Setting these variables for install is unnecessary due to the working priciples of non-Windows systems
  set( ACIS_REDIST_DEBUG "" )
  set( ACIS_REDIST_RELEASE "" )
endif()

# These are some internal variables and they should be muted
mark_as_advanced(
    ACIS_ARCH
    ACIS_LIBRARY_RELEASE
    ACIS_LIBRARY_DEBUG
    ACIS_INCLUDE_DIR
)

# Unset the temporary variables
unset( _ACIS_SEARCH_ROOT )
unset( _ACIS_SEARCH_NORMAL )
unset( _ACIS_SEARCH_PATHS )
unset( _ACIS_SEARCH_HINTDIRS )
unset( _ACIS_ROOT_DIR )

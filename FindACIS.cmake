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
include( CMakeFindDependencyMacro )

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
  # ACIS requires the Threads library
  find_dependency( Threads REQUIRED )

  set( ACIS_INCLUDE_DIRS ${ACIS_INCLUDE_DIR} )
  # Set a variable to be used for linking ACIS and Threads to the project
  set( ACIS_LINK_LIBRARIES ${ACIS_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT} )
  # Set somes variables which point to the ACIS dynamic libraries (.dll/.so)
  if( WIN32 )
    set( ACIS_REDIST_DEBUG ${_ACIS_ROOT_DIR}/${ACIS_ARCH}D/code/bin/SpaACISd.dll )
    set( ACIS_REDIST_RELEASE ${_ACIS_ROOT_DIR}/${ACIS_ARCH}/code/bin/SpaACIS.dll )
  else()
    # Only Windows version of ACIS has DEBUG libraries
    set( ACIS_REDIST_DEBUG ${_ACIS_ROOT_DIR}/${ACIS_ARCH}/code/bin/libSpaACIS.so )
    set( ACIS_REDIST_RELEASE ${_ACIS_ROOT_DIR}/${ACIS_ARCH}/code/bin/libSpaACIS.so )
  endif()
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

# Custom CMake Modules

This repository contains the following [CMake](https://cmake.org/) modules:

* __findACIS__: Finds libraries and headers for building applications which use [Spatial Corporation](https://www.spatial.com/)'s 3D ACIS Modeler

## Usage Examples

### findACIS:

* Create directory `<project_root>/cmake-modules` and  `findACIS.cmake` in this directory
* Alternatively, you can clone this repository directly in your `<project_root>`
* Use the following (or modify it for your needs) in your `CMakeLists.txt` file

```
cmake_minimum_required ( VERSION 2.8 )
project ( MyACISApp )

# Extend CMake module path for loading custom modules
set ( CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_LIST_DIR}/cmake-modules" )

# findACIS module accepts a parameter for processing additional search paths
set ( ACIS_ROOT "/opt" CACHE PATH "3D ACIS Modeler custom install path." )

# Find 3D ACIS Modeler headers and libraries
find_package ( ACIS REQUIRED )

# Check if CMake has found libraries and headers for 3D ACIS Modeler
if ( ACIS_FOUND )
  include_directories(${ACIS_INCLUDE_DIRS})
  # We don't need ACIS_ROOT variable anymore
  unset(ACIS_ROOT)
  unset(ACIS_ROOT CACHE)
else ()
  message(FATAL_ERROR "ACIS not found")
endif ()
```

ACIS requires the Threads library. To link both ACIS and the Threads library:

```
target_link_libraries ( MyACISApp ${ACIS_LINK_LIBRARIES} )
```

It is also possible to generate INSTALL rules as descibed below:

```
# Install ACIS Release .DLL/.SO to the application install directory
install (
  FILES ${ACIS_REDIST_RELEASE}
  DESTINATION ${APP_INSTALL_DIR}
  CONFIGURATIONS Release RelWithDebInfo MinSizeRel
)

# Install ACIS Debug .DLL/.SO to to the application install directory
install (
  FILES ${ACIS_REDIST_DEBUG}
  DESTINATION ${APP_INSTALL_DIR}
  CONFIGURATIONS Debug
)
```

## License

[The Unlicense](LICENSE)

## Author

* Onur Rauf Bingol (contact@onurbingol.net)

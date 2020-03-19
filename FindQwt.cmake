# Qt Widgets for Technical Applications
# available at http://qwt.sourceforge.net/
#
# The module defines the following variables:
#  QWT_FOUND - the system has Qwt
#  QWT_INCLUDE_DIR - where to find qwt_plot.h
#  QWT_INCLUDE_DIRS - qwt includes
#  QWT_QWT_LIBRARY - where to find the Qwt library
#  QWT_MATHML_LIBRARY - where to find Mathml library
#  QWT_LIBRARIES - aditional libraries
#  QWT_MAJOR_VERSION - major version
#  QWT_MINOR_VERSION - minor version
#  QWT_PATCH_VERSION - patch version
#  QWT_VERSION_STRING - version (ex. 5.2.1)
#  QWT_ROOT_DIR - root directory of Qwt installation

set(QWT_ROOT_DIR ${CONAN_QWT_ROOT})

find_path(QWT_INCLUDE_DIR NAMES qwt_plot.h PATHS ${CONAN_INCLUDE_DIRS_QWT})

set(QWT_INCLUDE_DIRS ${QWT_INCLUDE_DIR})

#-------------------------------- Extract version --------------------------------------------------

set(_VERSION_FILE ${QWT_INCLUDE_DIR}/qwt_global.h)
if(EXISTS ${_VERSION_FILE})
    file(STRINGS ${_VERSION_FILE} _VERSION_LINE REGEX "define[ ]+QWT_VERSION_STR")
    if(_VERSION_LINE)
        string (REGEX REPLACE ".*define[ ]+QWT_VERSION_STR[ ]+\"(.*)\".*" "\\1" QWT_VERSION_STRING "${_VERSION_LINE}")
        string (REGEX REPLACE "([0-9]+)\\.([0-9]+)\\.([0-9]+)" "\\1" QWT_MAJOR_VERSION "${QWT_VERSION_STRING}")
        string (REGEX REPLACE "([0-9]+)\\.([0-9]+)\\.([0-9]+)" "\\2" QWT_MINOR_VERSION "${QWT_VERSION_STRING}")
        string (REGEX REPLACE "([0-9]+)\\.([0-9]+)\\.([0-9]+)" "\\3" QWT_PATCH_VERSION "${QWT_VERSION_STRING}")
    endif()
endif()

#-------------------------------- Check version ----------------------------------------------------

set(_QWT_VERSION_MATCH TRUE)
if(Qwt_FIND_VERSION AND QWT_VERSION_STRING)
    if(Qwt_FIND_VERSION_EXACT)
        if(NOT Qwt_FIND_VERSION VERSION_EQUAL QWT_VERSION_STRING)
            set(_QWT_VERSION_MATCH FALSE)
        endif()
    else()
        if(QWT_VERSION_STRING VERSION_LESS Qwt_FIND_VERSION)
            set(_QWT_VERSION_MATCH FALSE)
        endif()
    endif()
endif()

#-------------------------------- Find library files -----------------------------------------------

find_library(QWT_QWT_LIBRARY 
  NAMES qwt 
  PATHS ${CONAN_LIB_DIRS_QWT}
  PATH_SUFFIXES lib
)

find_library(QWT_MATHML_LIBRARY 
  NAMES qwtmathml 
  PATHS ${CONAN_LIB_DIRS_QWT}
  PATH_SUFFIXES lib
)

set(QWT_LIBRARIES ${QWT_QWT_LIBRARY} ${QWT_MATHML_LIBRARY})

#-------------------------------- Set component status ---------------------------------------------

if(NOT "${Qwt_FIND_COMPONENTS}")
    # Add default component
    set("${Qwt_FIND_COMPONENTS}" "Qwt")
endif()

set(_qwt_component_required_vars)

foreach(_comp ${Qwt_FIND_COMPONENTS})

    if ("${_comp}" STREQUAL "Qwt")
        list(APPEND _qwt_component_required_vars ${QWT_QWT_LIBRARY})
        if (QWT_INCLUDE_DIR AND EXISTS "${QWT_QWT_LIBRARY}")
            set(Qwt_Qwt_FOUND TRUE)
        else()
            set(Qwt_Qwt_FOUND False)
        endif()
        
    elseif("${_comp}" STREQUAL "Mathml")
        list(APPEND _qwt_component_required_vars ${QWT_MATHML_LIBRARY})
        if (QWT_INCLUDE_DIR AND EXISTS "${QWT_QWT_LIBRARY}" AND EXISTS "${QWT_MATHML_LIBRARY}")
            set(Qwt_Mathml_FOUND TRUE)
        else()
            set(Qwt_Mathml_FOUND False)
        endif()    
    
    else()
        message(WARNING "${_comp} is not a recognized Qwt component")
        set(Qwt_${_comp}_FOUND FALSE)
    endif()
endforeach()

#-------------------------------- Handle find_package() arguments ----------------------------------

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Qwt
    REQUIRED_VARS _qwt_component_required_vars
    VERSION_VAR QWT_VERSION_STRING
    HANDLE_COMPONENTS
)

#-------------------------------- Export found libraries as imported targets -----------------------

if(Qwt_Qwt_FOUND AND NOT TARGET Qwt::Qwt)
    add_library(Qwt::Qwt INTERFACE IMPORTED)
    set_target_properties(Qwt::Qwt PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${QWT_INCLUDE_DIRS}"
        INTERFACE_LINK_LIBRARIES "${QWT_QWT_LIBRARY}"
    )
endif()

if(Qwt_Mathml_FOUND AND NOT TARGET Qwt::Mathml)
    add_library(Qwt::Mathml INTERFACE IMPORTED)
    set_target_properties(Qwt::Qwt PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${QWT_INCLUDE_DIRS}"
        INTERFACE_LINK_LIBRARIES "${QWT_QWT_LIBRARY} ${QWT_MATHML_LIBRARY}"
    )
endif()

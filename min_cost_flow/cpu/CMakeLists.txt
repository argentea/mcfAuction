# required cmake version
cmake_minimum_required(VERSION 2.8)

set(PROJECT_NAME "cpulb")
project(${PROJECT_NAME})

set(EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/bin)
set(PROJECT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})


if (CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX_DIR ${CMAKE_INSTALL_PREFIX})
else()
  set(CMAKE_INSTALL_PREFIX_DIR ${CMAKE_CURRENT_SOURCE_DIR}/install)
endif()
message(STATUS "Install Prefix: ${CMAKE_INSTALL_PREFIX}")
unset(CMAKE_INSTALL_PREFIX)


# deal with GCC dual ABI issue 
if(NOT CMAKE_CXX_ABI)
    set(CMAKE_CXX_ABI 0 CACHE STRING
        "Choose the value for _GLIBCXX_USE_CXX11_ABI, options are: 0|1."
        FORCE)
endif(NOT CMAKE_CXX_ABI)
message(STATUS "CMAKE_CXX_ABI: _GLIBCXX_USE_CXX11_ABI=${CMAKE_CXX_ABI}")
add_definitions(-D_GLIBCXX_USE_CXX11_ABI=${CMAKE_CXX_ABI})


set(LEMON_DIR "/home/yuanzhou/mcfAuction/LEMON")
if (LEMON_DIR)
  set(LEMON_ROOT_DIR ${LEMON_DIR})
else()
  set(LEMON_ROOT_DIR $ENV{LEMON_DIR})
endif()
message(STATUS "Find Lemon: ${LEMON_ROOT_DIR}")
unset(LEMON_DIR CACHE)

set(CMAKE_CXX_FLAGS "-std=c++14 -Wall -fPIC")
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -fno-inline ")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")
set(CMAKE_CXX_FLAGS_PROFILE "-O3 -pg -Winline")
set(CMAKE_CXX_STANDARD 14)


#Print out the used build type
IF(CMAKE_BUILD_TYPE MATCHES Debug)
    message(STATUS "Using build type DEBUG")
    #ENDIF(CMAKE_BUILD_TYPE MATCHES Debug)
ELSEIF(CMAKE_BUILD_TYPE MATCHES Release)
    message(STATUS "Using build type RELEASE")
    #ENDIF(CMAKE_BUILD_TYPE MATCHES Release)
ELSEIF(CMAKE_BUILD_TYPE MATCHES Profile)
    message(STATUS "Using build type PROFILE")
    #ENDIF(CMAKE_BUILD_TYPE MATCHES Profile)
ELSE()
    message(STATUS "Using build type DEFAULT: using Release flag")
    set(CMAKE_BUILD_TYPE Release)
ENDIF()


file(GLOB_RECURSE CURRENT_HEADERS  *.h)
file(GLOB CURRENT_SOURCES *.cpp)
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${LEMON_ROOT_DIR}/install/include
)


add_library(${PROJECT_NAME} STATIC ${CURRENT_HEADERS} ${CURRENT_SOURCES})



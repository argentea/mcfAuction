cmake_minimum_required(VERSION 2.8...3.12)

set(PROJECT_NAME "mcf")
project(${PROJECT_NAME})

INCLUDE(FindPythonInterp)
set(MIN_COST_FLOW "/home/yuanzhou/mcfAuction")
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/bin)
set(PROJECT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)

if (CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX_DIR ${CMAKE_INSTALL_PREFIX})
else()
  set(CMAKE_INSTALL_PREFIX_DIR ${CMAKE_CURRENT_SOURCE_DIR}/install)
endif()
message(STATUS "Install Prefix: ${CMAKE_INSTALL_PREFIX}")
unset(CMAKE_INSTALL_PREFIX)

find_package(CUDA REQUIRED)
message(STATUS "Find CUDA: ${CUDA_FOUND}")

set(LEMON_DIR "/home/yuanzhou/mcfAuction")
if (LEMON_DIR)
  set(LEMON_ROOT_DIR ${LEMON_DIR})
else()
  set(LEMON_ROOT_DIR $ENV{LEMON_DIR})
endif()
message(STATUS "Find Lemon: ${LEMON_ROOT_DIR}")
unset(LEMON_DIR CACHE)

#set(CUDA_DIR "/usr/local/cuda-10.1/bin")
#if (CUDA_DIR)
#    set(CUDA_ROOT_DIR ${CUDA_DIR})
#else()
#    set(CUDA_ROOT_DIR $ENV{CUDA_DIR})
#endif()
#message(STATUS "Find CUDA: ${CUDA_ROOT_DIR}")
#unset(CUDA_DIR CACHE)



IF(CMAKE_BUILD_TYPE MATCHES Debug)
    message(STATUS "using build type DEBUG")
ELSEIF(CMAKE_BUILD_TYPE MATCHES Release)
    message(STATUS "Using build type DEBUG")
ELSEIF(CMAKE_BUILD_TYPE MATCHES Profile)
    message(STATUS "Using build type PROFILE")
    #ENDIF(CMAKE_BUILD_TYPE MATCHES Profile)
ELSE()
    message(STATUS "Using build type DEFAULT: using Release flag")
    set(CMAKE_BUILD_TYPE Release)
ENDIF()

set(CMAKE_CXX_FLAGS "-std=c++14 -Wall -fPIC")
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -fno-inline ")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")
set(CMAKE_CXX_FLAGS_PROFILE "-O3 -pg -Winline")
set(CMAKE_CXX_STANDARD 14)
set(CUDA_NVCC_FLAGS -std=c++14)


add_subdirectory("/home/yuanzhou/mcfAuction/min_cost_flow/gpu" "./build")
#add_subdirectory("min_cost_flow/cpu")
include_directories("/usr/local/cuda/lib64")
#include_directories("min_cost_flow/gpu")

#set(SRC min_cost_flow/cpu/auction.cpp min_cost_flow/smartdigraph.cpp)
file(GLOB SOURCE test.cpp)
file(GLOB EXE_SOURCE ${MIN_COST_FLOW}/min_cost_flow/cpu/* ${MIN_COST_FLOW}/min_cost_flow/gpu/* ${MIN_COST_FLOW}/min_cost_flow/lgf_api/*)

#set(SRC min_cost_flow/smartdigraph.cpp)
#set(SRC_EXE test/test.cpp)


set (EXTRA_LIBS ${EXTRA_LIBS} gpulb)
include_directories(
    ${MIN_COST_FLOW}/LEMON/install/include
    ${MIN_COST_FLOW}/include
    ${MIN_COST_FLOW}/min_cost_flow/gpu
    ${MIN_COST_FLOW}/min_cost_flow/lgf_api
)

add_executable(${PROJECT_NAME} ${SOURCE} ${EXE_SOURCE})
target_link_libraries(
    ${PROJECT_NAME}
    ${EXTRA_LIBS}
)


#install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_PREFIX_DIR}/bin)    

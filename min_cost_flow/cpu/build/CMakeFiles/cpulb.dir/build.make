# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.10

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/yuanzhou/mcfAuction/src/cpu

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/yuanzhou/mcfAuction/src/cpu/build

# Include any dependencies generated for this target.
include CMakeFiles/cpulb.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/cpulb.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/cpulb.dir/flags.make

CMakeFiles/cpulb.dir/auction.cpp.o: CMakeFiles/cpulb.dir/flags.make
CMakeFiles/cpulb.dir/auction.cpp.o: ../auction.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/yuanzhou/mcfAuction/src/cpu/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/cpulb.dir/auction.cpp.o"
	/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/cpulb.dir/auction.cpp.o -c /home/yuanzhou/mcfAuction/src/cpu/auction.cpp

CMakeFiles/cpulb.dir/auction.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/cpulb.dir/auction.cpp.i"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/yuanzhou/mcfAuction/src/cpu/auction.cpp > CMakeFiles/cpulb.dir/auction.cpp.i

CMakeFiles/cpulb.dir/auction.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/cpulb.dir/auction.cpp.s"
	/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/yuanzhou/mcfAuction/src/cpu/auction.cpp -o CMakeFiles/cpulb.dir/auction.cpp.s

CMakeFiles/cpulb.dir/auction.cpp.o.requires:

.PHONY : CMakeFiles/cpulb.dir/auction.cpp.o.requires

CMakeFiles/cpulb.dir/auction.cpp.o.provides: CMakeFiles/cpulb.dir/auction.cpp.o.requires
	$(MAKE) -f CMakeFiles/cpulb.dir/build.make CMakeFiles/cpulb.dir/auction.cpp.o.provides.build
.PHONY : CMakeFiles/cpulb.dir/auction.cpp.o.provides

CMakeFiles/cpulb.dir/auction.cpp.o.provides.build: CMakeFiles/cpulb.dir/auction.cpp.o


# Object files for target cpulb
cpulb_OBJECTS = \
"CMakeFiles/cpulb.dir/auction.cpp.o"

# External object files for target cpulb
cpulb_EXTERNAL_OBJECTS =

libcpulb.a: CMakeFiles/cpulb.dir/auction.cpp.o
libcpulb.a: CMakeFiles/cpulb.dir/build.make
libcpulb.a: CMakeFiles/cpulb.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/yuanzhou/mcfAuction/src/cpu/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX static library libcpulb.a"
	$(CMAKE_COMMAND) -P CMakeFiles/cpulb.dir/cmake_clean_target.cmake
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/cpulb.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/cpulb.dir/build: libcpulb.a

.PHONY : CMakeFiles/cpulb.dir/build

CMakeFiles/cpulb.dir/requires: CMakeFiles/cpulb.dir/auction.cpp.o.requires

.PHONY : CMakeFiles/cpulb.dir/requires

CMakeFiles/cpulb.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/cpulb.dir/cmake_clean.cmake
.PHONY : CMakeFiles/cpulb.dir/clean

CMakeFiles/cpulb.dir/depend:
	cd /home/yuanzhou/mcfAuction/src/cpu/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/yuanzhou/mcfAuction/src/cpu /home/yuanzhou/mcfAuction/src/cpu /home/yuanzhou/mcfAuction/src/cpu/build /home/yuanzhou/mcfAuction/src/cpu/build /home/yuanzhou/mcfAuction/src/cpu/build/CMakeFiles/cpulb.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/cpulb.dir/depend


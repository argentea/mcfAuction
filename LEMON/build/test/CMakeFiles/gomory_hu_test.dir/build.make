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
CMAKE_SOURCE_DIR = /home/yuanzhou/mcfAuction/LEMON

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/yuanzhou/mcfAuction/LEMON/build

# Include any dependencies generated for this target.
include test/CMakeFiles/gomory_hu_test.dir/depend.make

# Include the progress variables for this target.
include test/CMakeFiles/gomory_hu_test.dir/progress.make

# Include the compile flags for this target's objects.
include test/CMakeFiles/gomory_hu_test.dir/flags.make

test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o: test/CMakeFiles/gomory_hu_test.dir/flags.make
test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o: ../test/gomory_hu_test.cc
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/yuanzhou/mcfAuction/LEMON/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o"
	cd /home/yuanzhou/mcfAuction/LEMON/build/test && /usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o -c /home/yuanzhou/mcfAuction/LEMON/test/gomory_hu_test.cc

test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.i"
	cd /home/yuanzhou/mcfAuction/LEMON/build/test && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/yuanzhou/mcfAuction/LEMON/test/gomory_hu_test.cc > CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.i

test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.s"
	cd /home/yuanzhou/mcfAuction/LEMON/build/test && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/yuanzhou/mcfAuction/LEMON/test/gomory_hu_test.cc -o CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.s

test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o.requires:

.PHONY : test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o.requires

test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o.provides: test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o.requires
	$(MAKE) -f test/CMakeFiles/gomory_hu_test.dir/build.make test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o.provides.build
.PHONY : test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o.provides

test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o.provides.build: test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o


# Object files for target gomory_hu_test
gomory_hu_test_OBJECTS = \
"CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o"

# External object files for target gomory_hu_test
gomory_hu_test_EXTERNAL_OBJECTS =

test/gomory_hu_test: test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o
test/gomory_hu_test: test/CMakeFiles/gomory_hu_test.dir/build.make
test/gomory_hu_test: lemon/libemon.a
test/gomory_hu_test: test/CMakeFiles/gomory_hu_test.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/yuanzhou/mcfAuction/LEMON/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX executable gomory_hu_test"
	cd /home/yuanzhou/mcfAuction/LEMON/build/test && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/gomory_hu_test.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
test/CMakeFiles/gomory_hu_test.dir/build: test/gomory_hu_test

.PHONY : test/CMakeFiles/gomory_hu_test.dir/build

test/CMakeFiles/gomory_hu_test.dir/requires: test/CMakeFiles/gomory_hu_test.dir/gomory_hu_test.cc.o.requires

.PHONY : test/CMakeFiles/gomory_hu_test.dir/requires

test/CMakeFiles/gomory_hu_test.dir/clean:
	cd /home/yuanzhou/mcfAuction/LEMON/build/test && $(CMAKE_COMMAND) -P CMakeFiles/gomory_hu_test.dir/cmake_clean.cmake
.PHONY : test/CMakeFiles/gomory_hu_test.dir/clean

test/CMakeFiles/gomory_hu_test.dir/depend:
	cd /home/yuanzhou/mcfAuction/LEMON/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/yuanzhou/mcfAuction/LEMON /home/yuanzhou/mcfAuction/LEMON/test /home/yuanzhou/mcfAuction/LEMON/build /home/yuanzhou/mcfAuction/LEMON/build/test /home/yuanzhou/mcfAuction/LEMON/build/test/CMakeFiles/gomory_hu_test.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : test/CMakeFiles/gomory_hu_test.dir/depend


cmake_minimum_required(VERSION 2.4.6)
include($ENV{ROS_ROOT}/core/rosbuild/rosbuild.cmake)
# FindPkgConfig was introduced after 2.4.6, so we provide a copy of it
#include(FindPkgConfig)
include($ENV{ROS_ROOT}/core/rosbuild/FindPkgConfig.cmake)

set(ROS_BUILD_TYPE RelWithDebInfo)
#set(ROS_BUILD_TYPE Debug)

rospack(ogre_tools)

rospack_add_boost_directories()

#set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)
set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/lib)

find_package(wxWidgets REQUIRED)
include(${wxWidgets_USE_FILE})
include_directories( ${wxWidgets_INCLUDE_DIRS} )

if(NOT wxWidgets_FOUND)
message("wxWidgets not found!  Aborting...")
fail()
endif(NOT wxWidgets_FOUND)

find_package(PythonLibs REQUIRED)
include_directories(${PYTHON_INCLUDE_PATH})

# The versioned check apparently doesn't work.  So we'll check the version
# manually
pkg_check_modules(OGRE OGRE=1.6)
if(OGRE_VERSION STREQUAL "1.6")
  include_directories( ${OGRE_INCLUDE_DIRS} )
  link_directories( ${OGRE_LIBRARY_DIRS} )
  message("Found OGRE: ${OGRE_VERSION}")
  add_definitions("-DHAS_INSTALLED_OGRE")
else(OGRE_VERSION STREQUAL "1.6")
  message("Didn't find OGRE 1.6")
endif(OGRE_VERSION STREQUAL "1.6")

# We need GTK2 and OpenGL for the wx render window
pkg_check_modules(GTK2 gtk+-2.0)

include_directories( ${GTK2_INCLUDE_DIRS} )
add_definitions( ${GTK2_DEFINITIONS} )
link_directories( ${GTK2_LIBRARY_DIRS} )

find_package(OpenGL REQUIRED)
include_directories( ${OPENGL_INCLUDE_DIR} )

# Find the combined swig flags for this project
_rospack_invoke(${PROJECT_NAME} ${PROJECT_NAME} SWIG_FLAGS "export" "--lang=swig" "--attrib=flags")
set(SWIG_FLAGS ${${PROJECT_NAME}_SWIG_FLAGS})

# Find the wxswig executable
find_ros_package(wxswig)
set(WXSWIG_EXECUTABLE ${wxswig_PACKAGE_PATH}/bin/swig)

# Add a custom command for generating the swig output files
set(SWIG_INTERFACE_FILE ${PROJECT_SOURCE_DIR}/src/ogre_tools/ogre_tools.i)
set(SWIG_OUTPUT_PYTHON_FILE ${PROJECT_SOURCE_DIR}/lib/ogre_tools.py)

# Deal with CMake 2.4 vs. 2.6
if("${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}" GREATER 2.4)   # CMake 2.6
  set(SWIG_OUTPUT_CPP_FILE ${PROJECT_SOURCE_DIR}/src/ogre_tools/ogre_tools_swig_generated.cpp)
  set(SWIG_COMMAND ${WXSWIG_EXECUTABLE} ${SWIG_FLAGS} -o ${SWIG_OUTPUT_CPP_FILE} -outdir ../lib -module ${PROJECT_NAME} ${SWIG_INTERFACE_FILE})
else("${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}" GREATER 2.4)    # CMake 2.4
  set(SWIG_OUTPUT_CPP_FILE src/ogre_tools/ogre_tools_swig_generated.cpp)
  set(SWIG_COMMAND ${WXSWIG_EXECUTABLE} ${SWIG_FLAGS} -o ../${SWIG_OUTPUT_CPP_FILE} -outdir ../lib -module ${PROJECT_NAME} ${SWIG_INTERFACE_FILE})
endif("${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}" GREATER 2.4)

set_source_files_properties(${SWIG_OUTPUT_CPP_FILE} PROPERTIES GENERATED true)
add_custom_command(OUTPUT   ${SWIG_OUTPUT_CPP_FILE} 
                            ${SWIG_OUTPUT_PYTHON_FILE}
                   COMMAND  ${SWIG_COMMAND}
                   DEPENDS  ${SWIG_INTERFACE_FILE}
                   src/ogre_tools/initialization.i
                   src/ogre_tools/initialization.h)

# We add src/ogre_tools to the include list so that
# ogre_tools_swig_generated.cpp can find its headers.  This is part of a
# workaround for a deficiency in CMake 2.4's handling of generated sources.
include_directories(${PROJECT_SOURCE_DIR}/src/ogre_tools)

# We make one library with the basic C++ code...
rospack_add_library(${PROJECT_NAME} src/ogre_tools/point_cloud.cpp
            src/ogre_tools/object.cpp
            src/ogre_tools/shape.cpp
			      src/ogre_tools/grid.cpp
			      src/ogre_tools/arrow.cpp
			      src/ogre_tools/axes.cpp
			      src/ogre_tools/billboard_line.cpp
			      src/ogre_tools/camera_base.cpp
			      src/ogre_tools/fps_camera.cpp
			      src/ogre_tools/orbit_camera.cpp
			      src/ogre_tools/ortho_camera.cpp
			      src/ogre_tools/movable_text.cpp
			      src/ogre_tools/wx_ogre_render_window.cpp
			      src/ogre_tools/initialization.cpp
			      src/ogre_tools/orthographic.cpp
			      src/ogre_tools/stl_loader.cpp)

# make sure we set the gl and glu libraries only if they are avilable
set(OGRE_TOOLS_GL_LIBS "")
if(OPENGL_gl_LIBRARY)
  set(OGRE_TOOLS_GL_LIBS ${OGRE_TOOLS_GL_LIBS} ${OPENGL_gl_LIBRARY})
endif(OPENGL_gl_LIBRARY)
if(OPENGL_glu_LIBRARY)
  set(OGRE_TOOLS_GL_LIBS ${OGRE_TOOLS_GL_LIBS} ${OPENGL_glu_LIBRARY})
endif(OPENGL_glu_LIBRARY)

target_link_libraries(${PROJECT_NAME} ${wxWidgets_LIBRARIES} ${GTK2_LIBRARIES} ${OGRE_TOOLS_GL_LIBS} ${OGRE_LIBRARIES})

# ...and we make another library with just the SWIG wrappers, linked
# against the C++ lib.
rospack_add_library(python_${PROJECT_NAME} ${SWIG_OUTPUT_CPP_FILE})
target_link_libraries(python_${PROJECT_NAME} ${PROJECT_NAME} ${PYTHON_LIBRARIES})

# swig python needs a shared library named _<modulename>.[so|dll|...]
# this renames the output file to conform to that by prepending an underscore and removing the "lib" prefix
set_target_properties(python_${PROJECT_NAME}
                      PROPERTIES OUTPUT_NAME _${PROJECT_NAME}
                      PREFIX "")

rospack_add_executable(bin/grid_test EXCLUDE_FROM_ALL src/test/grid_test.cpp)
target_link_libraries(bin/grid_test ${PROJECT_NAME} ${wxWidgets_LIBRARIES})
rospack_declare_test(bin/grid_test)

include_directories(src)
rospack_add_executable(bin/stl_to_mesh src/stl_to_mesh/stl_to_mesh.cpp)
target_link_libraries(bin/stl_to_mesh ${OGRE_LIBRARIES} ${PROJECT_NAME})
rospack_link_boost(bin/stl_to_mesh filesystem system)

rospack_add_gtest_future(test/utest test/utest.cpp)
target_link_libraries(test/utest ${PROJECT_NAME})

######################
# For inclusion in ROS
######################

# Return a list of all msg/.msg files
set(GENERATED_MSG_FILES "")

macro(add_generated_msg)
  list(APPEND GENERATED_MSG_FILES ${ARGV})
endmacro(add_generated_msg)

macro(get_msgs msgvar)
  file(GLOB _msg_files RELATIVE "${PROJECT_SOURCE_DIR}/msg" "${PROJECT_SOURCE_DIR}/msg/*.msg")
  set(${msgvar} ${GENERATED_MSG_FILES})
  # Loop over each .msg file, establishing a rule to compile it
  foreach(_msg ${_msg_files})
    # Make sure we didn't get a bogus match (e.g., .#Foo.msg, which Emacs
    # might create as a temporary file).  the file()
    # command doesn't take a regular expression, unfortunately.
    if(${_msg} MATCHES "^[^\\.].*\\.msg$")
      list(APPEND ${msgvar} ${_msg})
    endif(${_msg} MATCHES "^[^\\.].*\\.msg$")
  endforeach(_msg)
endmacro(get_msgs)

# Return a list of all srv/.srv files
set(GENERATED_SRV_FILES "")

macro(add_generated_srv)
  list(APPEND GENERATED_SRV_FILES ${ARGV})
endmacro(add_generated_srv)

macro(get_srvs srvvar)
  file(GLOB _srv_files RELATIVE "${PROJECT_SOURCE_DIR}/srv" "${PROJECT_SOURCE_DIR}/srv/*.srv")
  set(${srvvar} ${GENERATED_SRV_FILES})
  # Loop over each .srv file, establishing a rule to compile it
  foreach(_srv ${_srv_files})
    message("get_srvs processing:" ${_srv})
    # Make sure we didn't get a bogus match (e.g., .#Foo.srv, which Emacs
    # might create as a temporary file).  the file()
    # command doesn't take a regular expression, unfortunately.
    if(${_srv} MATCHES "^[^\\.].*\\.srv$")
      list(APPEND ${srvvar} ${_srv})
    endif(${_srv} MATCHES "^[^\\.].*\\.srv$")
  endforeach(_srv)
endmacro(get_srvs)

##########################
# End For inclusion in ROS
##########################

###############################
# For Deletion once ROS updates
###############################

macro(genmsg_cpp)
  get_msgs(_msglist)
  set(_autogen "")
  foreach(_msg ${_msglist})
    # Construct the path to the .msg file
    set(_input ${PROJECT_SOURCE_DIR}/msg/${_msg})
  
    gendeps(${PROJECT_NAME} ${_msg})
  
    set(genmsg_cpp_exe ${genmsg_cpp_PACKAGE_PATH}/genmsg)

    set(_output_cpp ${PROJECT_SOURCE_DIR}/msg/cpp/${PROJECT_NAME}/${_msg})
    string(REPLACE ".msg" ".h" _output_cpp ${_output_cpp})
  
    # Add the rule to build the .h the .msg
    add_custom_command(OUTPUT ${_output_cpp} 
                       COMMAND ${genmsg_cpp_exe} ${_input}
                       DEPENDS ${_input} ${genmsg_cpp_exe} ${gendeps_exe} ${${PROJECT_NAME}_${_msg}_GENDEPS} ${ROS_MANIFEST_LIST})
    list(APPEND _autogen ${_output_cpp})
  endforeach(_msg)
  # Create a target that depends on the union of all the autogenerated
  # files
  add_custom_target(ROSBUILD_genmsg_cpp_hack DEPENDS ${_autogen})
  # Add our target to the top-level genmsg target, which will be fired if
  # the user calls genmsg()
  add_dependencies(rospack_genmsg ROSBUILD_genmsg_cpp_hack)
endmacro(genmsg_cpp)

macro(gensrv_cpp)
  get_srvs(_srvlist)
  set(_autogen "")
  foreach(_srv ${_srvlist})
    message("gensrv_cpp processing:" ${_srv})
    # Construct the path to the .srv file
    set(_input ${PROJECT_SOURCE_DIR}/srv/${_srv})
  
    gendeps(${PROJECT_NAME} ${_srv})
  
    set(gensrv_cpp_exe ${genmsg_cpp_PACKAGE_PATH}/gensrv)

    set(_output_cpp ${PROJECT_SOURCE_DIR}/srv/cpp/${PROJECT_NAME}/${_srv})
    string(REPLACE ".srv" ".h" _output_cpp ${_output_cpp})
  
    # Add the rule to build the .h from the .srv
    add_custom_command(OUTPUT ${_output_cpp} 
                       COMMAND ${gensrv_cpp_exe} ${_input}
                       DEPENDS ${_input} ${gensrv_cpp_exe} ${gendeps_exe} ${${PROJECT_NAME}_${_srv}_GENDEPS} ${ROS_MANIFEST_LIST})
    list(APPEND _autogen ${_output_cpp})
  endforeach(_srv)
  # Create a target that depends on the union of all the autogenerated
  # files
  add_custom_target(ROSBUILD_gensrv_cpp_hack DEPENDS ${_autogen})
  # Add our target to the top-level gensrv target, which will be fired if
  # the user calls gensrv()
  message("MSG: Adding dependency of rospack_gensrv on:" ${_autogen})
  add_dependencies(rospack_gensrv ROSBUILD_gensrv_cpp_hack ${_autogen})
endmacro(gensrv_cpp)


###################################
# End For Deletion once ROS updates
###################################

# Return a list of all cfg/.cfg files
set(GENERATED_CFG_FILES "")

macro(add_generated_cfg)
  list(APPEND GENERATED_CFG_FILES ${ARGV})
endmacro(add_generated_cfg)

macro(get_cfgs cfgvar)
  file(GLOB _cfg_files RELATIVE "${PROJECT_SOURCE_DIR}/cfg" "${PROJECT_SOURCE_DIR}/cfg/*.cfg")
  set(${cfgvar} ${GENERATED_CFG_FILES})
  # Loop over each .cfg file, establishing a rule to compile it
  foreach(_cfg ${_cfg_files})
    # Make sure we didn't get a bogus match (e.g., .#Foo.cfg, which Emacs
    # might create as a temporary file).  the file()
    # command doesn't take a regular expression, unfortunately.
    if(${_cfg} MATCHES "^[^\\.].*\\.cfg$")
      list(APPEND ${cfgvar} ${_cfg})
    endif(${_cfg} MATCHES "^[^\\.].*\\.cfg$")
  endforeach(_cfg)
endmacro(get_cfgs)

add_custom_target(rospack_gencfg ALL)

macro(gencfg)
  add_custom_target(rospack_gencfg_real ALL)
  add_dependencies(rospack_gencfg_real rospack_gencfg)
  # Need to do cfg then msg then srv.
  add_dependencies(rospack_genmsg rospack_gencfg)
  add_dependencies(rospack_gensrv rospack_genmsg)
  include_directories(${PROJECT_SOURCE_DIR}/cfg/cpp)
endmacro(gencfg)

find_ros_package(dynamic_reconfigure)

macro(gencfg_cpp)
  get_cfgs(_cfglist)
  set(_autogen "")
  foreach(_cfg ${_cfglist})
    message("MSG: gencfg_cpp on:" ${_cfg})
    # Construct the path to the .cfg file
    set(_input ${PROJECT_SOURCE_DIR}/cfg/${_cfg})
  
    gendeps(${PROJECT_NAME} ${_cfg})
  
    # The .cfg file is its own generator.
    set(gencfg_cpp_exe "")
    set(gencfg_build_files ${dynamic_reconfigure_PACKAGE_PATH}/templates/ConfigReconfigurator.h
      ${dynamic_reconfigure_PACKAGE_PATH}/src/dynamic_reconfigure/parameter_generator.py)

    string(REPLACE ".cfg" "" _cfg_bare ${_cfg})

    set(_output_cpp ${PROJECT_SOURCE_DIR}/cfg/cpp/${PROJECT_NAME}/${_cfg_bare}Reconfigurator.h)
    set(_output_msg ${PROJECT_SOURCE_DIR}/msg/${_cfg_bare}Config.msg)
    set(_output_getsrv ${PROJECT_SOURCE_DIR}/srv/Get${_cfg_bare}Config.srv)
    set(_output_setsrv ${PROJECT_SOURCE_DIR}/srv/Set${_cfg_bare}Config.srv)
    set(_output_dox ${PROJECT_SOURCE_DIR}/dox/${_cfg_bare}Config.dox)
    set(_output_usage ${PROJECT_SOURCE_DIR}/dox/${_cfg_bare}Config-usage.dox)
  
    # Indicate the msg and srv files that will get generated.
    string(REPLACE ${PROJECT_SOURCE_DIR}/msg/ "" _output_msg_name ${_output_msg})
    string(REPLACE ${PROJECT_SOURCE_DIR}/srv/ "" _output_getsrv_name ${_output_getsrv})
    string(REPLACE ${PROJECT_SOURCE_DIR}/srv/ "" _output_setsrv_name ${_output_setsrv})
    add_generated_msg(${_output_msg_name})
    add_generated_srv(${_output_setsrv_name} ${_output_getsrv_name})

    # Add the rule to build the .h the .cfg and the .msg
    # FIXME Horrible hack. Can't get CMAKE to add dependencies for anything
    # but the first output in add_custom_command.
    add_custom_command(OUTPUT ${_output_msg} ${_output_cpp} ${_output_getsrv} ${_output_setsrv} ${_output_dox} ${_output_usage}
                       COMMAND ${gencfg_cpp_exe} ${_input}
                       DEPENDS ${_input} ${gencfg_cpp_exe} ${ROS_MANIFEST_LIST} ${gencfg_build_files})
    list(APPEND _autogen ${_output_cpp} ${_output_msg} ${_output_getsrv} ${_output_setsrv} ${_output_dox} ${_output_usage})
  endforeach(_cfg)
  # Create a target that depends on the union of all the autogenerated
  # files
  add_custom_target(ROSBUILD_gencfg_cpp DEPENDS ${_autogen})
  # Add our target to the top-level gencfg target, which will be fired if
  # the user calls gencfg()
  add_dependencies(rospack_gencfg ROSBUILD_gencfg_cpp)

  # FIXME Remove these later, once ROS has been patched.
  genmsg_cpp()
  gensrv_cpp()
endmacro(gencfg_cpp)

# Call the macro we just defined.
gencfg_cpp()


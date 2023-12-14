cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "quick_breakpad")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "quick_breakpad_plugin")

add_library(${PLUGIN_NAME} SHARED
  "quick_breakpad_plugin.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

target_include_directories(${PLUGIN_NAME}
  INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/breakpad/include")

target_link_directories(${PLUGIN_NAME} PRIVATE
  $<$<CONFIG:Debug>:${CMAKE_CURRENT_SOURCE_DIR}/breakpad/${CMAKE_SYSTEM_PROCESSOR}/Debug>
  $<$<CONFIG:Profile>:${CMAKE_CURRENT_SOURCE_DIR}/breakpad/${CMAKE_SYSTEM_PROCESSOR}/Release>
  $<$<CONFIG:Release>:${CMAKE_CURRENT_SOURCE_DIR}/breakpad/${CMAKE_SYSTEM_PROCESSOR}/Release>)

target_link_libraries(${PLUGIN_NAME} PRIVATE exception_handler crash_generation_client common)

# List of absolute paths to libraries that should be bundled with the plugin
set(quick_breakpad_bundled_libraries
  ""
  PARENT_SCOPE
)

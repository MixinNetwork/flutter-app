#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  desktop_drop
  desktop_keep_screen_on
  desktop_lifecycle
  desktop_webview_window
  file_selector_windows
  flutter_app_icon_badge
  local_auth_windows
  pasteboard
  platform_device_id_windows
  protocol_handler
  quick_breakpad
  screen_retriever
  sqlite3_flutter_libs
  system_tray
  url_launcher_windows
  win_toast
  window_manager
  window_size
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
  ogg_opus_player
  system_clock
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)

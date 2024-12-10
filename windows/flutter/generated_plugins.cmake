#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  desktop_drop
  desktop_keep_screen_on
  desktop_webview_window
  file_selector_windows
  flutter_app_icon_badge
  irondash_engine_context
  local_auth_windows
  platform_device_id_windows
  protocol_handler_windows
  screen_retriever_windows
  sqlite3_flutter_libs
  super_native_extensions
  system_tray
  url_launcher_windows
  win_toast
  window_manager
  window_size
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
  breakpad_client
  mixin_logger
  ogg_opus_player
  rhttp
  system_clock
  webcrypto
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

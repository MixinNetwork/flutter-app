#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  bring_window_to_front
  desktop_drop
  desktop_webview_window
  file_selector_linux
  flutter_app_icon_badge
  irondash_engine_context
  open_file_linux
  platform_device_id_linux
  screen_retriever_linux
  sentry_flutter
  sqlite3_flutter_libs
  super_native_extensions
  url_launcher_linux
  window_manager
  window_size
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
  breakpad_client
  mixin_logger
  ogg_opus_player
  rhttp
  webcrypto
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/linux plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/linux plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)

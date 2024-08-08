#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "string"
#include "dbus/dbus.h"

#include "flutter/generated_plugin_registrant.h"

namespace {

const char *icon_relative_path = "/data/flutter_assets/assets/icons/windows_app_icon.png";

std::string GetIconPath() {
  char execute_path[PATH_MAX];
  memset(execute_path, 0, sizeof(execute_path));
  auto ret = readlink("/proc/self/exe", execute_path, PATH_MAX);
  if (ret == -1) {
    return "";
  }
  std::string icon_path(g_path_get_dirname(execute_path));
  icon_path.append(icon_relative_path);
  return icon_path;
}

int send_remote_args_to_primary_instance(char **arguments) {
  DBusError err;
  dbus_error_init(&err);
  auto connection = dbus_bus_get(DBUS_BUS_SESSION, &err);
  if (dbus_error_is_set(&err)) {
    fprintf(stderr, "Connection Error (%s)\n", err.message);
    dbus_error_free(&err);
  }
  if (connection == nullptr) {
    return -1;
  }

  dbus_uint32_t serial = 0;
  auto msg = dbus_message_new_method_call(
      "one.mixin.messenger",
      "/one/mixin/messenger",
      "one.mixin.messenger",
      "Open");
  DBusMessageIter args;
  dbus_message_iter_init_append(msg, &args);

  for (int i = 0; arguments[i] != nullptr; i++) {
    if (!dbus_message_iter_append_basic(&args, DBUS_TYPE_STRING, &arguments[i])) {
      g_warning("Out Of Memory!\n");
      return -1;
    }
  }

  auto send = dbus_connection_send(
      connection,
      msg,
      &serial);

  if (!send) {
    g_warning("Failed to send message to primary instance");
    return -1;
  }
  dbus_connection_flush(connection);
  dbus_message_unref(msg);
  return 0;
}

}

struct _MyApplication {
  GtkApplication parent_instance;
  char **dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void my_application_activate(GApplication *application) {
  MyApplication *self = MY_APPLICATION(application);
  GtkWindow *window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  auto icon_path = GetIconPath();
  if (!icon_path.empty()) {
    printf("icon path: %s", icon_path.c_str());
    gtk_window_set_icon_from_file(window, icon_path.c_str(), nullptr);
  }

  gtk_window_set_title(window, "Mixin Messenger");
  gtk_window_set_default_size(window, 1280, 720);
  gtk_window_set_position(window, GTK_WIN_POS_CENTER);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication *application, gchar ***arguments, int *exit_status) {
  MyApplication *self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  if (g_application_get_is_remote(application)) {
    g_warning("already running, try to open in primary instance.\n");
    char **args = g_strdupv(*arguments + 1);
    // send the args to primary instance by dbus
    int result = send_remote_args_to_primary_instance(args);
    if (result == 0) {
      g_info("Send args to primary instance successfully");
    } else {
      g_warning("Failed to send args to primary instance");
    }
    g_strfreev(args);
    *exit_status = 0;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GObject::dispose.
static void my_application_dispose(GObject *object) {
  MyApplication *self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass *klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication *self) {}

MyApplication *my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_HANDLES_COMMAND_LINE,
                                     nullptr));
}

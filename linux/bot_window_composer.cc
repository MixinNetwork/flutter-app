// Lays out the app's browser windows like the mobile web view: the
// `••• | ✕` capsule, and either a title row or, for immersive pages, a strip
// to drag the window. Both are the window's client-side title bar, so GTK
// drags the window and keeps its frame and shadow.
//
// `•••` asks Dart to show its menu in a Flutter view that shares the main
// engine, laid transparent over the page; Flutter's barrier takes the clicks
// outside the menu. On X11 a second view crashes the
// engine (flutter/flutter#186577), so `•••` opens a native menu instead.

#include "bot_window_composer.h"

#include <desktop_webview_window/webview_window_composer.h>
#include <gtk/gtk.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include <cstdint>
#include <cstring>
#include <map>
#include <memory>
#include <string>

namespace {

constexpr int kDragHeight = 28;
constexpr int kTitleRowHeight = 48;
constexpr int kCapsuleWidth = 88;
constexpr int kCapsuleHeight = 32;
constexpr int kCapsuleMargin = 6;
constexpr int kLeadingSize = 24;
constexpr int kLeadingLeft = 12;
constexpr int kGap = 8;

FlEngine* engine = nullptr;
FlMethodChannel* channel = nullptr;

struct BotWindow {
  int64_t browser = 0;
  GtkWindow* window = nullptr;
  GtkWidget* webview = nullptr;
  GtkWidget* page = nullptr;
  GtkWidget* header = nullptr;
  GtkWidget* overlay = nullptr;
  GtkWidget* leading = nullptr;
  GtkWidget* title = nullptr;
  GtkWidget* capsule = nullptr;
  GtkWidget* popup = nullptr;
  GtkWidget* menu = nullptr;
  GtkCssProvider* css = nullptr;
  bool immersive = false;
  bool follows_page_title = false;
  bool shows_icon = false;
  std::string url;
  std::map<std::string, std::string> menu_labels;
  uint32_t background = 0xFFFFFFFF;
  bool dark = false;
  GdkPixbuf* icon = nullptr;
  bool can_go_back = false;
  bool can_go_forward = false;
  bool back_hovered = false;
  bool back_pressed = false;
  int capsule_pressed = -1;  // 0: •••, 1: ✕
  bool popup_shown = false;
  bool dismiss_requested = false;
  GtkAllocation popup_allocation{};  // The overlay's when the popup showed.

  ~BotWindow() {
    g_clear_object(&icon);
    g_clear_object(&css);
  }
};

std::map<int64_t, std::unique_ptr<BotWindow>>& Windows() {
  static auto* windows = new std::map<int64_t, std::unique_ptr<BotWindow>>();
  return *windows;
}

BotWindow* Find(int64_t browser) {
  const auto found = Windows().find(browser);
  return found == Windows().end() ? nullptr : found->second.get();
}

bool IsX11() {
#ifdef GDK_WINDOWING_X11
  return GDK_IS_X11_DISPLAY(gdk_display_get_default());
#else
  return false;
#endif
}

FlValue* Lookup(FlValue* map, const char* key) {
  return map && fl_value_get_type(map) == FL_VALUE_TYPE_MAP
             ? fl_value_lookup_string(map, key)
             : nullptr;
}

bool GetBool(FlValue* map, const char* key) {
  FlValue* value = Lookup(map, key);
  return value && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL &&
         fl_value_get_bool(value);
}

std::string GetString(FlValue* map, const char* key) {
  FlValue* value = Lookup(map, key);
  return value && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(value)
             : "";
}

// CreateConfiguration.composerArguments: base64 of a standard-codec map.
FlValue* DecodeArguments(const char* arguments) {
  if (!arguments) return nullptr;
  gsize length = 0;
  guchar* data = g_base64_decode(arguments, &length);
  g_autoptr(GBytes) bytes = g_bytes_new_take(data, length);
  g_autoptr(FlStandardMessageCodec) codec = fl_standard_message_codec_new();
  g_autoptr(GError) error = nullptr;
  FlValue* value =
      fl_message_codec_decode_message(FL_MESSAGE_CODEC(codec), bytes, &error);
  if (value && fl_value_get_type(value) != FL_VALUE_TYPE_MAP) {
    fl_value_unref(value);
    return nullptr;
  }
  return value;
}

void SetSource(cairo_t* cr, uint32_t argb) {
  cairo_set_source_rgba(cr, ((argb >> 16) & 0xFF) / 255.0,
                        ((argb >> 8) & 0xFF) / 255.0, (argb & 0xFF) / 255.0,
                        (argb >> 24) / 255.0);
}

void Invoke(const char* method, int64_t browser) {
  if (!channel) return;
  g_autoptr(FlValue) arguments = fl_value_new_map();
  fl_value_set_string_take(arguments, "browserId", fl_value_new_int(browser));
  fl_method_channel_invoke_method(channel, method, arguments, nullptr, nullptr,
                                  nullptr);
}

// Dart hides the menu, then the popup through hidePopup.
void RequestDismiss(BotWindow* bot) {
  if (!bot->popup_shown || bot->dismiss_requested) return;
  bot->dismiss_requested = true;
  Invoke("onDismissPopup", bot->browser);
}

// Deferred: closing destroys the widget whose handler asked for it.
void CloseLater(int64_t browser) {
  g_idle_add(
      [](gpointer data) {
        dww_browser_close(static_cast<int64_t>(reinterpret_cast<intptr_t>(data)));
        return G_SOURCE_REMOVE;
      },
      reinterpret_cast<gpointer>(static_cast<intptr_t>(browser)));
}

void UpdateStyle(BotWindow* bot) {
  g_autofree gchar* css = g_strdup_printf(
      "#bot-header { background: rgb(%u, %u, %u); background-image: none;"
      " box-shadow: none; border: none; padding: 0; min-height: %dpx; }"
      " #bot-title { color: %s; font-size: 16px; font-weight: 500; }",
      (bot->background >> 16) & 0xFF, (bot->background >> 8) & 0xFF,
      bot->background & 0xFF, bot->immersive ? kDragHeight : kTitleRowHeight,
      bot->dark ? "white" : "black");
  gtk_css_provider_load_from_data(bot->css, css, -1, nullptr);
}

// The 24 × 24 slot before the title: the bot's icon, which turns into `‹`
// while the page can go back. Pages without an icon show it only for `‹`.
void UpdateLeading(BotWindow* bot) {
  if (!bot->leading) return;
  const bool shown = bot->shows_icon || bot->can_go_back;
  gtk_widget_set_visible(bot->leading, shown);
  gtk_widget_set_margin_start(bot->title, shown ? 0 : kLeadingLeft);
  gtk_widget_queue_draw(bot->leading);
}

gboolean DrawLeading(GtkWidget*, cairo_t* cr, BotWindow* bot) {
  const double radius = kLeadingSize / 2.0;
  cairo_arc(cr, radius, radius, radius, 0, 2 * G_PI);
  const uint32_t fill = bot->dark ? 0x26FFFFFF : 0x14000000;
  if (bot->can_go_back) {
    if (bot->back_hovered) {
      SetSource(cr, fill);
      cairo_fill(cr);
    }
    cairo_new_path(cr);
    cairo_move_to(cr, 14, 6);
    cairo_line_to(cr, 8, 12);
    cairo_line_to(cr, 14, 18);
    SetSource(cr, bot->dark ? 0xFFFFFFFF : 0xFF000000);
    cairo_set_line_width(cr, 2);
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND);
    cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND);
    cairo_stroke(cr);
  } else if (bot->icon) {
    cairo_clip(cr);
    cairo_scale(cr, kLeadingSize / static_cast<double>(gdk_pixbuf_get_width(bot->icon)),
                kLeadingSize / static_cast<double>(gdk_pixbuf_get_height(bot->icon)));
    gdk_cairo_set_source_pixbuf(cr, bot->icon, 0, 0);
    cairo_pattern_set_filter(cairo_get_source(cr), CAIRO_FILTER_GOOD);
    cairo_paint(cr);
  } else {
    // Holds the icon's place until it loads, or if it never does.
    SetSource(cr, fill);
    cairo_fill(cr);
  }
  return TRUE;
}

gboolean LeadingCrossing(GtkWidget*, GdkEventCrossing* event, BotWindow* bot) {
  bot->back_hovered = event->type == GDK_ENTER_NOTIFY;
  gtk_widget_queue_draw(bot->leading);
  return FALSE;
}

gboolean LeadingPress(GtkWidget*, GdkEventButton* event, BotWindow* bot) {
  bot->back_pressed = false;
  // The popup doesn't cover the title bar on Wayland: the click only
  // dismisses it.
  if (bot->popup_shown) {
    RequestDismiss(bot);
    return TRUE;
  }
  bot->back_pressed = bot->can_go_back && event->button == GDK_BUTTON_PRIMARY;
  // Otherwise the title bar drags the window.
  return bot->back_pressed;
}

gboolean LeadingRelease(GtkWidget* widget, GdkEventButton* event,
                        BotWindow* bot) {
  if (!bot->back_pressed || event->button != GDK_BUTTON_PRIMARY) return FALSE;
  bot->back_pressed = false;
  if (bot->can_go_back && event->x >= 0 && event->y >= 0 &&
      event->x < gtk_widget_get_allocated_width(widget) &&
      event->y < gtk_widget_get_allocated_height(widget)) {
    dww_browser_go_back(bot->browser);
  }
  return TRUE;
}

void AddRoundedRect(cairo_t* cr, double x, double y, double width,
                    double height, double radius) {
  cairo_new_sub_path(cr);
  cairo_arc(cr, x + width - radius, y + radius, radius, -G_PI / 2, 0);
  cairo_arc(cr, x + width - radius, y + height - radius, radius, 0, G_PI / 2);
  cairo_arc(cr, x + radius, y + height - radius, radius, G_PI / 2, G_PI);
  cairo_arc(cr, x + radius, y + radius, radius, G_PI, 3 * G_PI / 2);
  cairo_close_path(cr);
}

// `••• | ✕`, styled like Android's WebControlView.
gboolean DrawCapsule(GtkWidget*, cairo_t* cr, BotWindow* bot) {
  const bool dark = bot->dark;
  const double width = kCapsuleWidth;
  const double height = kCapsuleHeight;
  const double half = width / 2;
  AddRoundedRect(cr, 0.5, 0.5, width - 1, height - 1, (height - 1) / 2);
  SetSource(cr, dark ? 0xFF24262A : 0xC7F9F9F9);
  cairo_fill_preserve(cr);
  SetSource(cr, dark ? 0x0FFFFFFF : 0x0F000000);
  cairo_set_line_width(cr, 1);
  cairo_stroke(cr);
  if (bot->capsule_pressed >= 0) {
    cairo_save(cr);
    cairo_rectangle(cr, bot->capsule_pressed == 0 ? 0 : half, 0, half, height);
    cairo_clip(cr);
    AddRoundedRect(cr, 0.5, 0.5, width - 1, height - 1, (height - 1) / 2);
    SetSource(cr, dark ? 0x1FFFFFFF : 0x14000000);
    cairo_fill(cr);
    cairo_restore(cr);
  }

  SetSource(cr, dark ? 0x33FFFFFF : 0x1F000000);
  cairo_rectangle(cr, half - 0.5, 8, 1, height - 16);
  cairo_fill(cr);

  SetSource(cr, dark ? 0xFFFFFFFF : 0xFF000000);
  for (const double dx : {-6.0, 0.0, 6.0}) {
    cairo_arc(cr, half / 2 + dx, height / 2, 1.75, 0, 2 * G_PI);
    cairo_fill(cr);
  }
  const double x = half * 1.5;
  const double y = height / 2;
  cairo_move_to(cr, x - 5, y - 5);
  cairo_line_to(cr, x + 5, y + 5);
  cairo_move_to(cr, x + 5, y - 5);
  cairo_line_to(cr, x - 5, y + 5);
  cairo_set_line_width(cr, 1.6);
  cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND);
  cairo_stroke(cr);
  return TRUE;
}

void ActivateMenuItem(GtkMenuItem* item, gpointer data) {
  const auto browser = static_cast<int64_t>(reinterpret_cast<intptr_t>(data));
  BotWindow* bot = Find(browser);
  if (!bot) return;
  const std::string action = static_cast<const char*>(
      g_object_get_data(G_OBJECT(item), "action"));
  if (action == "refresh") {
    dww_browser_reload(browser);
  } else if (action == "copyLink") {
    gtk_clipboard_set_text(gtk_clipboard_get(GDK_SELECTION_CLIPBOARD),
                           bot->url.c_str(), -1);
  } else if (action == "openInBrowser") {
    gtk_show_uri_on_window(bot->window, bot->url.c_str(), GDK_CURRENT_TIME,
                           nullptr);
  } else if (action == "close") {
    CloseLater(browser);
  }
}

// X11 only: the items that need no Flutter UI.
void ShowNativeMenu(BotWindow* bot, GdkEvent* event) {
  if (!bot->menu) {
    bot->menu = gtk_menu_new();
    // Destroyed with the capsule.
    gtk_menu_attach_to_widget(GTK_MENU(bot->menu), bot->capsule, nullptr);
    for (const char* action : {"refresh", "copyLink", "openInBrowser", "", "close"}) {
      GtkWidget* item;
      if (*action == '\0') {
        item = gtk_separator_menu_item_new();
      } else {
        item = gtk_menu_item_new_with_label(bot->menu_labels[action].c_str());
        g_object_set_data(G_OBJECT(item), "action", const_cast<char*>(action));
        g_signal_connect(item, "activate", G_CALLBACK(ActivateMenuItem),
                         reinterpret_cast<gpointer>(static_cast<intptr_t>(bot->browser)));
      }
      gtk_menu_shell_append(GTK_MENU_SHELL(bot->menu), item);
    }
    gtk_widget_show_all(bot->menu);
  }
  gtk_menu_popup_at_widget(GTK_MENU(bot->menu), bot->capsule,
                           GDK_GRAVITY_SOUTH_EAST, GDK_GRAVITY_NORTH_EAST, event);
}

gboolean CapsulePress(GtkWidget* widget, GdkEventButton* event, BotWindow* bot) {
  if (event->type != GDK_BUTTON_PRESS || event->button != GDK_BUTTON_PRIMARY) {
    return TRUE;
  }
  if (bot->popup_shown) {
    RequestDismiss(bot);
    return TRUE;
  }
  bot->capsule_pressed = event->x < kCapsuleWidth / 2.0 ? 0 : 1;
  gtk_widget_queue_draw(widget);
  return TRUE;
}

gboolean CapsuleRelease(GtkWidget* widget, GdkEventButton* event,
                        BotWindow* bot) {
  const int pressed = bot->capsule_pressed;
  if (pressed < 0) return TRUE;
  bot->capsule_pressed = -1;
  gtk_widget_queue_draw(widget);
  const bool inside = event->x >= 0 && event->y >= 0 &&
                      event->x < kCapsuleWidth && event->y < kCapsuleHeight;
  if (!inside || (event->x < kCapsuleWidth / 2.0 ? 0 : 1) != pressed) return TRUE;
  if (pressed == 1) {
    CloseLater(bot->browser);
  } else if (IsX11()) {
    ShowNativeMenu(bot, reinterpret_cast<GdkEvent*>(event));
  } else {
    Invoke("onMoreTapped", bot->browser);
  }
  return TRUE;
}

// Alt+Left and Alt+Right, and the mouse's back and forward buttons, navigate
// in every layout.
bool Navigate(BotWindow* bot, bool forward) {
  if (bot->popup_shown) return false;
  if (forward) {
    if (!bot->can_go_forward) return false;
    dww_browser_go_forward(bot->browser);
  } else {
    if (!bot->can_go_back) return false;
    dww_browser_go_back(bot->browser);
  }
  return true;
}

// GDK numbers the mouse's back and forward buttons 8 and 9.
bool IsNavigationButton(const GdkEventButton* event) {
  return event->type == GDK_BUTTON_PRESS &&
         (event->button == 8 || event->button == 9);
}

// Connected to the page before WebKit's own handler, which takes every press.
gboolean PagePress(GtkWidget*, GdkEventButton* event, BotWindow* bot) {
  return IsNavigationButton(event) && Navigate(bot, event->button == 9);
}

gboolean WindowPress(GtkWidget*, GdkEventButton* event, BotWindow* bot) {
  // Presses on the title bar outside the capsule and `‹`.
  if (bot->popup_shown) {
    RequestDismiss(bot);
    return TRUE;
  }
  if (IsNavigationButton(event)) return Navigate(bot, event->button == 9);
  return FALSE;
}

// The menu hangs from where the capsule was when it opened. Showing the
// popup allocates the overlay again at the same size.
void OverlayAllocated(GtkWidget*, GtkAllocation* allocation, BotWindow* bot) {
  if (allocation->width != bot->popup_allocation.width ||
      allocation->height != bot->popup_allocation.height) {
    RequestDismiss(bot);
  }
}

void WindowActiveChanged(GObject*, GParamSpec*, BotWindow* bot) {
  if (!gtk_window_is_active(bot->window)) RequestDismiss(bot);
}

gboolean WindowKeyPress(GtkWidget*, GdkEventKey* event, BotWindow* bot) {
  if ((event->keyval != GDK_KEY_Left && event->keyval != GDK_KEY_Right) ||
      (event->state & gtk_accelerator_get_default_mod_mask()) != GDK_MOD1_MASK) {
    return FALSE;
  }
  return Navigate(bot, event->keyval == GDK_KEY_Right);
}

GtkWidget* DrawingArea(int width, int height, BotWindow* bot,
                       GCallback draw) {
  GtkWidget* area = gtk_drawing_area_new();
  gtk_widget_set_size_request(area, width, height);
  gtk_widget_set_valign(area, GTK_ALIGN_CENTER);
  gtk_widget_add_events(area, GDK_BUTTON_PRESS_MASK | GDK_BUTTON_RELEASE_MASK |
                                  GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK);
  g_signal_connect(area, "draw", draw, bot);
  return area;
}

void SetChrome(BotWindow* bot, FlValue* arguments) {
  FlValue* color = Lookup(arguments, "backgroundColor");
  if (color && fl_value_get_type(color) == FL_VALUE_TYPE_INT) {
    bot->background = static_cast<uint32_t>(fl_value_get_int(color));
  }
  if (Lookup(arguments, "dark")) bot->dark = GetBool(arguments, "dark");
  FlValue* icon = Lookup(arguments, "icon");
  if (icon && fl_value_get_type(icon) == FL_VALUE_TYPE_UINT8_LIST) {
    g_autoptr(GdkPixbufLoader) loader = gdk_pixbuf_loader_new();
    if (gdk_pixbuf_loader_write(loader, fl_value_get_uint8_list(icon),
                                fl_value_get_length(icon), nullptr) &&
        gdk_pixbuf_loader_close(loader, nullptr)) {
      if (GdkPixbuf* pixbuf = gdk_pixbuf_loader_get_pixbuf(loader)) {
        g_clear_object(&bot->icon);
        bot->icon = GDK_PIXBUF(g_object_ref(pixbuf));
      }
    }
  }
  UpdateStyle(bot);
  if (bot->leading) gtk_widget_queue_draw(bot->leading);
  gtk_widget_queue_draw(bot->capsule);
}

DWWComposeResult Compose(void*, const DWWComposeRequest* request) {
  g_autoptr(FlValue) arguments = DecodeArguments(request->arguments);
  if (!arguments) return DWW_COMPOSE_DEFAULT;
  auto owned = std::make_unique<BotWindow>();
  BotWindow* bot = owned.get();
  bot->browser = request->browser;
  bot->window = GTK_WINDOW(request->window);
  bot->webview = GTK_WIDGET(request->webview_view);
  bot->immersive = GetBool(arguments, "immersive");
  bot->follows_page_title = GetBool(arguments, "followPageTitle");
  bot->shows_icon = GetBool(arguments, "showIcon");
  FlValue* menu = Lookup(arguments, "menu");
  for (const char* action : {"refresh", "copyLink", "openInBrowser", "close"}) {
    bot->menu_labels[action] = GetString(menu, action);
  }
  const std::string title = GetString(arguments, "title");
  gtk_window_set_title(bot->window, title.c_str());
  // The size the window opens with is also the smallest it gets.
  GdkGeometry geometry{};
  gtk_window_get_default_size(bot->window, &geometry.min_width,
                              &geometry.min_height);
  gtk_window_set_geometry_hints(bot->window, nullptr, &geometry,
                                GDK_HINT_MIN_SIZE);

  bot->css = gtk_css_provider_new();
  bot->header = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
  gtk_widget_set_name(bot->header, "bot-header");
  gtk_style_context_add_provider(gtk_widget_get_style_context(bot->header),
                                 GTK_STYLE_PROVIDER(bot->css),
                                 GTK_STYLE_PROVIDER_PRIORITY_APPLICATION + 1);
  bot->capsule = DrawingArea(kCapsuleWidth, kCapsuleHeight, bot,
                             G_CALLBACK(DrawCapsule));
  g_signal_connect(bot->capsule, "button-press-event", G_CALLBACK(CapsulePress), bot);
  g_signal_connect(bot->capsule, "button-release-event", G_CALLBACK(CapsuleRelease), bot);
  gtk_widget_set_margin_end(bot->capsule, kCapsuleMargin);

  bot->overlay = gtk_overlay_new();
  gtk_container_add(GTK_CONTAINER(bot->overlay), bot->webview);
  if (bot->immersive) {
    // Over the page 6 below the strip.
    gtk_widget_set_halign(bot->capsule, GTK_ALIGN_END);
    gtk_widget_set_valign(bot->capsule, GTK_ALIGN_START);
    gtk_widget_set_margin_top(bot->capsule, 6);
    gtk_overlay_add_overlay(GTK_OVERLAY(bot->overlay), bot->capsule);
  } else {
    bot->leading = DrawingArea(kLeadingSize, kLeadingSize, bot,
                               G_CALLBACK(DrawLeading));
    gtk_widget_set_margin_start(bot->leading, kLeadingLeft);
    gtk_widget_set_margin_end(bot->leading, kGap);
    gtk_widget_set_no_show_all(bot->leading, TRUE);
    g_signal_connect(bot->leading, "button-press-event", G_CALLBACK(LeadingPress), bot);
    g_signal_connect(bot->leading, "button-release-event", G_CALLBACK(LeadingRelease), bot);
    g_signal_connect(bot->leading, "enter-notify-event", G_CALLBACK(LeadingCrossing), bot);
    g_signal_connect(bot->leading, "leave-notify-event", G_CALLBACK(LeadingCrossing), bot);
    bot->title = gtk_label_new(title.c_str());
    gtk_widget_set_name(bot->title, "bot-title");
    gtk_style_context_add_provider(gtk_widget_get_style_context(bot->title),
                                   GTK_STYLE_PROVIDER(bot->css),
                                   GTK_STYLE_PROVIDER_PRIORITY_APPLICATION + 1);
    // A long title truncates; the window keeps its width.
    gtk_label_set_ellipsize(GTK_LABEL(bot->title), PANGO_ELLIPSIZE_END);
    // The window's natural width would otherwise be the whole title's;
    // hexpand gives the label the rest.
    gtk_label_set_max_width_chars(GTK_LABEL(bot->title), 1);
    gtk_label_set_xalign(GTK_LABEL(bot->title), 0);
    gtk_widget_set_hexpand(bot->title, TRUE);
    gtk_widget_set_margin_end(bot->title, kGap);
    gtk_box_pack_start(GTK_BOX(bot->header), bot->leading, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(bot->header), bot->title, TRUE, TRUE, 0);
    gtk_box_pack_end(GTK_BOX(bot->header), bot->capsule, FALSE, FALSE, 0);
  }
  gtk_widget_set_size_request(bot->header, -1,
                              bot->immersive ? kDragHeight : kTitleRowHeight);
  gtk_widget_show_all(bot->header);
  gtk_window_set_titlebar(bot->window, bot->header);
  gtk_container_add(GTK_CONTAINER(bot->window), bot->overlay);
  gtk_widget_show_all(bot->overlay);

  g_signal_connect(bot->window, "button-press-event", G_CALLBACK(WindowPress), bot);
  g_signal_connect(bot->overlay, "size-allocate", G_CALLBACK(OverlayAllocated), bot);
  // The plugin's container holds WebKitWebView as its main child.
  bot->page = gtk_bin_get_child(GTK_BIN(bot->webview));
  if (bot->page) {
    g_signal_connect(bot->page, "button-press-event", G_CALLBACK(PagePress), bot);
  }
  g_signal_connect(bot->window, "key-press-event", G_CALLBACK(WindowKeyPress), bot);
  g_signal_connect(bot->window, "notify::is-active",
                   G_CALLBACK(WindowActiveChanged), bot);

  SetChrome(bot, arguments);
  UpdateLeading(bot);
  Windows()[bot->browser] = std::move(owned);
  return DWW_COMPOSE_HANDLED;
}

void NavigationChanged(void*, const DWWNavigationState* state) {
  BotWindow* bot = Find(state->browser);
  if (!bot) return;
  bot->url = state->url ? state->url : "";
  bot->can_go_back = state->can_go_back != 0;
  bot->can_go_forward = state->can_go_forward != 0;
  if (!bot->can_go_back) bot->back_hovered = false;
  if (bot->follows_page_title) {
    const char* title = state->title ? state->title : "";
    gtk_window_set_title(bot->window, title);
    if (bot->title) gtk_label_set_text(GTK_LABEL(bot->title), title);
  }
  UpdateLeading(bot);
}

void Closing(void*, int64_t browser) {
  const auto found = Windows().find(browser);
  if (found == Windows().end()) return;
  BotWindow* bot = found->second.get();
  // The widgets go with the window, the popup's view with them; nothing may
  // call back into this state while they do.
  for (gpointer instance : {static_cast<gpointer>(bot->window),
                            static_cast<gpointer>(bot->page),
                            static_cast<gpointer>(bot->leading),
                            static_cast<gpointer>(bot->capsule)}) {
    if (instance) g_signal_handlers_disconnect_by_data(instance, bot);
  }
  Windows().erase(found);
}

// The view is created on first use, then hidden and reused until the window
// closes.
FlValue* ShowPopup(BotWindow* bot) {
  if (!bot->popup) {
    bot->popup = GTK_WIDGET(fl_view_new_for_engine(engine));
    const GdkRGBA transparent{0, 0, 0, 0};
    fl_view_set_background_color(FL_VIEW(bot->popup), &transparent);
    gtk_widget_set_no_show_all(bot->popup, TRUE);
    gtk_overlay_add_overlay(GTK_OVERLAY(bot->overlay), bot->popup);
  }
  bot->popup_shown = true;
  bot->dismiss_requested = false;
  gtk_widget_get_allocation(bot->overlay, &bot->popup_allocation);
  gtk_widget_show(bot->popup);
  gtk_widget_grab_focus(bot->popup);
  // The capsule may be in the title bar, above the view.
  int x = 0;
  int y = 0;
  gtk_widget_translate_coordinates(bot->capsule, bot->overlay, 0, 0, &x, &y);
  FlValue* anchor = fl_value_new_list();
  for (const int value : {x, y, kCapsuleWidth, kCapsuleHeight}) {
    fl_value_append_take(anchor, fl_value_new_float(value));
  }
  FlValue* result = fl_value_new_map();
  fl_value_set_string_take(result, "viewId",
                           fl_value_new_int(fl_view_get_id(FL_VIEW(bot->popup))));
  fl_value_set_string_take(result, "anchor", anchor);
  return result;
}

void HidePopup(BotWindow* bot) {
  bot->popup_shown = false;
  if (!bot->popup) return;
  gtk_widget_hide(bot->popup);
  gtk_widget_grab_focus(bot->webview);
}

#ifndef NDEBUG
// For integration tests; the same on every platform. Points are top-left
// based, in window content coordinates: the title bar's, inside the frame.

bool DebugPoint(FlValue* value, double* x, double* y) {
  if (!value || fl_value_get_type(value) != FL_VALUE_TYPE_LIST ||
      fl_value_get_length(value) < 2) {
    return false;
  }
  *x = fl_value_get_float(fl_value_get_list_value(value, 0));
  *y = fl_value_get_float(fl_value_get_list_value(value, 1));
  return true;
}

bool Contains(BotWindow* bot, GtkWidget* widget, double x, double y) {
  if (!widget || !gtk_widget_get_mapped(widget)) return false;
  int local_x = 0;
  int local_y = 0;
  if (!gtk_widget_translate_coordinates(bot->header, widget, static_cast<int>(x),
                                        static_cast<int>(y), &local_x, &local_y)) {
    return false;
  }
  return local_x >= 0 && local_y >= 0 &&
         local_x < gtk_widget_get_allocated_width(widget) &&
         local_y < gtk_widget_get_allocated_height(widget);
}

// What takes a click at the point. The popup is over the page only: on
// Wayland the title bar stays above it.
const char* RoleAt(BotWindow* bot, double x, double y) {
  if (Contains(bot, bot->popup, x, y)) return "popup";
  if (Contains(bot, bot->capsule, x, y)) return "capsule";
  if (bot->can_go_back && Contains(bot, bot->leading, x, y)) return "leading";
  return Contains(bot, bot->header, x, y) ? "header" : "page";
}

FlValue* DebugProbe(BotWindow* bot, FlValue* arguments) {
  const int width = gtk_widget_get_allocated_width(bot->header);
  const int height = gtk_widget_get_allocated_height(bot->header);
  cairo_surface_t* surface =
      cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);
  cairo_t* cr = cairo_create(surface);
  gtk_widget_draw(bot->header, cr);
  cairo_destroy(cr);
  cairo_surface_flush(surface);
  const unsigned char* data = cairo_image_surface_get_data(surface);
  const int stride = cairo_image_surface_get_stride(surface);

  FlValue* probes = fl_value_new_list();
  FlValue* points = Lookup(arguments, "points");
  const size_t count = points && fl_value_get_type(points) == FL_VALUE_TYPE_LIST
                           ? fl_value_get_length(points)
                           : 0;
  for (size_t i = 0; i < count; i++) {
    double x = 0;
    double y = 0;
    if (!DebugPoint(fl_value_get_list_value(points, i), &x, &y)) continue;
    // Only the title bar is drawn here; the tests probe nothing else.
    int64_t color = 0;
    if (x >= 0 && y >= 0 && x < width && y < height) {
      color = 0xFF000000 |
              (*reinterpret_cast<const uint32_t*>(
                   data + static_cast<int>(y) * stride + static_cast<int>(x) * 4) &
               0xFFFFFF);
    }
    FlValue* probe = fl_value_new_map();
    fl_value_set_string_take(probe, "hit", fl_value_new_string(RoleAt(bot, x, y)));
    fl_value_set_string_take(probe, "color", fl_value_new_int(color));
    fl_value_append_take(probes, probe);
  }
  cairo_surface_destroy(surface);

  int origin_x = 0;
  int origin_y = 0;
  gtk_widget_translate_coordinates(bot->overlay, bot->header, 0, 0, &origin_x,
                                   &origin_y);
  FlValue* origin = fl_value_new_list();
  fl_value_append_take(origin, fl_value_new_float(origin_x));
  fl_value_append_take(origin, fl_value_new_float(origin_y));
  const bool leading_shown = bot->leading && gtk_widget_get_visible(bot->leading);
  FlValue* leading = fl_value_new_map();
  fl_value_set_string_take(leading, "shown", fl_value_new_bool(leading_shown));
  fl_value_set_string_take(leading, "hasIcon", fl_value_new_bool(bot->icon != nullptr));
  fl_value_set_string_take(leading, "back",
                           fl_value_new_bool(leading_shown && bot->can_go_back));

  FlValue* result = fl_value_new_map();
  fl_value_set_string_take(result, "probes", probes);
  fl_value_set_string_take(result, "headerColor",
                           fl_value_new_int(0xFF000000 | (bot->background & 0xFFFFFF)));
  fl_value_set_string_take(
      result, "popupHidden",
      fl_value_new_bool(!bot->popup || !gtk_widget_get_visible(bot->popup)));
  fl_value_set_string_take(result, "popupOrigin", origin);
  fl_value_set_string_take(result, "nativeMenu", fl_value_new_bool(IsX11()));
  fl_value_set_string_take(result, "leading", leading);
  fl_value_set_string_take(
      result, "width",
      fl_value_new_float(gtk_widget_get_allocated_width(bot->overlay)));
  return result;
}

// The topmost visible window at a point in `window`; GDK keeps siblings
// top first.
GdkWindow* WindowAt(GdkWindow* window, int x, int y, int* local_x, int* local_y) {
  for (GList* child = gdk_window_peek_children(window); child; child = child->next) {
    GdkWindow* candidate = GDK_WINDOW(child->data);
    if (!gdk_window_is_visible(candidate)) continue;
    int left = 0;
    int top = 0;
    gdk_window_get_position(candidate, &left, &top);
    if (x >= left && y >= top && x < left + gdk_window_get_width(candidate) &&
        y < top + gdk_window_get_height(candidate)) {
      return WindowAt(candidate, x - left, y - top, local_x, local_y);
    }
  }
  *local_x = x;
  *local_y = y;
  return window;
}

// Delivers the event a real mouse would, through GTK's own dispatch.
void DebugMouse(BotWindow* bot, FlValue* arguments, int dx = 0) {
  GtkWidget* toplevel = GTK_WIDGET(bot->window);
  int x = 0;
  int y = 0;
  FlValue* x_value = Lookup(arguments, "x");
  FlValue* y_value = Lookup(arguments, "y");
  gtk_widget_translate_coordinates(
      bot->header, toplevel,
      x_value ? static_cast<int>(fl_value_get_float(x_value)) : 0,
      y_value ? static_cast<int>(fl_value_get_float(y_value)) : 0, &x, &y);
  GtkAllocation allocation;
  gtk_widget_get_allocation(toplevel, &allocation);
  int local_x = 0;
  int local_y = 0;
  GdkWindow* target = WindowAt(gtk_widget_get_window(toplevel),
                               x + dx + allocation.x, y + allocation.y,
                               &local_x, &local_y);
  int root_x = 0;
  int root_y = 0;
  gdk_window_get_root_coords(target, local_x, local_y, &root_x, &root_y);

  const std::string type = GetString(arguments, "type");
  const guint32 time = static_cast<guint32>(g_get_monotonic_time() / 1000);
  GdkEvent* event;
  if (type == "down" || type == "up") {
    event = gdk_event_new(type == "down" ? GDK_BUTTON_PRESS : GDK_BUTTON_RELEASE);
    event->button.time = time;
    event->button.x = local_x;
    event->button.y = local_y;
    event->button.x_root = root_x;
    event->button.y_root = root_y;
    event->button.button = GDK_BUTTON_PRIMARY;
    event->button.state = type == "up" ? GDK_BUTTON1_MASK : 0;
  } else {
    event = gdk_event_new(GDK_MOTION_NOTIFY);
    event->motion.time = time;
    event->motion.x = local_x;
    event->motion.y = local_y;
    event->motion.x_root = root_x;
    event->motion.y_root = root_y;
  }
  event->any.window = GDK_WINDOW(g_object_ref(target));
  event->any.send_event = TRUE;
  GdkDevice* pointer = gdk_seat_get_pointer(
      gdk_display_get_default_seat(gdk_window_get_display(target)));
  gdk_event_set_device(event, pointer);
  gdk_event_set_source_device(event, pointer);
  gtk_main_do_event(event);
  gdk_event_free(event);
}
#endif

void HandleCall(FlMethodChannel*, FlMethodCall* call, gpointer) {
  const char* method = fl_method_call_get_name(call);
  FlValue* arguments = fl_method_call_get_args(call);
  FlValue* browser = Lookup(arguments, "browserId");
  BotWindow* bot = browser && fl_value_get_type(browser) == FL_VALUE_TYPE_INT
                       ? Find(fl_value_get_int(browser))
                       : nullptr;
  if (!bot) {
    fl_method_call_respond_error(call, "no_window", "Unknown browser window",
                                 nullptr, nullptr);
    return;
  }
  if (strcmp(method, "setChrome") == 0) {
    SetChrome(bot, arguments);
    fl_method_call_respond_success(call, nullptr, nullptr);
  } else if (strcmp(method, "showPopup") == 0) {
    if (IsX11()) {
      fl_method_call_respond_error(call, "unsupported",
                                   "X11 cannot add Flutter views", nullptr,
                                   nullptr);
      return;
    }
    g_autoptr(FlValue) result = ShowPopup(bot);
    fl_method_call_respond_success(call, result, nullptr);
  } else if (strcmp(method, "hidePopup") == 0) {
    HidePopup(bot);
    fl_method_call_respond_success(call, nullptr, nullptr);
  } else if (strcmp(method, "focus") == 0) {
    gtk_window_present(bot->window);
    g_autoptr(FlValue) focused = fl_value_new_bool(TRUE);
    fl_method_call_respond_success(call, focused, nullptr);
#ifndef NDEBUG
  } else if (strcmp(method, "debugProbe") == 0) {
    g_autoptr(FlValue) result = DebugProbe(bot, arguments);
    fl_method_call_respond_success(call, result, nullptr);
  } else if (strcmp(method, "debugMouse") == 0) {
    // Flutter drops a hover where the pointer was just added: the move needs
    // a step before the point.
    if (GetString(arguments, "type") == "moved") DebugMouse(bot, arguments, -1);
    DebugMouse(bot, arguments);
    fl_method_call_respond_success(call, nullptr, nullptr);
#endif
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
  }
}

}  // namespace

void bot_window_composer_install(FlView* view) {
  engine = FL_ENGINE(g_object_ref(fl_view_get_engine(view)));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  channel = fl_method_channel_new(fl_engine_get_binary_messenger(engine),
                                  "one.mixin/bot_window", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, HandleCall, nullptr, nullptr);

  static const DWWComposer composer{nullptr, Compose, NavigationChanged,
                                    nullptr, Closing};
  dww_set_composer(&composer);
}

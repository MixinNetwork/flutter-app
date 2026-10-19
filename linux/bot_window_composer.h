#ifndef BOT_WINDOW_COMPOSER_H_
#define BOT_WINDOW_COMPOSER_H_

#include <flutter_linux/flutter_linux.h>

// Lays out the app's browser windows like the mobile web view and registers
// the `one.mixin/bot_window` channel on |view|'s engine. Call before the
// first browser opens.
void bot_window_composer_install(FlView* view);

#endif  // BOT_WINDOW_COMPOSER_H_

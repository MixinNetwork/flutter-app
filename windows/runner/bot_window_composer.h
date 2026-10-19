#ifndef RUNNER_BOT_WINDOW_COMPOSER_H_
#define RUNNER_BOT_WINDOW_COMPOSER_H_

#include <flutter/binary_messenger.h>

namespace bot_window_composer {

// Lays out the app's browser windows like the mobile web view and registers
// the `one.mixin/bot_window` channel. Call before the first browser opens.
void Install(flutter::BinaryMessenger* messenger);

}  // namespace bot_window_composer

#endif  // RUNNER_BOT_WINDOW_COMPOSER_H_

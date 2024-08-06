#include <pwd.h>

#include "my_application.h"
#include <mixin_logger/mixin_logger.h>
#include <filesystem>
#include <iostream>
#include <breakpad_client/breakpad_client.h>


std::filesystem::path get_app_dir() {
    auto home_dir = getenv("HOME");
    if ((home_dir = getenv("HOME")) == nullptr) {
        home_dir = getpwuid(getuid())->pw_dir;
    }
    if (home_dir == nullptr) {
        std::cout << "failed to get home dir" << std::endl;
        return "/tmp";
    }

    const std::filesystem::path home(home_dir);
    return home / ".mixin";
}


void write_log(const char *log) {
    mixin_logger_write_log(log);
}

int main(int argc, char **argv) {
    auto app_dir = get_app_dir();
    mixin_logger_init((app_dir / "log").c_str(), 10 * 1024 * 1024, 10, "");

    breakpad_client_set_logger(write_log);
    breakpad_client_init_exception_handler((app_dir / "crash").c_str());

    g_autoptr(MyApplication) app = my_application_new();
    return g_application_run(G_APPLICATION(app), argc, argv);
}

# quick_breakpad

A cross-platform flutter plugin for `C/C++/ObjC` crash report via [Google Breakpad](https://chromium.googlesource.com/breakpad/breakpad)

# Use breakpad for quick_breakpad_example

> $CLI_BREAKPAD is local clone of https://github.com/Sunbreak/cli-breakpad.trial

## Android

- run on macOS/Linux

```sh
# Device/emulator connected
$ android_abi=`adb shell getprop ro.product.cpu.abi`
$ pushd example
$ flutter run
✓ Built build/app/outputs/flutter-apk/app-debug.apk.
I/quick_breakpad(28255): JNI_OnLoad
I quick_breakpad_example(28255): JNI_OnLoad
D quick_breakpad(28255): Dump path: /data/data/com.example.quick_breakpad_example/cache/54ecbb9d-cef5-4fa9-5b6869b2-198bc87e.dmp
$ popd
$ adb shell "run-as com.example.quick_breakpad_example sh -c 'cat /data/data/com.example.quick_breakpad_example/cache/54ecbb9d-cef5-4fa9-5b6869b2-198bc87e.dmp'" >| 54ecbb9d-cef5-4fa9-5b6869b2-198bc87e.dmp
```

- run on Linux (e.g. https://multipass.run/)

> Only C/C++ crash for now

```sh
$ $CLI_BREAKPAD/breakpad/linux/$(arch)/dump_syms example/build/app/intermediates/cmake/debug/obj/${android_abi}/libquick-breakpad-example.so > libquick-breakpad-example.so.sym
$ uuid=`awk 'FNR==1{print \$4}' libquick-breakpad-example.so.sym`
$ mkdir -p symbols/libquick-breakpad-example.so/$uuid/
$ mv ./libquick-breakpad-example.so.sym symbols/libquick-breakpad-example.so/$uuid/
$ $CLI_BREAKPAD/breakpad/linux/$(arch)/minidump_stackwalk 54ecbb9d-cef5-4fa9-5b6869b2-198bc87e.dmp symbols/ > libquick-breakpad-example.so.log
```

- Show parsed Android log: `head -n 20 libquick-breakpad-example.so.log`

So the crash is at line 30 of `quick_breakpad_example.cpp`

![image](https://user-images.githubusercontent.com/7928961/135052776-226168bc-ee60-442c-b6b3-78987714e63d.png)

## iOS

- run on macOS

1. Get simulator UUID and run on it

```sh
$ flutter devices
1 connected device:
iPhone SE (2nd generation) (mobile) • C7E50B0A-D9AE-4073-9C3C-14DAF9D93329 • ios        • com.apple.CoreSimulator.SimRuntime.iOS-14-5 (simulator)
$ device=C7E50B0A-D9AE-4073-9C3C-14DAF9D93329
$ pushd example
$ flutter run -d $device
Running Xcode build...                                                  
 └─Compiling, linking and signing...                      2,162ms
Xcode build done.                                            6.2s
Lost connection to device.
$ popd
```

2. Find application data and get dump file

```sh
$ data=`xcrun simctl get_app_container booted com.example.quickBreakpadExample data`
$ ls $data/Library/Caches/Breakpad
A1D2CF75-848E-42C4-8F5C-0406E8520647.dmp        Config-FsNxCZ
$ cp $data/Library/Caches/Breakpad/A1D2CF75-848E-42C4-8F5C-0406E8520647.dmp .
```

3. Parse the dump file via symbols of `Runner`

> Only C/C++/Objective-C crash for now

```sh
$ dsymutil example/build/ios/Debug-iphonesimulator/Runner.app/Runner -o Runner.dSYM
$ $CLI_BREAKPAD/breakpad/mac/dump_syms Runner.dSYM > Runner.sym
$ uuid=`awk 'FNR==1{print \$4}' Runner.sym`
$ mkdir -p symbols/Runner/$uuid/
$ mv ./Runner.sym symbols/Runner/$uuid/
$ $CLI_BREAKPAD/breakpad/mac/$(arch)/minidump_stackwalk A1D2CF75-848E-42C4-8F5C-0406E8520647.dmp symbols > Runner.log
```

- Show parsed iOS log: `head -n 20 Runner.log`

So the crash is at line 11 of `AppDelegate.m`

![image](https://user-images.githubusercontent.com/7928961/135052660-3f5ebf3a-df20-4176-906e-89c92e76b3f2.png)

## Windows

1. Run the example

- run on Windows

```bat
rem Command Prompt
> pushd example
> flutter run -d windows
Building Windows application...                                         
dump_path: .
minidump_id: 34cd2b95-aef1-4003-ae75-1c848b18aad2
> popd
> copy example\34cd2b95-aef1-4003-ae75-1c848b18aad2.dmp .
```

2. Parse the dump file

- run on Windows

```bat
rem Command Prompt
> %CLI_BREAKPAD%\windows\%PROCESSOR_ARCHITECTURE%\dump_syms example\build\windows\runner\Debug\quick_breakpad_example.pdb > quick_breakpad_example.sym
```

- run on Linux

```bat
# bash or zsh
$ uuid=`awk 'FNR==1{print \$4}' quick_breakpad_example.sym`
$ mkdir -p symbols/quick_breakpad_example.pdb/$uuid/
$ mv ./quick_breakpad_example.sym symbols/quick_breakpad_example.pdb/$uuid/
$ ./breakpad/linux/$(arch)/minidump_stackwalk 34cd2b95-aef1-4003-ae75-1c848b18aad2.dmp symbols > quick_breakpad_example.log
```

3. Show parsed Linux log

- run on Linux

```sh
# bash or zsh
$ head -n 20 quick_breakpad_example.log
```

So the crash is at line 23 of `flutter_windows.cpp`

![image](https://user-images.githubusercontent.com/7928961/140525793-a5b71332-7a42-4eba-8b75-16a5acb78c4c.png)


## macOS

https://github.com/woodemi/quick_breakpad/issues/5

## Linux

- run on Linux

```sh
$ pushd example
$ flutter run -d linux
Building Linux application...                                           
Dump path: /tmp/d4a1c6ac-2ad7-4301-c22e3c9b-0a4c5588.dmp
$ popd
$ cp /tmp/d4a1c6ac-2ad7-4301-c22e3c9b-0a4c5588.dmp .
```

- parse the dump file

```sh
# flutterArch=x64 or arm64
$ $CLI_BREAKPAD/breakpad/linux/$(arch)/dump_syms build/linux/${flutterArch}/debug/bundle/quick_breakpad_example > quick_breakpad_example.sym
$ uuid=`awk 'FNR==1{print \$4}' quick_breakpad_example.sym`
$ mkdir -p symbols/quick_breakpad_example/$uuid/
$ mv ./quick_breakpad_example.sym symbols/quick_breakpad_example/$uuid/
$ $CLI_BREAKPAD/breakpad/linux/$(arch)/minidump_stackwalk d4a1c6ac-2ad7-4301-c22e3c9b-0a4c5588.dmp symbols/ > quick_breakpad_example.log
```

- Show parsed Linux log: `head -n 20 quick_breakpad_example.log`

So the crash is at line 19 of `my_application.cc`

![image](https://user-images.githubusercontent.com/7928961/135187002-2dd89e60-7cea-4cd0-a26b-f3d81e07d063.png)

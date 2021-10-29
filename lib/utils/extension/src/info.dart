part of '../extension.dart';

extension PackageInfoExtension on PackageInfo {
  String get versionAndBuildNumber =>
      '${this.version}${buildNumber.isEmpty ? '' : '($buildNumber)'}';
}

part of '../extension.dart';

extension PackageInfoExtension on PackageInfo {
  String get versionAndBuildNumber =>
      '$version${buildNumber.isEmpty ? '' : '($buildNumber)'}';
}

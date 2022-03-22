/// A callback provided to [MenuItem] to handle menu selection.
typedef MenuItemSelectedCallback = void Function();

/// The base type for an individual menu item that can be shown in a menu.
abstract class MenuItemBase {
  /// Creates a new menu item with the give label.
  const MenuItemBase(this.type, this.label);

  /// The displayed label for the menu item.
  final String type;
  final String label;
}

/// A standard menu item, with no submenus.
class MenuItem extends MenuItemBase {
  /// Creates a new menu item with the given [label] and options.
  ///
  /// Note that onClicked should generally be set unless [enabled] is false,
  /// or the menu item will be selectable but not do anything.
  MenuItem({
    required String label,
    this.enabled = true,
    this.onClicked,
  }) : super('lable', label);

  /// Whether or not the menu item is enabled.
  final bool enabled;

  /// The callback to call whenever the menu item is selected.
  final MenuItemSelectedCallback? onClicked;
}

/// A menu item continaing a submenu.
///
/// The item itself can't be selected, it just displays the submenu.
class SubMenu extends MenuItemBase {
  /// Creates a new submenu with the given [label] and [children].
  SubMenu({required String label, required this.children})
      : super('submenu', label);

  /// The menu items contained in the submenu.
  final List<MenuItemBase> children;
}

/// A menu item that serves as a separator, generally drawn as a line.
class MenuSeparator extends MenuItemBase {
  /// Creates a new separator item.
  MenuSeparator() : super('separator', '');
}

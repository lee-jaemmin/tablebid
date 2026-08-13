class SetMenuItemsModel {
  final int id;
  final int setMenuId;
  final int itemId;
  final int quantity;

  SetMenuItemsModel({
    required this.id,
    required this.setMenuId,
    required this.itemId,
    required this.quantity,
  });

  factory SetMenuItemsModel.fromJson(Map<String, dynamic> json) {
    return SetMenuItemsModel(
      id: json['id'],
      setMenuId: json['set_menu_id'],
      itemId: json['item_id'],
      quantity: json['quantity'],
    );
  }
}

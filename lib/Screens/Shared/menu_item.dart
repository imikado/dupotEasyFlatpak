class MenuItem {
  MenuItem(this.label, this.action, this.pageSelected, this.categoryIdSelected,
      this.badge);

  String label;
  Function action;
  String pageSelected;
  String categoryIdSelected;
  String badge;
}

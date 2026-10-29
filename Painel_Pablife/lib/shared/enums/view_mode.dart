enum ViewMode {
  grid,
  list;

  bool get isGrid => this == ViewMode.grid;
  bool get isList => this == ViewMode.list;
}

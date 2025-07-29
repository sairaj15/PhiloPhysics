// general.dart
sortMap(Map data, String valName) {
  var sortedEntries = data.entries.toList()
    ..sort((e1, e2) {
      final v1 = e1.value[valName];
      final v2 = e2.value[valName];
      if (v1 == null && v2 == null) return 0;
      if (v1 == null) return 1; // nulls last
      if (v2 == null) return -1;
      return v1.toString().compareTo(v2.toString());
    });

  Map data1 = {};
  for (int i = 0; i < sortedEntries.length; i++) {
    data1.putIfAbsent(sortedEntries[i].key, () => sortedEntries[i].value);
  }
  return data1;
}

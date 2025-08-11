import 'package:ephysicsapp/screens/Admin/vlabs_monthy_graph.dart';
import 'package:ephysicsapp/screens/Admin/vlabs_weekly_graph.dart';
import 'package:ephysicsapp/screens/Admin/vlabs_yearly_graph.dart';
import 'package:flutter/material.dart';
import 'package:material_segmented_control/material_segmented_control.dart';

class VLabUsageStatsPage extends StatefulWidget {
  @override
  _VLabUsageStatsPageState createState() => _VLabUsageStatsPageState();
}

class _VLabUsageStatsPageState extends State<VLabUsageStatsPage> {
  int _currentSelection = 0;
  final Map<int, Widget> _children = const {
    0: Text('Weekly'),
    1: Text('Monthly'),
    2: Text('Semester'),
  };

  @override
  Widget build(BuildContext context) {
    Widget _currentWidget;
    if (_currentSelection == 0) {
      _currentWidget = VLabWeeklyUsageGraph();
    } else if (_currentSelection == 1) {
      _currentWidget = VLabMonthlyUsageGraph();
    } else {
      _currentWidget = VLabYearlyUsageGraph();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("V-Lab Usage Statistics"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          MaterialSegmentedControl(
            children: _children,
            selectionIndex: _currentSelection,
            borderColor: Colors.black,
            selectedColor: Colors.purple,
            unselectedColor: Colors.white,
            selectedTextStyle: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            unselectedTextStyle: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
                fontSize: 17),
            borderWidth: 2,
            borderRadius: 32.0,
            onSegmentTapped: (index) {
              setState(() {
                _currentSelection =
                    index is int ? index : int.parse(index.toString());
              });
            },
          ),
          Expanded(child: _currentWidget),
        ],
      ),
    );
  }
}

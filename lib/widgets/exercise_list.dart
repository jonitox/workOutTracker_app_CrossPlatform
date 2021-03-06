import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/exercises.dart';
import '../providers/filters.dart';
import '../screens/insert_events_screen.dart';
import '../models/exercise.dart';
import './exercise_dialog.dart';
import './custom_floating_button.dart';
import './badge.dart';

// ************ exercise list ************ //
class ExerciseList extends StatefulWidget {
  final bool isForFilters;
  final bool isForManage;
  final bool isForInsert;
  final bool isForSelect;
  final bool isForRoutine;
  final bool isForAddExtra;
  final List<String> alreadySelected;
  final String selectedId;
  ExerciseList({
    this.isForManage = false,
    this.isForInsert = false,
    this.isForSelect = false,
    this.isForFilters = false,
    this.isForRoutine = false,
    this.isForAddExtra = false,
    this.selectedId,
    this.alreadySelected,
  });
  @override
  _ExerciseListState createState() => _ExerciseListState();
}

class _ExerciseListState extends State<ExerciseList> {
  String selectedId;
  String selectedTargetName = Target.all;
  Map<String, bool> isSelected;
  ScrollController _rowScrollController;
  ScrollController _columnScrollController;

  // init State
  void initState() {
    _rowScrollController = ScrollController();
    _columnScrollController = ScrollController();

    if (widget.isForInsert || widget.isForRoutine || widget.isForAddExtra) {
      isSelected = // get Map<String(id), bool> for selection check.
          Provider.of<Exercises>(context, listen: false).getExercisesSelection;
    }
    if (widget.isForSelect) {
      selectedId = widget.selectedId; // already selected item
    }
    super.initState();
  }

  // dispose
  @override
  void dispose() {
    _rowScrollController.dispose();
    _columnScrollController.dispose();
    super.dispose();
  }

// ************ build widget(exercise list with cartegory) ************ //
  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final themeData = Theme.of(context);
    print('build Exercise List!');
    // * At exercise dialog by edit event screen & adding extra event *//
    if (widget.isForSelect || widget.isForAddExtra) {
      return Container(
        height: deviceSize.height / 2,
        width: deviceSize.width - 100,
        child: Column(
          // mainAxisSize: MainAxisSize.min,
          children: [
            categoriesBox,
            Expanded(child: exercisesListTiles),
            ElevatedButton(
                style:
                    ElevatedButton.styleFrom(primary: themeData.primaryColor),
                onPressed: () {
                  Navigator.of(context)
                      .pop(widget.isForSelect ? selectedId : isSelected);
                },
                child: const Text('선택완료'))
          ],
        ),
      );
    } else if (widget.isForFilters) {
      // * At filters dialog *//
      return Container(
        height: deviceSize.height * 0.5,
        width: deviceSize.width * 0.7,
        child: Column(
          children: [
            categoriesBox,
            Expanded(child: exercisesListTiles),
            SizedBox(height: 5),
            ElevatedButton(
              style: ElevatedButton.styleFrom(primary: themeData.primaryColor),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Container(
                width: deviceSize.width * 0.5,
                child: Center(
                  child: const Text(
                    '완료',
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // * At manageScreen *//
      return Column(
        children: [
          categoriesBox,
          Expanded(child: exercisesListTiles),
          Divider(),
          if (widget.isForManage)
            floatingButton(
              isBadge: false,
              text: '운동 추가하기',
              icon: Icons.add,
              onPressed: () => showDialog(
                context: context,
                builder: (bctx) => ExerciseDialog(true, selectedTargetName),
                barrierDismissible: true,
              ),
            ),
          if (widget.isForInsert || widget.isForRoutine)
            floatingButton(
              isBadge: true,
              text: '선택 완료',
              color: isSelected.containsValue(true)
                  ? Colors.deepOrange
                  : Colors.grey,
              onPressed: isSelected.containsValue(true)
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => InsertEventsScreen(
                            isRawInsert: true,
                            isForRoutine: widget.isForRoutine,
                            exerciseIds: isSelected.entries
                                .where((entry) => entry.value == true)
                                .map((entry) => entry.key)
                                .toList(),
                          ),
                        ),
                      )
                  : null,
            ),
        ],
      );
    }
  }

  // ************ categories box ************ //
  Widget get categoriesBox {
    return Scrollbar(
      controller: _rowScrollController,
      child: SingleChildScrollView(
        controller: _rowScrollController,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: Target.values
                .map(
                  (targetName) => GestureDetector(
                    // border, clip
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Chip(
                        backgroundColor: selectedTargetName == targetName
                            ? Colors.deepOrange
                            : Colors.grey[300],
                        label: Text(
                          targetName,
                          style: TextStyle(
                              color: selectedTargetName == targetName
                                  ? Colors.white
                                  : Colors.black),
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selectedTargetName = targetName;
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  // ************ exercise tiles list ************ //
  Widget get exercisesListTiles {
    return Consumer<Exercises>(
      builder: (ctx, exercises, _) {
        print('build exercisesColumn!');
        final items = exercises.getExercisesByTarget(selectedTargetName);
        // remove already selected exercises when inserting events
        if (widget.isForAddExtra) {
          items.removeWhere((ex) => widget.alreadySelected.contains(ex.id));
        }
        return Scrollbar(
          controller: _columnScrollController,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (ctx, i) =>
                exerciseTile(items[i], ValueKey(items[i].id)),
          ),
        );
      },
    );
  }

  // ************ exercise tile ************ //
  Widget exerciseTile(Exercise ex, Key key) {
    // for insert Events & for make routine
    if (widget.isForInsert || widget.isForRoutine || widget.isForAddExtra) {
      return GestureDetector(
        key: key,
        onTap: () {
          setState(() {
            isSelected[ex.id] = !isSelected[ex.id];
          });
        },
        child: Container(
          color: isSelected[ex.id] ? Colors.amber[200] : Colors.white,
          child: ListTile(
            title: Text(
              ex.name,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isSelected[ex.id] ? Icon(Icons.check) : null,
          ),
        ),
      );
    } else if (widget.isForSelect) {
      // for select exercise when editing event
      return GestureDetector(
        key: key,
        onTap: () {
          setState(() {
            selectedId = ex.id;
          });
        },
        child: Container(
          color: selectedId == ex.id ? Colors.amber[200] : Colors.white,
          child: ListTile(
            title: Text(ex.name),
            trailing: selectedId == ex.id ? const Icon(Icons.check) : null,
          ),
        ),
      );
    } else if (widget.isForFilters) {
      // for filters dialog
      return Consumer<Filters>(
        key: key,
        builder: (ctx, filters, ch) {
          return GestureDetector(
            onTap: () {
              filters.switchItem(ex.id);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(child: ch),
                  Icon(filters.items[ex.id]
                      ? Icons.check_box_outlined
                      : Icons.check_box_outline_blank),
                ],
              ),
            ),
          );
        },
        child: Text(
          ex.name,
          style: TextStyle(fontSize: 18),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      );
    } else
      // for manage screen
      return GestureDetector(
        key: key,
        onTap: () => showDialog(
          context: context,
          builder: (bctx) => ExerciseDialog(false, ex.target.value, id: ex.id),
          barrierDismissible: true,
        ),
        child: ListTile(
          title: Text(
            ex.name,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
  }

  // ************ floating button ************ //
  Widget floatingButton(
      {bool isBadge,
      String text,
      Function onPressed,
      IconData icon,
      Color color}) {
    final btn = CustomFloatingButton(
      color: color ?? Colors.deepOrange,
      name: text,
      onPressed: onPressed,
      icon: icon,
    );
    return isBadge
        ? Badge(
            child: btn,
            value: isSelected.values
                .fold(0, (cnt, x) => x ? cnt + 1 : cnt)
                .toString(),
          )
        : btn;
  }
}

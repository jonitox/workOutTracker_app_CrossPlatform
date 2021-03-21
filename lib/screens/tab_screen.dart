import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/events.dart';
import '../providers/exercises.dart';
import '../providers/routines.dart';
import '../providers/filters.dart';
import '../providers/tap_page_index.dart';

import './manage_screen.dart';
import './calendar_screen.dart';
import './functions_screen.dart';
import './home_screen.dart';

import '../widgets/filters_dialog.dart';

class TabScreen extends StatelessWidget {
  final List<Map<String, Object>> _pages = [
    {'title': 'MUPPLER', 'page': HomeScreen()},
    {'title': '', 'page': CalendarScreen()},
    {'title': '운동/루틴 라이브러리', 'page': ManageScreen()},
    {'title': '다양한 기능을 사용해보세요.', 'page': FuncionsScreen()},
  ];

  Future<void> fetchAndSetDatas(BuildContext ctx) async {
    await Provider.of<Events>(ctx, listen: false).fetchAndSetEvents();
    await Provider.of<Routines>(ctx, listen: false).fetchAndSetRotuines();
    final ids =
        await Provider.of<Exercises>(ctx, listen: false).fetchAndSetExercises();
    Provider.of<Filters>(ctx, listen: false).addFilters(ids);
  }

  // tap set Filter button

  @override
  Widget build(BuildContext context) {
    print('build tapScreen!');
    return Scaffold(
      appBar: AppBar(
        leading: Consumer<TapPageIndex>(
          builder: (ctx, pageIdx, _) {
            if (pageIdx.curIdx == 3 && pageIdx.funcPageIdx > 0) {
              return IconButton(
                  icon: Icon(Icons.keyboard_arrow_left_rounded),
                  onPressed: () {
                    pageIdx.moveFuncPage(0);
                  });
            } else {
              return Container();
            }
          },
        ),
        title: Consumer<TapPageIndex>(
          builder: (ctx, pageIdx, _) => Text(
            _pages[pageIdx.curIdx]['title'],
            style: Theme.of(context).appBarTheme.titleTextStyle.copyWith(
                fontSize: pageIdx.curIdx == 0 ? 34 : 24,
                color: pageIdx.curIdx == 0 ? Colors.deepOrange : Colors.white,
                fontWeight:
                    pageIdx.curIdx == 0 ? FontWeight.w900 : FontWeight.bold),
          ),
        ),
        bottom: PreferredSize(
          child: Container(
            color: Colors.teal[400],
            height: 2,
          ),
          preferredSize: Size.fromHeight(2),
        ),
      ),
      body: FutureBuilder(
        future: fetchAndSetDatas(context),
        builder: (ctx, snapshot) {
          return snapshot.connectionState == ConnectionState.waiting
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Consumer<TapPageIndex>(
                  builder: (ctx, pageIdx, _) => _pages[pageIdx.curIdx]['page'],
                );
        },
      ),
      bottomNavigationBar: Consumer<TapPageIndex>(
        builder: (ctx, pageIdx, _) => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: '운동 기록',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: '라이브러리',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer),
              label: '기능',
            ),
          ],
          currentIndex: pageIdx.curIdx,
          onTap: (idx) {
            pageIdx.movePage(idx);
          },
        ),
      ),
    );
  }
}

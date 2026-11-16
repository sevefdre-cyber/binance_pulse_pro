import 'package:flutter/cupertino.dart';
import 'tabs/debug_tab.dart';
import 'tabs/ranking_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/simulator_tab.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.88),
        activeColor: const Color(0xFF30D158),
        inactiveColor: CupertinoColors.systemGrey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.flame_fill),
            label: 'Classement',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_alt_fill),
            label: 'Simulateur',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.slider_horizontal_3),
            label: 'Scan & Risque',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.ant_fill),
            label: 'Debug Log',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const RankingTab();
          case 1:
            return const SimulatorTab();
          case 2:
            return const SettingsTab();
          default:
            return const DebugTab();
        }
      },
    );
  }
}

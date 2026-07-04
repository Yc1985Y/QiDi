import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/inbox_message.dart';
import '../models/source_info.dart';
import '../services/api_config.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/event_card.dart';
import '../widgets/weaving_widgets.dart';

enum ProfileRoute {
  dashboard,
  agentCenter,
  agentCheckup,
  history,
  statistics,
  achievements,
  preferences,
  account,
  settings,
  personalInfo,
  persona,
  reminderCenter,
  timelineAssets,
  exportRecords,
  runtimeStatus,
  notificationInbox,
  privacySecurity,
  dataSpace,
}

enum InboxFilter { all, pending, feedback }

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileRoute _route = ProfileRoute.dashboard;
  final List<ProfileRoute> _routeStack = [ProfileRoute.dashboard];

  void _push(ProfileRoute route) {
    if (_route == route) return;
    setState(() {
      _route = route;
      _routeStack.add(route);
    });
  }

  void _pop() {
    if (_routeStack.length <= 1) return;
    setState(() {
      _routeStack.removeLast();
      _route = _routeStack.last;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return PopScope(
          canPop: _route == ProfileRoute.dashboard,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || _route == ProfileRoute.dashboard) return;
            _pop();
          },
          child: WeavingBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _ProfileHeaderBar(
                    title: _titleForRoute(_route),
                    showBack: _route != ProfileRoute.dashboard,
                    onBack: _pop,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(
                        key: ValueKey(_route),
                        child: _buildRoute(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoute() {
    final controller = widget.controller;
    switch (_route) {
      case ProfileRoute.dashboard:
        return _DashboardPage(controller: controller, onNavigate: _push);
      case ProfileRoute.agentCenter:
        return _AgentCenterPage(controller: controller, onNavigate: _push);
      case ProfileRoute.agentCheckup:
        return _AgentCheckupPage(controller: controller, onNavigate: _push);
      case ProfileRoute.history:
        return _HistoryPage(controller: controller);
      case ProfileRoute.statistics:
        return _StatisticsPage(controller: controller);
      case ProfileRoute.achievements:
        return _AchievementsPage(controller: controller);
      case ProfileRoute.preferences:
        return _PreferencesPage(controller: controller);
      case ProfileRoute.account:
        return _AccountPage(controller: controller, onNavigate: _push);
      case ProfileRoute.settings:
        return _SettingsPage(controller: controller, onNavigate: _push);
      case ProfileRoute.personalInfo:
        return _PersonalInfoPage(controller: controller);
      case ProfileRoute.persona:
        return _PersonaPage(controller: controller);
      case ProfileRoute.reminderCenter:
        return _ReminderCenterPage(controller: controller);
      case ProfileRoute.timelineAssets:
        return _TimelineAssetsPage(controller: controller);
      case ProfileRoute.exportRecords:
        return _ExportRecordsPage(controller: controller);
      case ProfileRoute.runtimeStatus:
        return _RuntimeStatusPage(controller: controller);
      case ProfileRoute.notificationInbox:
        return _NotificationInboxPage(
          controller: controller,
          onNavigate: _push,
        );
      case ProfileRoute.privacySecurity:
        return _PrivacySecurityPage(controller: controller);
      case ProfileRoute.dataSpace:
        return _DataSpacePage(controller: controller, onNavigate: _push);
    }
  }

  String _titleForRoute(ProfileRoute route) {
    switch (route) {
      case ProfileRoute.dashboard:
        return '我的';
      case ProfileRoute.agentCenter:
        return '智能体中心';
      case ProfileRoute.agentCheckup:
        return '智能体体检';
      case ProfileRoute.history:
        return '历史记录';
      case ProfileRoute.statistics:
        return '统计';
      case ProfileRoute.achievements:
        return '我的成就';
      case ProfileRoute.preferences:
        return '偏好设置';
      case ProfileRoute.account:
        return '账号';
      case ProfileRoute.settings:
        return '设置';
      case ProfileRoute.personalInfo:
        return '个人信息';
      case ProfileRoute.persona:
        return '用户画像';
      case ProfileRoute.reminderCenter:
        return '提醒中心';
      case ProfileRoute.timelineAssets:
        return '时间线资产';
      case ProfileRoute.exportRecords:
        return '导出记录';
      case ProfileRoute.runtimeStatus:
        return '运行状态';
      case ProfileRoute.notificationInbox:
        return '通知中心';
      case ProfileRoute.privacySecurity:
        return '隐私与安全';
      case ProfileRoute.dataSpace:
        return '数据空间';
    }
  }
}

class _ProfileHeaderBar extends StatelessWidget {
  const _ProfileHeaderBar({
    required this.title,
    required this.showBack,
    required this.onBack,
  });

  final String title;
  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          if (showBack) ...[
            IconButton.filledTonal(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: '返回',
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.controller, required this.onNavigate});

  final AppController controller;
  final ValueChanged<ProfileRoute> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ProfileIdentityCard(controller: controller, onNavigate: onNavigate),
        const SizedBox(height: 14),
        _ProfileShortcutGrid(
          onOpenSettings: () => onNavigate(ProfileRoute.settings),
          onOpenHistory: () => onNavigate(ProfileRoute.history),
          onOpenStatistics: () => onNavigate(ProfileRoute.statistics),
          onOpenAccount: () => onNavigate(ProfileRoute.account),
        ),
        const SizedBox(height: 14),
        _ScheduleBoardCard(
          todayAgendaCount: controller.todayEvents.length,
          pendingAgendaCount: controller.pendingNotices.length,
          scheduledReminderCount: controller.scheduledReminderCount,
          onOpenTimelineAssets: () => onNavigate(ProfileRoute.timelineAssets),
          onTodayAgendaClick: () => onNavigate(ProfileRoute.timelineAssets),
          onPendingClick: () => onNavigate(ProfileRoute.notificationInbox),
          onReminderClick: () => onNavigate(ProfileRoute.reminderCenter),
        ),
        const SizedBox(height: 14),
        _AgentCenterEntryCard(
          confirmedAgendaCount: controller.confirmedEvents.length,
          pendingAgendaCount: controller.pendingNotices.length,
          scheduledReminderCount: controller.scheduledReminderCount,
          activePolicyCount: _buildActivePolicyCount(controller),
          onOpenTimelineAssets: () => onNavigate(ProfileRoute.timelineAssets),
          onOpenAgentCenter: () => onNavigate(ProfileRoute.agentCenter),
        ),
      ],
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.controller,
    required this.onNavigate,
  });

  final AppController controller;
  final ValueChanged<ProfileRoute> onNavigate;

  @override
  Widget build(BuildContext context) {
    final preference = controller.preference;
    final nickname = preference.nickname.trim().isEmpty
        ? '织时用户'
        : preference.nickname.trim();
    final avatarPath = preference.avatarPath.trim();
    final signature = preference.signature.trim();
    final schoolLine = _buildProfileLine(
      account: controller.currentAccountLabel,
      school: preference.school.trim(),
      major: preference.major.trim(),
      grade: preference.grade.trim(),
    );
    final briefLine = _buildProfileBrief(
      birthday: preference.birthday.trim(),
      age: preference.age.trim(),
      gender: preference.gender.trim(),
      hometown: preference.hometown.trim(),
    );

    return WeavingCard(
      onTap: () => onNavigate(ProfileRoute.personalInfo),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: AppColors.coral,
            backgroundImage:
                avatarPath.isNotEmpty && File(avatarPath).existsSync()
                ? FileImage(File(avatarPath))
                : null,
            child: avatarPath.isNotEmpty && File(avatarPath).existsSync()
                ? null
                : Text(
                    nickname.characters.first,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  schoolLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  signature.isEmpty ? briefLine : signature,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileShortcutGrid extends StatelessWidget {
  const _ProfileShortcutGrid({
    required this.onOpenSettings,
    required this.onOpenHistory,
    required this.onOpenStatistics,
    required this.onOpenAccount,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      child: Row(
        children: [
          _ShortcutEntry(
            icon: Icons.settings_rounded,
            label: '设置',
            background: AppColors.gold,
            onTap: onOpenSettings,
          ),
          const SizedBox(width: 10),
          _ShortcutEntry(
            icon: Icons.history_rounded,
            label: '历史',
            background: AppColors.primarySoft,
            onTap: onOpenHistory,
          ),
          const SizedBox(width: 10),
          _ShortcutEntry(
            icon: Icons.query_stats_rounded,
            label: '统计',
            background: AppColors.coral,
            onTap: onOpenStatistics,
          ),
          const SizedBox(width: 10),
          _ShortcutEntry(
            icon: Icons.manage_accounts_rounded,
            label: '账号',
            background: Colors.white.withValues(alpha: 0.82),
            onTap: onOpenAccount,
          ),
        ],
      ),
    );
  }
}

class _ShortcutEntry extends StatelessWidget {
  const _ShortcutEntry({
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleBoardCard extends StatelessWidget {
  const _ScheduleBoardCard({
    required this.todayAgendaCount,
    required this.pendingAgendaCount,
    required this.scheduledReminderCount,
    required this.onOpenTimelineAssets,
    required this.onTodayAgendaClick,
    required this.onPendingClick,
    required this.onReminderClick,
  });

  final int todayAgendaCount;
  final int pendingAgendaCount;
  final int scheduledReminderCount;
  final VoidCallback onOpenTimelineAssets;
  final VoidCallback onTodayAgendaClick;
  final VoidCallback onPendingClick;
  final VoidCallback onReminderClick;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      color: AppColors.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('日程表', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      '把今天与后续提醒整理在一张看板里',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onOpenTimelineAssets,
                icon: const Icon(Icons.calendar_month_rounded),
                tooltip: '打开时间线',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DashboardMetricPill(
                  title: '今日安排',
                  value: '$todayAgendaCount',
                  icon: Icons.calendar_month_rounded,
                  background: AppColors.gold,
                  onTap: onTodayAgendaClick,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardMetricPill(
                  title: '待确认',
                  value: '$pendingAgendaCount',
                  icon: Icons.shield_rounded,
                  background: AppColors.coral,
                  onTap: onPendingClick,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardMetricPill(
                  title: '待提醒',
                  value: '$scheduledReminderCount',
                  icon: Icons.notifications_active_rounded,
                  background: AppColors.primarySoft,
                  onTap: onReminderClick,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenTimelineAssets,
              icon: const Icon(Icons.timeline_rounded),
              label: const Text('查看完整时间线'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricPill extends StatelessWidget {
  const _DashboardMetricPill({
    required this.title,
    required this.value,
    required this.icon,
    required this.background,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 108,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _AgentCenterEntryCard extends StatelessWidget {
  const _AgentCenterEntryCard({
    required this.confirmedAgendaCount,
    required this.pendingAgendaCount,
    required this.scheduledReminderCount,
    required this.activePolicyCount,
    required this.onOpenTimelineAssets,
    required this.onOpenAgentCenter,
  });

  final int confirmedAgendaCount;
  final int pendingAgendaCount;
  final int scheduledReminderCount;
  final int activePolicyCount;
  final VoidCallback onOpenTimelineAssets;
  final VoidCallback onOpenAgentCenter;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      onTap: onOpenAgentCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoChip(
                      label: '更多功能',
                      icon: Icons.psychology_rounded,
                      backgroundColor: AppColors.primarySoft,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '把低频功能收进二级空间',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '成就、画像、提醒策略、隐私边界与导出入口都集中在这里，第一屏只保留高频操作。',
                      style: TextStyle(color: AppColors.muted, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CenterStatusPill(
                  title: '资产',
                  value: '$confirmedAgendaCount',
                  background: AppColors.primarySoft,
                  onTap: onOpenTimelineAssets,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CenterStatusPill(
                  title: '待确认',
                  value: '$pendingAgendaCount',
                  background: AppColors.coral,
                  onTap: onOpenAgentCenter,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CenterStatusPill(
                  title: '提醒',
                  value: '$scheduledReminderCount',
                  background: AppColors.gold,
                  onTap: onOpenAgentCenter,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CenterStatusPill(
                  title: '策略',
                  value: '$activePolicyCount/3',
                  background: Colors.white.withValues(alpha: 0.82),
                  onTap: onOpenAgentCenter,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CenterStatusPill extends StatelessWidget {
  const _CenterStatusPill({
    required this.title,
    required this.value,
    required this.background,
    required this.onTap,
  });

  final String title;
  final String value;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(title, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _AgentCenterPage extends StatelessWidget {
  const _AgentCenterPage({required this.controller, required this.onNavigate});

  final AppController controller;
  final ValueChanged<ProfileRoute> onNavigate;

  @override
  Widget build(BuildContext context) {
    final featureItems = _dashboardFeatureItems(controller, onNavigate);
    final systemItems = _agentCenterSystemItems(controller, onNavigate);
    final checkupItems = _buildCheckupItems(controller);
    final issueCount = checkupItems
        .where((item) => item.level != _CheckupLevel.ready)
        .length;
    final checkupScore = _calculateCheckupScore(checkupItems);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              value: '${controller.confirmedEvents.length}',
              label: '已确认',
              color: AppColors.primarySoft,
            ),
            _MetricBox(
              value: '${controller.scheduledReminderCount}',
              label: '待提醒',
              color: AppColors.gold,
            ),
            _MetricBox(
              value: '${controller.pendingNotices.length}',
              label: '待确认',
              color: AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '能力链路',
          summary: '导入、校验、提醒与资产回看',
          child: Row(
            children: [
              Expanded(
                child: _FlowMiniTile(
                  icon: Icons.history_rounded,
                  title: '回看',
                  summary: '${controller.confirmedEvents.length} 条资产',
                  background: AppColors.primarySoft,
                  onTap: () => onNavigate(ProfileRoute.timelineAssets),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FlowMiniTile(
                  icon: Icons.shield_rounded,
                  title: '校验',
                  summary: '${controller.pendingNotices.length} 条待办',
                  background: AppColors.coral,
                  onTap: () => onNavigate(ProfileRoute.notificationInbox),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FlowMiniTile(
                  icon: Icons.notifications_active_rounded,
                  title: '守护',
                  summary: '${controller.scheduledReminderCount} 条提醒',
                  background: AppColors.gold,
                  onTap: () => onNavigate(ProfileRoute.reminderCenter),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        WeavingCard(
          onTap: () => onNavigate(ProfileRoute.agentCheckup),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: issueCount == 0
                      ? AppColors.primarySoft
                      : AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '智能体一键体检',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: issueCount == 0
                                ? AppColors.primarySoft
                                : AppColors.coral,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$checkupScore 分',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      issueCount == 0
                          ? '时间线、提醒、风险边界与消息收纳状态良好。'
                          : '发现 $issueCount 项可优化内容，点进后可逐项处理。',
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '功能地图',
          summary: '二级页统一承接低频能力，避免我的页第一屏继续堆长列表。',
          child: _NavGrid(items: featureItems),
        ),
        const SizedBox(height: 14),
        _PreferenceOverviewCard(
          controller: controller,
          onOpenPreferences: () => onNavigate(ProfileRoute.preferences),
        ),
        const SizedBox(height: 14),
        _AchievementPreviewCard(
          controller: controller,
          onOpenAll: () => onNavigate(ProfileRoute.achievements),
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '系统入口',
          summary: '完整工具链仍然可达，但不再压在第一界面。',
          child: _NavGrid(items: systemItems),
        ),
      ],
    );
  }
}

class _FlowMiniTile extends StatelessWidget {
  const _FlowMiniTile({
    required this.icon,
    required this.title,
    required this.summary,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String summary;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 124),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceOverviewCard extends StatelessWidget {
  const _PreferenceOverviewCard({
    required this.controller,
    required this.onOpenPreferences,
  });

  final AppController controller;
  final VoidCallback onOpenPreferences;

  @override
  Widget build(BuildContext context) {
    final preference = controller.preference;
    return WeavingCard(
      onTap: onOpenPreferences,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('边界控制', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text(
            '关键开关仍可在更多功能页直接调整，减少跳转成本。',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 12),
          _PreferenceStatusRow(
            title: '高风险拦截',
            value: preference.blockHighRisk ? '已开启' : '未开启',
          ),
          _PreferenceStatusRow(
            title: '低置信静默',
            value: preference.muteLowConfidence ? '已开启' : '未开启',
          ),
          _PreferenceStatusRow(
            title: '自动地图联动',
            value: preference.autoMapLink ? '已开启' : '未开启',
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _PreferenceStatusRow extends StatelessWidget {
  const _PreferenceStatusRow({
    required this.title,
    required this.value,
    this.compact = false,
  });

  final String title;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 0 : 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(value, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _AchievementPreviewCard extends StatelessWidget {
  const _AchievementPreviewCard({
    required this.controller,
    required this.onOpenAll,
  });

  final AppController controller;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '成就勋章',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(onPressed: onOpenAll, child: const Text('查看全部')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AchievementBadge(
                  title: '海报小能手',
                  subtitle: '累计沉淀 ${controller.confirmedEvents.length} 条安排',
                  background: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AchievementBadge(
                  title: '考试周守护者',
                  subtitle: '仍有 ${controller.pendingNotices.length} 条待确认',
                  background: AppColors.primarySoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AchievementBadge(
                  title: '低噪规划师',
                  subtitle: '已挂载 ${controller.scheduledReminderCount} 条提醒',
                  background: AppColors.coral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.title,
    required this.subtitle,
    required this.background,
  });

  final String title;
  final String subtitle;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _HistoryPage extends StatefulWidget {
  const _HistoryPage({required this.controller});

  final AppController controller;

  @override
  State<_HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<_HistoryPage> {
  final TextEditingController _query = TextEditingController();
  String _dateFilter = '全部';
  String _statusFilter = '全部';
  String _sourceFilter = '全部';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.controller.confirmedEvents;
    final sourceOptions = [
      '全部',
      ...events
          .map(
            (event) =>
                event.source.label.trim().isEmpty ? '未知来源' : event.source.label,
          )
          .toSet(),
    ];
    final query = _query.text.trim().toLowerCase();
    final filtered =
        events.where((event) {
          final matchesQuery =
              query.isEmpty ||
              event.title.toLowerCase().contains(query) ||
              (event.location ?? '').toLowerCase().contains(query) ||
              (event.description ?? '').toLowerCase().contains(query) ||
              event.source.label.toLowerCase().contains(query);
          if (!matchesQuery) return false;
          if (_dateFilter == '今日' &&
              !ZhishiDateUtils.isToday(event.startTimeIso)) {
            return false;
          }
          if (_dateFilter == '本周') {
            final start = event.startTime;
            if (start == null) return false;
            final now = DateTime.now();
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 7));
            if (start.isBefore(weekStart) || !start.isBefore(weekEnd)) {
              return false;
            }
          }
          if (_dateFilter == '待定' &&
              !(event.startTimeIso == null ||
                  event.startTimeIso!.trim().isEmpty)) {
            return false;
          }
          if (_statusFilter == '已确认' &&
              !event.status.contains('确认') &&
              !event.status.contains('加入')) {
            return false;
          }
          if (_statusFilter == '待校验' && !event.status.contains('待')) {
            return false;
          }
          final sourceLabel = event.source.label.trim().isEmpty
              ? '未知来源'
              : event.source.label;
          if (_sourceFilter != '全部' && sourceLabel != _sourceFilter) {
            return false;
          }
          return true;
        }).toList()..sort((left, right) {
          final leftTime = left.startTime ?? left.deadline ?? DateTime(1900);
          final rightTime = right.startTime ?? right.deadline ?? DateTime(1900);
          final compare = rightTime.compareTo(leftTime);
          if (compare != 0) return compare;
          return left.title.compareTo(right.title);
        });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SectionBlock(
          title: '历史资产检索',
          summary: '按标题、地点、来源快速定位',
          child: Column(
            children: [
              TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: '搜索讲座、地点、摘要或来源...',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.76),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _ChoiceWrap(
                values: const ['全部', '今日', '本周', '待定'],
                selected: _dateFilter,
                onSelect: (value) => setState(() => _dateFilter = value),
              ),
              const SizedBox(height: 10),
              _ChoiceWrap(
                values: const ['全部', '已确认', '待校验'],
                selected: _statusFilter,
                onSelect: (value) => setState(() => _statusFilter = value),
              ),
              const SizedBox(height: 10),
              _ChoiceWrap(
                values: sourceOptions,
                selected: _sourceFilter,
                onSelect: (value) => setState(() => _sourceFilter = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '检索结果',
          summary: '当前命中 ${filtered.length} / ${events.length} 条，可回看或重新解析。',
          child: filtered.isEmpty
              ? EmptyState(
                  title: '暂无匹配记录',
                  summary: '可以切换日期、状态或来源筛选，也可以回到首页继续导入通知。',
                  actionLabel: '回首页',
                  onAction: () => widget.controller.setTab(0),
                )
              : Column(
                  children: filtered
                      .map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: EventCard(
                            event: event,
                            onEdit: () => widget.controller.reparseEvent(event),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => widget.controller.setTab(1),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('进入时间线总览'),
          ),
        ),
      ],
    );
  }
}

class _StatisticsPage extends StatelessWidget {
  const _StatisticsPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final sourceCounts = <String, int>{};
    for (final event in controller.confirmedEvents) {
      final key = event.source.label.trim().isEmpty
          ? '未知来源'
          : event.source.label;
      sourceCounts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              value: '${controller.confirmedEvents.length}',
              label: '已确认',
              color: AppColors.primarySoft,
            ),
            _MetricBox(
              value: '${controller.pendingNotices.length}',
              label: '待确认',
              color: AppColors.gold,
            ),
            _MetricBox(
              value: '${controller.exportRecords.length}',
              label: '已导出',
              color: AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 14),
        WeavingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('来源统计', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (sourceCounts.isEmpty)
                const Text(
                  '暂无已确认来源统计',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                ...sourceCounts.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text(
                          '${entry.value} 条',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementsPage extends StatelessWidget {
  const _AchievementsPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final confirmedCount = controller.confirmedEvents.length;
    final reminderCount = controller.scheduledReminderCount;
    final pendingCount = controller.pendingNotices.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              value: '$confirmedCount',
              label: '沉淀',
              color: AppColors.gold,
            ),
            _MetricBox(
              value: '$reminderCount',
              label: '提醒',
              color: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '徽章墙',
          summary: '用成就反馈强化长期习惯，沉淀可复盘的时间管理结果。',
          child: _NavGrid(
            items: [
              _NavItemSpec(
                Icons.auto_graph_rounded,
                '海报小能手',
                '已累计沉淀 $confirmedCount 条安排',
                null,
                color: AppColors.gold,
              ),
              _NavItemSpec(
                Icons.notifications_active_rounded,
                '低噪规划师',
                '已挂载 $reminderCount 条提醒',
                null,
                color: AppColors.primarySoft,
              ),
              _NavItemSpec(
                Icons.shield_rounded,
                '校验守门人',
                '$pendingCount 条待确认，保持 HITL',
                null,
                color: AppColors.coral,
              ),
              const _NavItemSpec(
                Icons.timeline_rounded,
                '时间线织工',
                '持续把碎片织成秩序',
                null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '解锁路径',
          summary: '继续用真实导入、真实校验和真实导出累积长期反馈。',
          child: const Column(
            children: [
              _DetailGuideRow(
                icon: Icons.history_rounded,
                title: '连续织入',
                summary: '连续把讲座、会议和群通知转为时间线，可提升徽章等级。',
              ),
              SizedBox(height: 10),
              _DetailGuideRow(
                icon: Icons.query_stats_rounded,
                title: '低置信度校验',
                summary: '主动修正时间和地点字段，可强化安全型成就。',
              ),
              SizedBox(height: 10),
              _DetailGuideRow(
                icon: Icons.download_rounded,
                title: '时间线导出',
                summary: '导出时间线资产后，可补充复盘型徽章。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        WeavingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('下一枚徽章', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('连续织入', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                '继续把讲座、会议和群通知转为时间线，可解锁更高等级的低噪规划徽章。',
                style: TextStyle(color: AppColors.muted, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferencesPage extends StatelessWidget {
  const _PreferencesPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final preference = controller.preference;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SwitchTile(
          title: '提前一天预热',
          subtitle: '为已确认事项保留一天前提醒。',
          value: preference.dayReminderEnabled,
          onChanged: (value) => controller.savePreference(
            preference.copyWith(dayReminderEnabled: value),
          ),
        ),
        _SwitchTile(
          title: '临近前提醒',
          subtitle: '使用分钟级提醒覆盖最近时间点。',
          value: preference.hourReminderEnabled,
          onChanged: (value) => controller.savePreference(
            preference.copyWith(hourReminderEnabled: value),
          ),
        ),
        _ReminderLeadTile(controller: controller),
        _SwitchTile(
          title: '高风险动作拦截',
          subtitle: '考试、截止、地点不明等事项先经过你确认。',
          value: preference.blockHighRisk,
          onChanged: (value) => controller.savePreference(
            preference.copyWith(blockHighRisk: value),
          ),
        ),
        _SwitchTile(
          title: '低置信静默处理',
          subtitle: '降低误写入时间线的概率。',
          value: preference.muteLowConfidence,
          onChanged: (value) => controller.savePreference(
            preference.copyWith(muteLowConfidence: value),
          ),
        ),
        _SwitchTile(
          title: '自动地图联动',
          subtitle: '地点完整时允许直接拉起地图。',
          value: preference.autoMapLink,
          onChanged: (value) => controller.savePreference(
            preference.copyWith(autoMapLink: value),
          ),
        ),
      ],
    );
  }
}

class _AccountPage extends StatelessWidget {
  const _AccountPage({required this.controller, required this.onNavigate});

  final AppController controller;
  final ValueChanged<ProfileRoute> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _NavGrid(
          items: [
            _NavItemSpec(
              Icons.badge_outlined,
              '个人信息',
              '编辑昵称、学校、专业与头像',
              () => onNavigate(ProfileRoute.personalInfo),
            ),
            _NavItemSpec(
              Icons.tune_rounded,
              '设置',
              '偏好、提醒与隐私策略',
              () => onNavigate(ProfileRoute.settings),
            ),
            _NavItemSpec(
              Icons.person_search_outlined,
              '用户画像',
              '基于真实使用状态推断',
              () => onNavigate(ProfileRoute.persona),
            ),
            _NavItemSpec(
              Icons.workspace_premium_outlined,
              '我的成就',
              '查看沉淀结果与展示亮点',
              () => onNavigate(ProfileRoute.achievements),
            ),
          ],
        ),
        const SizedBox(height: 14),
        WeavingCard(
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.logoutAccount,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('退出登录'),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.controller, required this.onNavigate});

  final AppController controller;
  final ValueChanged<ProfileRoute> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _NavGrid(
          items: [
            _NavItemSpec(
              Icons.tune_rounded,
              '偏好设置',
              '提醒、风控、地图与性能',
              () => onNavigate(ProfileRoute.preferences),
            ),
            _NavItemSpec(
              Icons.alarm_rounded,
              '提醒中心',
              '重排本地提醒与查看覆盖率',
              () => onNavigate(ProfileRoute.reminderCenter),
            ),
            _NavItemSpec(
              Icons.notifications_active_rounded,
              '通知中心',
              '${controller.inboxMessages.length} 条系统记录',
              () => onNavigate(ProfileRoute.notificationInbox),
            ),
            _NavItemSpec(
              Icons.speed_rounded,
              '运行状态',
              '模型、OCR、权限与存储',
              () => onNavigate(ProfileRoute.runtimeStatus),
            ),
            _NavItemSpec(
              Icons.shield_rounded,
              '隐私与安全',
              '高风险拦截与低置信策略',
              () => onNavigate(ProfileRoute.privacySecurity),
            ),
            _NavItemSpec(
              Icons.storage_rounded,
              '数据空间',
              '时间资产与导出记录',
              () => onNavigate(ProfileRoute.dataSpace),
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonalInfoPage extends StatefulWidget {
  const _PersonalInfoPage({required this.controller});

  final AppController controller;

  @override
  State<_PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<_PersonalInfoPage> {
  late final TextEditingController _nickname;
  late final TextEditingController _signature;
  late final TextEditingController _school;
  late final TextEditingController _major;
  late final TextEditingController _grade;
  late final TextEditingController _birthday;
  late final TextEditingController _age;
  late final TextEditingController _gender;
  late final TextEditingController _hometown;
  String _avatarPath = '';

  @override
  void initState() {
    super.initState();
    final preference = widget.controller.preference;
    _nickname = TextEditingController(text: preference.nickname);
    _signature = TextEditingController(text: preference.signature);
    _school = TextEditingController(text: preference.school);
    _major = TextEditingController(text: preference.major);
    _grade = TextEditingController(text: preference.grade);
    _birthday = TextEditingController(text: preference.birthday);
    _age = TextEditingController(text: preference.age);
    _gender = TextEditingController(text: preference.gender);
    _hometown = TextEditingController(text: preference.hometown);
    _avatarPath = preference.avatarPath;
  }

  @override
  void dispose() {
    _nickname.dispose();
    _signature.dispose();
    _school.dispose();
    _major.dispose();
    _grade.dispose();
    _birthday.dispose();
    _age.dispose();
    _gender.dispose();
    _hometown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        WeavingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.coral,
                    backgroundImage:
                        _avatarPath.isNotEmpty && File(_avatarPath).existsSync()
                        ? FileImage(File(_avatarPath))
                        : null,
                    child:
                        _avatarPath.isNotEmpty && File(_avatarPath).existsSync()
                        ? null
                        : const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                          ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: _pickAvatar,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('更换头像'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InputField(controller: _nickname, label: '昵称'),
              _InputField(controller: _signature, label: '签名', maxLines: 2),
              _InputField(controller: _school, label: '学校'),
              _InputField(controller: _major, label: '专业'),
              _InputField(controller: _grade, label: '年级'),
              _InputField(controller: _birthday, label: '生日'),
              _InputField(controller: _age, label: '年龄'),
              _InputField(controller: _gender, label: '性别'),
              _InputField(controller: _hometown, label: '家乡'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存资料'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAvatar() async {
    final path = await widget.controller.pickImage(SourceType.album);
    if (!mounted || path == null) return;
    setState(() => _avatarPath = path);
  }

  Future<void> _save() async {
    await widget.controller.saveAccountProfile(
      nickname: _nickname.text,
      signature: _signature.text,
      school: _school.text,
      major: _major.text,
      grade: _grade.text,
      birthday: _birthday.text,
      age: _age.text,
      gender: _gender.text,
      hometown: _hometown.text,
      avatarPath: _avatarPath,
    );
  }
}

class _ReminderCenterPage extends StatelessWidget {
  const _ReminderCenterPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final preference = controller.preference;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SwitchTile(
          title: '提前一天提醒',
          subtitle: '为时间线事项生成一天前提醒。',
          value: preference.dayReminderEnabled,
          onChanged: (value) => controller.savePreference(
            preference.copyWith(dayReminderEnabled: value),
          ),
        ),
        _SwitchTile(
          title: '临近提醒',
          subtitle: '按分钟级提醒覆盖最近时段。',
          value: preference.hourReminderEnabled,
          onChanged: (value) => controller.savePreference(
            preference.copyWith(hourReminderEnabled: value),
          ),
        ),
        _ReminderLeadTile(controller: controller),
        WeavingCard(
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.rescheduleReminders,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('重新排程本地提醒'),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineAssetsPage extends StatelessWidget {
  const _TimelineAssetsPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final events = controller.confirmedEvents;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (events.isEmpty)
          const EmptyState(
            title: '还没有已确认的时间线资产',
            summary: '从首页导入海报、截图、语音或文本后，确认过的事项会沉淀到这里。',
          )
        else
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EventCard(
                event: event,
                onEdit: () => controller.reparseEvent(event),
                onDelete: () => controller.deleteEvent(event),
                onDuplicate: () => controller.duplicateEvent(event),
                onNavigate: () => controller.openMap(event),
                onShare: () => controller.shareEvent(event),
                onCopy: () => controller.copyEvent(event),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExportRecordsPage extends StatelessWidget {
  const _ExportRecordsPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final records = controller.exportRecords;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SectionBlock(
          title: '生成导出文件',
          summary: '选择格式后直接从当前时间线生成文件，并写入导出记录。',
          child: _NavGrid(
            items: [
              _NavItemSpec(
                Icons.picture_as_pdf_rounded,
                'PDF',
                '生成可阅读文档',
                controller.exportTimelinePdf,
                color: AppColors.coral,
              ),
              _NavItemSpec(
                Icons.image_rounded,
                'PNG',
                '生成图片快照',
                controller.exportTimelinePng,
                color: AppColors.primarySoft,
              ),
              _NavItemSpec(
                Icons.photo_rounded,
                'JPG',
                '生成压缩图片',
                controller.exportTimelineJpg,
                color: AppColors.gold,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (records.isEmpty)
          const EmptyState(
            title: '还没有导出记录',
            summary: '从时间线导出 PDF、PNG 或 JPG 后，记录会真实保存在这里。',
          )
        else
          ...records.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WeavingCard(
                onTap: () => controller.openExportRecord(record),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${record.format} · ${record.eventCount} 条事项',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.path,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatBytes(record.bytes)} · ${ZhishiDateUtils.formatExport(DateTime.fromMillisecondsSinceEpoch(record.createdAtMillis))}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RuntimeStatusPage extends StatelessWidget {
  const _RuntimeStatusPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final readyCount = [
      ApiConfig.hasOcrConfig,
      ApiConfig.hasChatConfig,
      controller.dataStoreReady,
      controller.currentAccountLabel.trim().isNotEmpty,
      controller.cameraPermissionReady,
      controller.microphonePermissionReady,
    ].where((item) => item).length;
    final rows = <_RuntimeBoardSpec>[
      _RuntimeBoardSpec(
        icon: Icons.psychology_rounded,
        title: '模型链路',
        summary: controller.runtimeModelName,
        ready: ApiConfig.hasChatConfig,
      ),
      _RuntimeBoardSpec(
        icon: Icons.document_scanner_rounded,
        title: 'OCR 接口',
        summary: controller.ocrEndpoint,
        ready: ApiConfig.hasOcrConfig,
      ),
      _RuntimeBoardSpec(
        icon: Icons.storage_rounded,
        title: '本地存储',
        summary: controller.dataStoreReady ? '事件、偏好、导出记录可读写' : '本地库未就绪',
        ready: controller.dataStoreReady,
      ),
      _RuntimeBoardSpec(
        icon: Icons.manage_accounts_rounded,
        title: '当前账号',
        summary: controller.currentAccountLabel.trim().isEmpty
            ? '尚未登录有效账号'
            : controller.currentAccountLabel,
        ready: controller.currentAccountLabel.trim().isNotEmpty,
      ),
      _RuntimeBoardSpec(
        icon: Icons.photo_camera_rounded,
        title: '相机权限',
        summary: controller.cameraPermissionReady ? '可用于拍照识别' : '尚未授权相机',
        ready: controller.cameraPermissionReady,
      ),
      _RuntimeBoardSpec(
        icon: Icons.photo_library_rounded,
        title: '相册权限',
        summary: controller.photosPermissionReady ? '可用于相册导入' : '尚未授权相册',
        ready: controller.photosPermissionReady,
      ),
      _RuntimeBoardSpec(
        icon: Icons.notifications_active_rounded,
        title: '通知权限',
        summary: controller.notificationPermissionReady ? '本地提醒可触达' : '尚未授权通知',
        ready: controller.notificationPermissionReady,
      ),
      _RuntimeBoardSpec(
        icon: Icons.mic_rounded,
        title: '麦克风权限',
        summary: controller.microphonePermissionReady ? '语音输入可用' : '尚未授权麦克风',
        ready: controller.microphonePermissionReady,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              value: '$readyCount/6',
              label: '就绪模块',
              color: readyCount >= 5 ? AppColors.primarySoft : AppColors.gold,
            ),
            _MetricBox(
              value: '${controller.scheduledReminderCount}',
              label: '待触达提醒',
              color: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 14),
        WeavingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('接口状态', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                ApiConfig.hasChatConfig && ApiConfig.hasOcrConfig
                    ? '真实接入'
                    : '待配置',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '当前模型链路指向 ${controller.runtimeModelName}，聊天接口 ${controller.chatEndpoint}，OCR 接口 ${controller.ocrEndpoint}。',
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '模块状态',
          summary: '这里展示的是当前 App 可读到的工程状态，不是静态说明卡。',
          child: Column(
            children: rows
                .map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WeavingCard(
                      color: Colors.white.withValues(alpha: 0.7),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: row.ready
                                  ? AppColors.primarySoft
                                  : AppColors.coral,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              row.icon,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  row.summary,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          InfoChip(
                            label: row.ready ? '正常' : '待处理',
                            backgroundColor: row.ready
                                ? AppColors.primarySoft
                                : AppColors.coral,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _NotificationInboxPage extends StatefulWidget {
  const _NotificationInboxPage({
    required this.controller,
    required this.onNavigate,
  });

  final AppController controller;
  final ValueChanged<ProfileRoute> onNavigate;

  @override
  State<_NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends State<_NotificationInboxPage> {
  InboxFilter _filter = InboxFilter.all;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final filtered = _filterInboxMessages(controller.inboxMessages, _filter);
    final pendingCount = controller.inboxMessages
        .where(
          (message) =>
              message.status.contains('待') || message.status.contains('未读'),
        )
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              value: '${controller.pendingNotices.length}',
              label: '待校验',
              color: AppColors.coral,
            ),
            _MetricBox(
              value: '${controller.scheduledReminderCount}',
              label: '已提醒',
              color: AppColors.gold,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '消息概览',
          summary: '像主流任务 App 的 Inbox 一样，把 AI 解析、风险拦截和时间线操作集中起来。',
          child: _NavGrid(
            items: [
              _NavItemSpec(
                Icons.notifications_active_rounded,
                '全部消息',
                '${controller.inboxMessages.length} 条事件记录',
                () => setState(() => _filter = InboxFilter.all),
                color: AppColors.gold,
              ),
              _NavItemSpec(
                Icons.shield_rounded,
                '待处理',
                '$pendingCount 条需要复核',
                () => setState(() => _filter = InboxFilter.pending),
                color: AppColors.coral,
              ),
              _NavItemSpec(
                Icons.query_stats_rounded,
                '解析反馈',
                '低置信度与失败会保留原因',
                () => setState(() => _filter = InboxFilter.feedback),
                color: AppColors.primarySoft,
              ),
              _NavItemSpec(
                Icons.tune_rounded,
                '通知策略',
                '调整提醒与静默规则',
                () => widget.onNavigate(ProfileRoute.preferences),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('全部'),
              selected: _filter == InboxFilter.all,
              onSelected: (_) => setState(() => _filter = InboxFilter.all),
            ),
            ChoiceChip(
              label: const Text('待处理'),
              selected: _filter == InboxFilter.pending,
              onSelected: (_) => setState(() => _filter = InboxFilter.pending),
            ),
            ChoiceChip(
              label: const Text('反馈'),
              selected: _filter == InboxFilter.feedback,
              onSelected: (_) => setState(() => _filter = InboxFilter.feedback),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionBlock(
          title: _inboxSectionTitle(_filter),
          summary: filtered.isEmpty
              ? _inboxEmptySummary(_filter)
              : '按时间倒序展示最近 ${filtered.length} 条，点击任意消息可查看完整状态。',
          child: filtered.isEmpty
              ? WeavingCard(
                  color: Colors.white.withValues(alpha: 0.72),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '收纳箱',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '干净',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '当你导入图片、确认日程、取消执行或遇到低置信度结果时，这里会保留可回看的系统记录。',
                        style: TextStyle(color: AppColors.muted, height: 1.45),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: filtered
                      .map(
                        (message) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: WeavingCard(
                            color: _inboxMessageBackground(
                              message.type,
                              message.status,
                            ),
                            onTap: () => _openMessageDetail(context, message),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.58,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _inboxMessageIcon(
                                          message.type,
                                          message.status,
                                        ),
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.title,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            message.summary,
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              height: 1.4,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    InfoChip(
                                      label: message.status.isEmpty
                                          ? '未读'
                                          : message.status,
                                      backgroundColor: _inboxMessageBackground(
                                        message.type,
                                        message.status,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ZhishiDateUtils.formatExport(
                                          DateTime.fromMillisecondsSinceEpoch(
                                            message.createdAtMillis,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _inboxTypeLabel(message.type),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        if (controller.inboxMessages.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.clearInboxMessages,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('清空通知中心'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openMessageDetail(
    BuildContext context,
    InboxMessage message,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.title.isEmpty ? '织时消息' : message.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('状态：${message.status.isEmpty ? '未读' : message.status}'),
            const SizedBox(height: 6),
            Text('类型：${_inboxTypeLabel(message.type)}'),
            const SizedBox(height: 6),
            Text(
              '时间：${ZhishiDateUtils.formatExport(DateTime.fromMillisecondsSinceEpoch(message.createdAtMillis))}',
            ),
            const SizedBox(height: 10),
            Text(message.summary.isEmpty ? '暂无摘要' : message.summary),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _PrivacySecurityPage extends StatelessWidget {
  const _PrivacySecurityPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final preference = controller.preference;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SwitchTile(
          title: '高风险动作拦截',
          subtitle: '考试、截止、地点不明等事项必须先经过你确认。',
          value: preference.blockHighRisk,
          onChanged: (value) => controller.savePreference(
            preference.copyWith(blockHighRisk: value),
          ),
        ),
        _SwitchTile(
          title: '低置信静默处理',
          subtitle: '降低误写入时间线的风险。',
          value: preference.muteLowConfidence,
          onChanged: (value) => controller.savePreference(
            preference.copyWith(muteLowConfidence: value),
          ),
        ),
        _SwitchTile(
          title: '自动地图联动',
          subtitle: '地点明确时才自动联动地图。',
          value: preference.autoMapLink,
          onChanged: (value) => controller.savePreference(
            preference.copyWith(autoMapLink: value),
          ),
        ),
        WeavingCard(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('最小必要', style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text(
                '织时围绕校园通知解析、日程确认、提醒和时间线沉淀组织数据，不用 mock、demo 或空壳状态冒充真实结果。',
                style: TextStyle(color: AppColors.muted, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DataSpacePage extends StatelessWidget {
  const _DataSpacePage({required this.controller, required this.onNavigate});

  final AppController controller;
  final ValueChanged<ProfileRoute> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              value: '${controller.confirmedEvents.length}',
              label: '已确认',
              color: AppColors.gold,
            ),
            _MetricBox(
              value: '${controller.pendingNotices.length}',
              label: '待处理',
              color: AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MetricRow(
          children: [
            _MetricBox(
              value: '${controller.scheduledReminderCount}',
              label: '提醒',
              color: AppColors.primarySoft,
            ),
            _MetricBox(
              value: controller.dataStoreReady ? 'ON' : 'OFF',
              label: '本地库',
              color: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 14),
        WeavingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('资产状态', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                controller.dataStoreReady ? '持续织入' : '待检查',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.dataStoreReady
                    ? '导入来源、解析结果、时间资产和导出记录都在本地分层沉淀，保持真实数据边界清晰可查。'
                    : '当前本地库尚未就绪，事件、导出记录和偏好写入需要先恢复存储能力。',
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '数据能力',
          summary: '把时间线做成可复盘、可检索、可导出的个人校园资产。',
          child: _NavGrid(
            items: [
              _NavItemSpec(
                Icons.history_rounded,
                '来源可追溯',
                '保留文本 / 截图 / 海报语义',
                () => onNavigate(ProfileRoute.history),
              ),
              _NavItemSpec(
                Icons.query_stats_rounded,
                '密度可感知',
                '快速判断本周时间压力',
                () => onNavigate(ProfileRoute.statistics),
              ),
              _NavItemSpec(
                Icons.download_rounded,
                '导出记录',
                '打开真实导出记录',
                () => onNavigate(ProfileRoute.exportRecords),
              ),
              _NavItemSpec(
                Icons.shield_rounded,
                '风险可回看',
                '待校验事项不会被埋掉',
                () => onNavigate(ProfileRoute.notificationInbox),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => onNavigate(ProfileRoute.timelineAssets),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('打开时间线'),
          ),
        ),
      ],
    );
  }
}

class _PersonaPage extends StatelessWidget {
  const _PersonaPage({required this.controller});

  final AppController controller;

  _PersonaSummary _buildPersona() {
    final confirmed = controller.confirmedEvents.length;
    final pending = controller.pendingNotices.length;
    final reminders = controller.scheduledReminderCount;
    final sourceTypes = controller.confirmedEvents
        .map((event) => event.source.type)
        .toSet()
        .length;
    final locationComplete = confirmed == 0
        ? 0
        : controller.confirmedEvents
              .where((event) => event.location?.trim().isNotEmpty ?? false)
              .length;
    final locationRate = confirmed == 0
        ? 0
        : ((locationComplete / confirmed) * 100).round();

    if (confirmed < 3 && pending < 2 && reminders < 2) {
      return const _PersonaSummary(
        title: '画像生成中',
        subtitle: '资料不足',
        tags: ['确认记录不足', '来源样本不足', '继续真实使用'],
        guides: [
          _PersonaGuide(
            Icons.add_task_rounded,
            '先确认更多事项',
            '至少沉淀 3 条已确认时间线后，画像会变得更稳定。',
          ),
          _PersonaGuide(
            Icons.download_rounded,
            '保留导入来源',
            '文本、相册、拍照和系统分享都会参与来源分布判断。',
          ),
          _PersonaGuide(
            Icons.location_on_outlined,
            '补齐地点线索',
            '地点完整率会影响地图联动和时间资产可信度。',
          ),
        ],
      );
    }

    final tags = <String>[];
    if (sourceTypes >= 3) tags.add('多来源导入');
    if (pending >= 3) tags.add('谨慎校验');
    if (reminders >= confirmed && confirmed > 0) tags.add('提醒托管');
    if (locationRate >= 70) tags.add('地点完整');
    if (confirmed >= 8) tags.add('时间线沉淀');
    if (tags.isEmpty) tags.add('稳态推进');

    var title = '稳态推进型';
    var subtitle = '基于确认记录、提醒和来源分布生成';
    if (pending >= confirmed && pending >= 3) {
      title = '谨慎校验型';
      subtitle = '待确认事项较多，仍以人工复核为主';
    } else if (sourceTypes >= 3 && confirmed >= 4) {
      title = '多模态导入型';
      subtitle = '多种真实导入来源正在形成稳定习惯';
    } else if (reminders >= confirmed && confirmed >= 4) {
      title = '提醒托管型';
      subtitle = '已确认事项大多接入本地提醒';
    } else if (confirmed >= 8) {
      title = '时间线沉淀型';
      subtitle = '已形成可复盘的校园时间资产';
    }

    return _PersonaSummary(
      title: title,
      subtitle: subtitle,
      tags: tags,
      guides: [
        _PersonaGuide(
          Icons.check_circle_outline_rounded,
          '已确认记录',
          '$confirmed 条已确认，$pending 条待确认。',
        ),
        _PersonaGuide(
          Icons.notifications_active_rounded,
          '提醒覆盖',
          '$reminders 条后续提醒，提前量 ${controller.preference.reminderLeadMinutes} 分钟。',
        ),
        _PersonaGuide(
          Icons.location_on_outlined,
          '地点完整率',
          '$locationRate% 的已确认事项带有地点线索。',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final persona = _buildPersona();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              value: '${controller.todayEvents.length}',
              label: '今日',
              color: AppColors.gold,
            ),
            _MetricBox(
              value: '${controller.scheduledReminderCount}',
              label: '提醒',
              color: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 14),
        WeavingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前画像', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                persona.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                persona.subtitle,
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '画像标签',
          summary: '标签只来自真实确认记录、待确认数量、提醒数量、来源分布和地点完整率。',
          child: _NavGrid(
            items: persona.tags
                .map(
                  (tag) => _NavItemSpec(
                    _personaTagIcon(tag),
                    tag,
                    _personaTagSummary(tag),
                    null,
                    color: _personaTagColor(tag),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '个性化建议',
          summary: '根据当前使用状态给出可解释建议，不凭空猜测用户习惯。',
          child: Column(
            children: [
              for (var i = 0; i < persona.guides.length; i++) ...[
                _DetailGuideRow(
                  icon: persona.guides[i].icon,
                  title: persona.guides[i].title,
                  summary: persona.guides[i].summary,
                ),
                if (i < persona.guides.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonaSummary {
  const _PersonaSummary({
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.guides,
  });

  final String title;
  final String subtitle;
  final List<String> tags;
  final List<_PersonaGuide> guides;
}

class _PersonaGuide {
  const _PersonaGuide(this.icon, this.title, this.summary);

  final IconData icon;
  final String title;
  final String summary;
}

IconData _personaTagIcon(String tag) {
  if (tag.contains('多来源')) return Icons.download_rounded;
  if (tag.contains('校验')) return Icons.shield_rounded;
  if (tag.contains('提醒')) return Icons.notifications_active_rounded;
  if (tag.contains('地点')) return Icons.location_on_outlined;
  if (tag.contains('沉淀')) return Icons.timeline_rounded;
  return Icons.auto_awesome_rounded;
}

String _personaTagSummary(String tag) {
  if (tag.contains('多来源')) return '文本、图片或分享来源形成分布';
  if (tag.contains('校验')) return '待确认池仍需要人工复核';
  if (tag.contains('提醒')) return '关键时间点已有本地提醒';
  if (tag.contains('地点')) return '地点字段较完整，可联动地图';
  if (tag.contains('沉淀')) return '已有可复盘的时间线资产';
  return '使用状态正在稳定积累';
}

Color? _personaTagColor(String tag) {
  if (tag.contains('校验')) return AppColors.coral;
  if (tag.contains('多来源') || tag.contains('地点')) return AppColors.gold;
  if (tag.contains('提醒') || tag.contains('沉淀')) {
    return AppColors.primarySoft;
  }
  return null;
}

class _AgentCheckupPage extends StatelessWidget {
  const _AgentCheckupPage({required this.controller, required this.onNavigate});

  final AppController controller;
  final ValueChanged<ProfileRoute> onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = _buildCheckupItems(controller);
    final actionCount = items
        .where((item) => item.level == _CheckupLevel.action)
        .length;
    final watchCount = items
        .where((item) => item.level == _CheckupLevel.watch)
        .length;
    final score = _calculateCheckupScore(items);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              value: '$score',
              label: '健康分',
              color: score >= 90 ? AppColors.primarySoft : AppColors.gold,
            ),
            _MetricBox(
              value: '$actionCount',
              label: '需处理',
              color: actionCount == 0 ? Colors.white : AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MetricRow(
          children: [
            _MetricBox(
              value: '$watchCount',
              label: '观察项',
              color: watchCount == 0 ? Colors.white : AppColors.gold,
            ),
            _MetricBox(
              value: '${controller.confirmedEvents.length}',
              label: '已沉淀',
              color: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 14),
        WeavingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('体检结论', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                _buildCheckupConclusion(score, actionCount, watchCount),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '织时会把低频风险集中到体检页，不挤占首页和“我的”第一页；每个体检项都能跳到对应页面继续处理。',
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionBlock(
          title: '快速补强',
          summary: '按主流任务中心的思路，把处理入口压缩为几个高频动作。',
          child: _NavGrid(
            items: [
              _NavItemSpec(
                Icons.notifications_active_rounded,
                '处理消息',
                '${controller.inboxMessages.length} 条系统记录',
                () => onNavigate(ProfileRoute.notificationInbox),
              ),
              _NavItemSpec(
                Icons.tune_rounded,
                '调整偏好',
                '提醒与安全边界',
                () => onNavigate(ProfileRoute.preferences),
              ),
              _NavItemSpec(
                Icons.timeline_rounded,
                '回看资产',
                '${controller.confirmedEvents.length} 条时间线',
                () => onNavigate(ProfileRoute.timelineAssets),
              ),
              _NavItemSpec(
                Icons.shield_rounded,
                '安全策略',
                '人在回路与静默阈值',
                () => onNavigate(ProfileRoute.privacySecurity),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WeavingCard(
              onTap: () => onNavigate(item.route),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      InfoChip(
                        label: item.level.label,
                        backgroundColor: item.level.backgroundColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.summary,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => ChoiceChip(
              label: Text(value),
              selected: selected == value,
              onSelected: (_) => onSelect(value),
            ),
          )
          .toList(),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.82),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WeavingCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ReminderLeadTile extends StatelessWidget {
  const _ReminderLeadTile({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final leadMinutes = controller.preference.reminderLeadMinutes
        .clamp(5, 180)
        .toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WeavingCard(
        onTap: () => _showLeadDialog(context, leadMinutes),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('提醒提前量', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text(
                    '手动设置临近提醒提前多少分钟触达。',
                    style: TextStyle(color: AppColors.muted, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InfoChip(
              label: '$leadMinutes 分钟',
              backgroundColor: AppColors.primarySoft,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLeadDialog(BuildContext context, int initialMinutes) async {
    var selected = initialMinutes.toDouble();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedMinutes = selected.round();
            return AlertDialog(
              title: const Text('提醒提前量'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('当前：$selectedMinutes 分钟'),
                  Slider(
                    min: 5,
                    max: 180,
                    divisions: 35,
                    value: selected,
                    label: '$selectedMinutes 分钟',
                    onChanged: (value) {
                      setDialogState(() {
                        selected = (value / 5).round() * 5;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    controller.savePreference(
                      controller.preference.copyWith(
                        reminderLeadMinutes: selectedMinutes,
                      ),
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.summary,
    required this.child,
  });

  final String title;
  final String summary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            summary,
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _NavGrid extends StatelessWidget {
  const _NavGrid({required this.items});

  final List<_NavItemSpec> items;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final itemWidth = width > 600 ? (width - 52) / 3 : (width - 42) / 2;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => SizedBox(
              width: itemWidth,
              child: WeavingCard(
                color: item.color,
                onTap: item.onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: AppColors.primary),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.summary,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NavItemSpec {
  const _NavItemSpec(
    this.icon,
    this.title,
    this.summary,
    this.onTap, {
    this.color,
  });

  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback? onTap;
  final Color? color;
}

enum _CheckupLevel { ready, watch, action }

class _RuntimeBoardSpec {
  const _RuntimeBoardSpec({
    required this.icon,
    required this.title,
    required this.summary,
    required this.ready,
  });

  final IconData icon;
  final String title;
  final String summary;
  final bool ready;
}

extension on _CheckupLevel {
  String get label {
    switch (this) {
      case _CheckupLevel.ready:
        return '正常';
      case _CheckupLevel.watch:
        return '观察';
      case _CheckupLevel.action:
        return '处理';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _CheckupLevel.ready:
        return AppColors.primarySoft;
      case _CheckupLevel.watch:
        return AppColors.gold;
      case _CheckupLevel.action:
        return AppColors.coral;
    }
  }
}

class _CheckupItem {
  const _CheckupItem({
    required this.title,
    required this.summary,
    required this.level,
    required this.route,
  });

  final String title;
  final String summary;
  final _CheckupLevel level;
  final ProfileRoute route;
}

List<_NavItemSpec> _dashboardFeatureItems(
  AppController controller,
  ValueChanged<ProfileRoute> onNavigate,
) {
  return [
    _NavItemSpec(
      Icons.health_and_safety_outlined,
      '一键体检',
      '校验待办、提醒、冲突和策略',
      () => onNavigate(ProfileRoute.agentCheckup),
    ),
    _NavItemSpec(
      Icons.timeline_rounded,
      '日程表',
      '查看沉淀资产与今天安排',
      () => onNavigate(ProfileRoute.timelineAssets),
    ),
    _NavItemSpec(
      Icons.notifications_active_rounded,
      '通知中心',
      '回看待处理与系统消息',
      () => onNavigate(ProfileRoute.notificationInbox),
    ),
    _NavItemSpec(
      Icons.workspace_premium_outlined,
      '我的成就',
      '勋章、里程碑与使用激励',
      () => onNavigate(ProfileRoute.achievements),
    ),
    _NavItemSpec(
      Icons.person_search_outlined,
      '用户画像',
      '校园时间管理侧写',
      () => onNavigate(ProfileRoute.persona),
    ),
    _NavItemSpec(
      Icons.shield_rounded,
      '隐私与安全',
      '人在回路与风险拦截',
      () => onNavigate(ProfileRoute.privacySecurity),
    ),
    _NavItemSpec(
      Icons.storage_rounded,
      '数据空间',
      '本地存储与数据边界',
      () => onNavigate(ProfileRoute.dataSpace),
    ),
    _NavItemSpec(
      Icons.speed_rounded,
      '运行状态',
      '模型、OCR、存储与权限状态',
      () => onNavigate(ProfileRoute.runtimeStatus),
    ),
  ];
}

List<_NavItemSpec> _agentCenterSystemItems(
  AppController controller,
  ValueChanged<ProfileRoute> onNavigate,
) {
  return [
    _NavItemSpec(
      Icons.download_rounded,
      '导出记录',
      '导出你的时间资产',
      () => onNavigate(ProfileRoute.exportRecords),
    ),
    _NavItemSpec(
      Icons.settings_rounded,
      '设置',
      '管理账号、偏好与退出登录',
      () => onNavigate(ProfileRoute.settings),
    ),
    _NavItemSpec(
      Icons.speed_rounded,
      '运行状态',
      '${controller.runtimeModelName} / 本地能力',
      () => onNavigate(ProfileRoute.runtimeStatus),
    ),
    _NavItemSpec(
      Icons.logout_rounded,
      '退出登录',
      '返回登录页并保留本地时间线数据',
      controller.logoutAccount,
    ),
  ];
}

int _buildActivePolicyCount(AppController controller) {
  final preference = controller.preference;
  return [
    preference.blockHighRisk,
    preference.muteLowConfidence,
    preference.autoMapLink,
  ].where((enabled) => enabled).length;
}

String _buildProfileLine({
  required String account,
  required String school,
  required String major,
  required String grade,
}) {
  final parts = [
    account,
    school,
    major,
    grade,
  ].map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  return parts.isEmpty ? '请完善校园身份资料' : parts.join(' · ');
}

String _buildProfileBrief({
  required String birthday,
  required String age,
  required String gender,
  required String hometown,
}) {
  final parts = <String>[
    if (birthday.isNotEmpty) '生日 $birthday',
    if (age.isNotEmpty) '$age 岁',
    if (gender.isNotEmpty) gender,
    if (hometown.isNotEmpty) hometown,
  ];
  return parts.isEmpty ? '请完善生日、年龄和学校资料' : parts.join(' · ');
}

List<InboxMessage> _filterInboxMessages(
  List<InboxMessage> inboxMessages,
  InboxFilter filter,
) {
  switch (filter) {
    case InboxFilter.all:
      return inboxMessages;
    case InboxFilter.pending:
      return inboxMessages
          .where(
            (message) =>
                message.status.contains('待') || message.status.contains('未读'),
          )
          .toList();
    case InboxFilter.feedback:
      return inboxMessages
          .where(
            (message) =>
                _containsIgnoreCase(message.type, 'clarification') ||
                _containsIgnoreCase(message.type, 'error') ||
                _containsIgnoreCase(message.type, 'blocked') ||
                _containsIgnoreCase(message.type, 'tts') ||
                _containsIgnoreCase(message.type, 'feedback'),
          )
          .toList();
  }
}

String _inboxSectionTitle(InboxFilter filter) {
  switch (filter) {
    case InboxFilter.all:
      return '最近消息';
    case InboxFilter.pending:
      return '待处理消息';
    case InboxFilter.feedback:
      return '解析反馈';
  }
}

String _inboxEmptySummary(InboxFilter filter) {
  switch (filter) {
    case InboxFilter.all:
      return '暂时没有待处理消息，新的解析、确认、拦截和错误会自动收纳在这里。';
    case InboxFilter.pending:
      return '当前没有待处理消息，待确认和待补充事项会自动回流到这里。';
    case InboxFilter.feedback:
      return '当前没有新的解析反馈，低置信和失败结果会保留在这里。';
  }
}

String _inboxTypeLabel(String type) {
  if (_containsIgnoreCase(type, 'error')) return '错误反馈';
  if (_containsIgnoreCase(type, 'blocked')) return '风险拦截';
  if (_containsIgnoreCase(type, 'clarification')) return '待补充';
  if (_containsIgnoreCase(type, 'tts')) return '语音播报';
  if (_containsIgnoreCase(type, 'feedback')) return '解析反馈';
  if (_containsIgnoreCase(type, 'reminder')) return '提醒回流';
  return '系统消息';
}

IconData _inboxMessageIcon(String type, String status) {
  if (_containsIgnoreCase(type, 'error')) return Icons.security_rounded;
  if (_containsIgnoreCase(type, 'blocked')) return Icons.shield_rounded;
  if (_containsIgnoreCase(type, 'confirm')) return Icons.check_circle_rounded;
  if (_containsIgnoreCase(type, 'edit')) return Icons.edit_rounded;
  if (_containsIgnoreCase(type, 'delete')) return Icons.delete_rounded;
  if (_containsIgnoreCase(type, 'navigate')) return Icons.map_rounded;
  if (_containsIgnoreCase(type, 'duplicate')) return Icons.replay_rounded;
  if (status.contains('待')) return Icons.shield_rounded;
  return Icons.notifications_active_rounded;
}

Color _inboxMessageBackground(String type, String status) {
  if (_containsIgnoreCase(type, 'error') ||
      _containsIgnoreCase(type, 'blocked')) {
    return AppColors.coral;
  }
  if (status.contains('待') || status.contains('补充')) {
    return AppColors.coral;
  }
  if (_containsIgnoreCase(type, 'confirm') || status.contains('已处理')) {
    return AppColors.primarySoft;
  }
  if (_containsIgnoreCase(type, 'navigate') ||
      _containsIgnoreCase(type, 'duplicate')) {
    return AppColors.gold;
  }
  return Colors.white.withValues(alpha: 0.88);
}

bool _containsIgnoreCase(String value, String pattern) {
  return value.toLowerCase().contains(pattern.toLowerCase());
}

class _DetailGuideRow extends StatelessWidget {
  const _DetailGuideRow({
    required this.icon,
    required this.title,
    required this.summary,
  });

  final IconData icon;
  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      color: Colors.white.withValues(alpha: 0.68),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: const TextStyle(color: AppColors.muted, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<_CheckupItem> _buildCheckupItems(AppController controller) {
  final confirmedItems = controller.confirmedEvents;
  final missingTimeCount = confirmedItems
      .where((item) => (item.startTimeIso ?? '').trim().isEmpty)
      .length;
  final missingLocationCount = confirmedItems
      .where((item) => (item.location ?? '').trim().isEmpty)
      .length;
  final reminderCoverageLow =
      confirmedItems.isNotEmpty &&
      controller.scheduledReminderCount < confirmedItems.length;
  final conflictCount = confirmedItems.asMap().entries.where((entry) {
    if (entry.value.startTime == null) return false;
    for (var i = entry.key + 1; i < confirmedItems.length; i++) {
      final other = confirmedItems[i].startTime;
      if (other == null) continue;
      if (entry.value.startTime!.difference(other).inMinutes.abs() <= 90) {
        return true;
      }
    }
    return false;
  }).length;
  final pendingInboxCount = controller.inboxMessages
      .where(
        (message) =>
            message.status.contains('待') ||
            message.status.contains('未读') ||
            _containsIgnoreCase(message.type, 'error'),
      )
      .length;

  return [
    _CheckupItem(
      title: '待确认池',
      summary: controller.pendingNotices.isEmpty
          ? '当前没有待校验事项，人在回路链路保持干净。'
          : '还有 ${controller.pendingNotices.length} 条事项等待复核，建议先处理再继续使用。',
      level: controller.pendingNotices.isEmpty
          ? _CheckupLevel.ready
          : _CheckupLevel.action,
      route: ProfileRoute.notificationInbox,
    ),
    _CheckupItem(
      title: '时间字段',
      summary: missingTimeCount == 0
          ? '已沉淀事项均有可解析时间，时间线排序稳定。'
          : '$missingTimeCount 条记录缺少精确时间，可能影响提醒和日历展示。',
      level: missingTimeCount == 0 ? _CheckupLevel.ready : _CheckupLevel.action,
      route: ProfileRoute.history,
    ),
    _CheckupItem(
      title: '地点字段',
      summary: missingLocationCount == 0 && controller.preference.autoMapLink
          ? '地点线索完整，地图联动已开启。'
          : !controller.preference.autoMapLink
          ? '地图联动未开启，地点识别不会自动生成导航动作。'
          : '$missingLocationCount 条记录地点不完整，可在历史记录中回看补齐。',
      level: !controller.preference.autoMapLink
          ? _CheckupLevel.watch
          : missingLocationCount == 0
          ? _CheckupLevel.ready
          : _CheckupLevel.watch,
      route: controller.preference.autoMapLink
          ? ProfileRoute.history
          : ProfileRoute.preferences,
    ),
    _CheckupItem(
      title: '提醒覆盖',
      summary: reminderCoverageLow
          ? '已确认事项多于提醒数，建议检查默认提醒策略。'
          : '提醒托管状态正常，关键时间点已有系统守护。',
      level: reminderCoverageLow ? _CheckupLevel.watch : _CheckupLevel.ready,
      route: ProfileRoute.reminderCenter,
    ),
    _CheckupItem(
      title: '安全边界',
      summary: controller.preference.blockHighRisk
          ? controller.preference.muteLowConfidence
                ? '高风险拦截与低置信静默均已开启，适合正式使用。'
                : '高风险拦截已开启，可按个人需要打开低置信静默。'
          : '高风险拦截未开启，建议恢复人在回路防线。',
      level: controller.preference.blockHighRisk
          ? controller.preference.muteLowConfidence
                ? _CheckupLevel.ready
                : _CheckupLevel.watch
          : _CheckupLevel.action,
      route: ProfileRoute.privacySecurity,
    ),
    _CheckupItem(
      title: '时间冲突',
      summary: conflictCount == 0
          ? '未发现 90 分钟内的密集冲突，时间线节奏清晰。'
          : '发现 $conflictCount 组相近安排，建议进入时间线资产复核。',
      level: conflictCount == 0 ? _CheckupLevel.ready : _CheckupLevel.watch,
      route: ProfileRoute.timelineAssets,
    ),
    _CheckupItem(
      title: '消息收纳',
      summary: pendingInboxCount == 0
          ? '通知中心没有未处理消息，系统状态清爽。'
          : '通知中心还有 $pendingInboxCount 条待处理记录，可集中清理。',
      level: pendingInboxCount == 0 ? _CheckupLevel.ready : _CheckupLevel.watch,
      route: ProfileRoute.notificationInbox,
    ),
    _CheckupItem(
      title: '数据沉淀',
      summary: confirmedItems.isNotEmpty
          ? '已有 ${confirmedItems.length} 条专属时间资产，可用于导出和复盘。'
          : '还没有确认资产，建议先从群聊截图或通知文本导入一条。',
      level: confirmedItems.isNotEmpty
          ? _CheckupLevel.ready
          : _CheckupLevel.watch,
      route: ProfileRoute.timelineAssets,
    ),
  ];
}

int _calculateCheckupScore(List<_CheckupItem> items) {
  var score = 100;
  for (final item in items) {
    switch (item.level) {
      case _CheckupLevel.ready:
        break;
      case _CheckupLevel.watch:
        score -= 6;
      case _CheckupLevel.action:
        score -= 14;
    }
  }
  return score.clamp(52, 100);
}

String _buildCheckupConclusion(int score, int actionCount, int watchCount) {
  if (score >= 92) return '状态良好';
  if (actionCount > 0) return '先处理 $actionCount 项';
  if (watchCount > 0) return '建议微调 $watchCount 项';
  return '状态稳定';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

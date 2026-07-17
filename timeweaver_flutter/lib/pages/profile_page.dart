import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../models/event_item.dart';
import '../models/inbox_message.dart';
import '../models/source_info.dart';
import '../services/api_config.dart';
import '../utils/date_utils.dart';
import '../widgets/weaving_widgets.dart';

enum ProfileRoute {
  dashboard,
  agentCenter,
  agentCheckup,
  history,
  statistics,
  achievements,
  preferences,
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
              child: _route == ProfileRoute.dashboard
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(
                        key: ValueKey(_route),
                        child: _buildRoute(),
                      ),
                    )
                  : NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) => [
                        SliverToBoxAdapter(
                          child: _ProfileHeaderBar(
                            title: _titleForRoute(_route),
                            subtitle: _subtitleForRoute(_route),
                            icon: _iconForRoute(_route),
                            onBack: _pop,
                          ),
                        ),
                      ],
                      body: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: KeyedSubtree(
                          key: ValueKey(_route),
                          child: _buildRoute(),
                        ),
                      ),
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
        return _AgentCheckupPage(
          controller: controller,
          onNavigate: _push,
          onBack: _pop,
        );
      case ProfileRoute.history:
        return _HistoryPage(controller: controller);
      case ProfileRoute.statistics:
        return _StatisticsPage(controller: controller);
      case ProfileRoute.achievements:
        return _AchievementsPage(controller: controller);
      case ProfileRoute.preferences:
        return _PreferencesPage(controller: controller);
      case ProfileRoute.settings:
        return _SettingsPage(controller: controller, onNavigate: _push);
      case ProfileRoute.personalInfo:
        return _PersonalInfoPage(controller: controller, onSaved: _pop);
      case ProfileRoute.persona:
        return _PersonaPage(controller: controller);
      case ProfileRoute.reminderCenter:
        return _ReminderCenterPage(controller: controller);
      case ProfileRoute.timelineAssets:
        return _TimelineAssetsPage(controller: controller, onNavigate: _push);
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
        return '功能中心';
      case ProfileRoute.agentCheckup:
        return '智能体体检';
      case ProfileRoute.history:
        return '历史记录';
      case ProfileRoute.statistics:
        return '统计';
      case ProfileRoute.achievements:
        return '我的成就';
      case ProfileRoute.preferences:
        return '我的偏好';
      case ProfileRoute.settings:
        return '设置';
      case ProfileRoute.personalInfo:
        return '个人资料';
      case ProfileRoute.persona:
        return '使用偏好画像';
      case ProfileRoute.reminderCenter:
        return '提醒中心';
      case ProfileRoute.timelineAssets:
        return '时间线资产';
      case ProfileRoute.exportRecords:
        return '记录导出';
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

  String _subtitleForRoute(ProfileRoute route) {
    switch (route) {
      case ProfileRoute.dashboard:
        return '';
      case ProfileRoute.agentCenter:
        return '';
      case ProfileRoute.agentCheckup:
        return '逐项检查待确认、提醒、冲突、消息与边界策略';
      case ProfileRoute.history:
        return '搜索、筛选并重新解析已经织入的校园碎片';
      case ProfileRoute.statistics:
        return '';
      case ProfileRoute.achievements:
        return '';
      case ProfileRoute.preferences:
        return '集中管理提醒、风控和地点联动策略';
      case ProfileRoute.settings:
        return '';
      case ProfileRoute.personalInfo:
        return '头像、签名和校园身份';
      case ProfileRoute.persona:
        final nickname = widget.controller.preference.nickname.trim();
        return '${nickname.isEmpty ? '织时用户' : nickname} 的校园时间管理参考';
      case ProfileRoute.reminderCenter:
        return '把每一次关键校园安排提前交给系统守护';
      case ProfileRoute.timelineAssets:
        return '查看碎片被织入秩序后的沉淀结果';
      case ProfileRoute.exportRecords:
        return '';
      case ProfileRoute.runtimeStatus:
        return '智能解析、文字识别、本地记录、提醒和账号状态';
      case ProfileRoute.notificationInbox:
        return '';
      case ProfileRoute.privacySecurity:
        return '明确 AI 能做什么、什么时候必须停下来问你';
      case ProfileRoute.dataSpace:
        return '查看已经沉淀在本地的时间资产与缓存边界';
    }
  }

  IconData _iconForRoute(ProfileRoute route) {
    switch (route) {
      case ProfileRoute.dashboard:
        return Icons.person_rounded;
      case ProfileRoute.agentCenter:
      case ProfileRoute.persona:
        return Icons.psychology_rounded;
      case ProfileRoute.agentCheckup:
        return Icons.check_circle_rounded;
      case ProfileRoute.history:
        return Icons.history_rounded;
      case ProfileRoute.statistics:
        return Icons.query_stats_rounded;
      case ProfileRoute.achievements:
        return Icons.emoji_events_rounded;
      case ProfileRoute.preferences:
        return Icons.tune_rounded;
      case ProfileRoute.settings:
        return Icons.settings_rounded;
      case ProfileRoute.personalInfo:
        return Icons.manage_accounts_rounded;
      case ProfileRoute.reminderCenter:
      case ProfileRoute.notificationInbox:
        return Icons.notifications_active_rounded;
      case ProfileRoute.timelineAssets:
        return Icons.timeline_rounded;
      case ProfileRoute.exportRecords:
        return Icons.download_rounded;
      case ProfileRoute.runtimeStatus:
        return Icons.speed_rounded;
      case ProfileRoute.privacySecurity:
        return Icons.security_rounded;
      case ProfileRoute.dataSpace:
        return Icons.storage_rounded;
    }
  }
}

class _ProfileHeaderBar extends StatelessWidget {
  const _ProfileHeaderBar({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _ProfileHeaderBubble(
            icon: Icons.arrow_back_rounded,
            background: AppColors.surfaceLowest,
            onTap: onBack,
          ),
          const SizedBox(width: 14),
          _ProfileHeaderBubble(icon: icon, background: AppColors.gold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 21,
                    height: 27 / 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderBubble extends StatelessWidget {
  const _ProfileHeaderBubble({
    required this.icon,
    required this.background,
    this.onTap,
  });

  final IconData icon;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: CircleBorder(
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.64),
          width: 0.8,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        _ProfileIdentityCard(controller: controller, onNavigate: onNavigate),
        const SizedBox(height: 10),
        _ProfileShortcutGrid(
          onOpenSettings: () => onNavigate(ProfileRoute.settings),
          onOpenHistory: () => onNavigate(ProfileRoute.history),
          onOpenStatistics: () => onNavigate(ProfileRoute.statistics),
          onOpenPersona: () => onNavigate(ProfileRoute.persona),
        ),
        const SizedBox(height: 10),
        _ScheduleBoardCard(
          todayAgendaCount: controller.todayEvents.length,
          pendingAgendaCount: controller.pendingNotices.length,
          scheduledReminderCount: controller.scheduledReminderCount,
          onOpenTimelineAssets: () => onNavigate(ProfileRoute.timelineAssets),
        ),
        const SizedBox(height: 10),
        _AgentCenterEntryCard(
          confirmedAgendaCount: controller.confirmedEvents.length,
          pendingAgendaCount: controller.pendingNotices.length,
          scheduledReminderCount: controller.scheduledReminderCount,
          activePolicyCount: _buildActivePolicyCount(controller),
          onOpenTimelineAssets: () => onNavigate(ProfileRoute.timelineAssets),
          onOpenAgentCenter: () => onNavigate(ProfileRoute.agentCenter),
        ),
        const SizedBox(height: 10),
        _DashboardLogoutButton(controller: controller),
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
      school: preference.school.trim(),
      major: preference.major.trim(),
      grade: preference.grade.trim(),
      fallback: controller.currentAccountLabel.trim().isEmpty
          ? '完善学校、专业与年级信息'
          : controller.currentAccountLabel.trim(),
    );
    final briefLine = _buildProfileBrief(
      birthday: preference.birthday.trim(),
      age: preference.age.trim(),
      gender: preference.gender.trim(),
      hometown: preference.hometown.trim(),
    );

    return WeavingCard(
      color: AppColors.surfaceLowest.withValues(alpha: 0.92),
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
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      height: 24 / 18,
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
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 21,
                    height: 27 / 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  schoolLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  signature.isEmpty ? briefLine : signature,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
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

class _DashboardLogoutButton extends StatelessWidget {
  const _DashboardLogoutButton({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('退出登录'),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('退出登录？'),
          content: const Text('退出后需要重新登录才能继续使用当前账号。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('退出登录'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await controller.logoutAccount();
    }
  }
}

class _ProfileShortcutGrid extends StatelessWidget {
  const _ProfileShortcutGrid({
    required this.onOpenSettings,
    required this.onOpenHistory,
    required this.onOpenStatistics,
    required this.onOpenPersona,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenPersona;

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
          const SizedBox(width: 6),
          _ShortcutEntry(
            icon: Icons.history_rounded,
            label: '历史',
            background: AppColors.primarySoft,
            onTap: onOpenHistory,
          ),
          const SizedBox(width: 6),
          _ShortcutEntry(
            icon: Icons.query_stats_rounded,
            label: '统计',
            background: AppColors.coral,
            onTap: onOpenStatistics,
          ),
          const SizedBox(width: 6),
          _ShortcutEntry(
            icon: Icons.psychology_rounded,
            label: '用户画像',
            background: AppColors.surfaceWarm,
            onTap: onOpenPersona,
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
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 5),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
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
  });

  final int todayAgendaCount;
  final int pendingAgendaCount;
  final int scheduledReminderCount;
  final VoidCallback onOpenTimelineAssets;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      color: AppColors.coral.withValues(alpha: 0.82),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '日程表',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '把今天与后续提醒整理在一张看板里',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.64),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DashboardMetricPill(
                  title: '今日安排',
                  value: '$todayAgendaCount',
                  icon: Icons.calendar_month_rounded,
                  background: AppColors.gold,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _DashboardMetricPill(
                  title: '待确认',
                  value: '$pendingAgendaCount',
                  icon: Icons.shield_rounded,
                  background: AppColors.coral,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _DashboardMetricPill(
                  title: '待提醒',
                  value: '$scheduledReminderCount',
                  icon: Icons.notifications_active_rounded,
                  background: AppColors.primarySoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpenTimelineAssets,
              icon: const Icon(Icons.timeline_rounded),
              label: const Text('查看完整时间线'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: const StadiumBorder(),
              ),
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
  });

  final String title;
  final String value;
  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: WeavingCard(
        color: background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 25,
                height: 31 / 25,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
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
      color: AppColors.surfaceLowest.withValues(alpha: 0.92),
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
                      label: '功能中心',
                      icon: Icons.psychology_rounded,
                      backgroundColor: AppColors.primarySoft,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '管理记录、提醒与安全设置',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 21,
                            height: 27 / 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '集中查看时间线记录、待确认事项、提醒策略、隐私安全与导出记录。',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                        height: 13 / 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.64),
                    width: 0.8,
                  ),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              const SizedBox(width: 6),
              Expanded(
                child: _CenterStatusPill(
                  title: '待确认',
                  value: '$pendingAgendaCount',
                  background: AppColors.coral,
                  onTap: onOpenAgentCenter,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CenterStatusPill(
                  title: '提醒',
                  value: '$scheduledReminderCount',
                  background: AppColors.gold,
                  onTap: onOpenAgentCenter,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CenterStatusPill(
                  title: '策略',
                  value: '$activePolicyCount/3',
                  background: AppColors.surfaceWarm,
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
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(title, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
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
    final systemItems = _agentCenterSystemItems(onNavigate);
    final checkupItems = _buildCheckupItems(controller);
    final issueCount = checkupItems
        .where((item) => item.level != _CheckupLevel.ready)
        .length;
    final checkupScore = _calculateCheckupScore(checkupItems);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.timeline_rounded,
              value: '${controller.confirmedEvents.length}',
              label: '已沉淀',
              color: AppColors.primarySoft,
            ),
            _MetricBox(
              icon: Icons.shield_rounded,
              value: '${controller.pendingNotices.length}',
              label: '待确认',
              color: AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _AgentCenterFlowCard(controller: controller, onNavigate: onNavigate),
        const SizedBox(height: 10),
        _AgentCheckupEntryCard(
          score: checkupScore,
          issueCount: issueCount,
          onTap: () => onNavigate(ProfileRoute.agentCheckup),
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DetailSectionHeader(title: '功能地图'),
            const SizedBox(height: 6),
            _NavGrid(items: featureItems),
          ],
        ),
        const SizedBox(height: 10),
        _AchievementPreviewCard(
          controller: controller,
          onOpenAll: () => onNavigate(ProfileRoute.achievements),
        ),
        const SizedBox(height: 10),
        _DetailRowGroup(title: '系统入口', items: systemItems),
      ],
    );
  }
}

class _AgentCenterFlowCard extends StatelessWidget {
  const _AgentCenterFlowCard({
    required this.controller,
    required this.onNavigate,
  });

  final AppController controller;
  final ValueChanged<ProfileRoute> onNavigate;

  @override
  Widget build(BuildContext context) {
    final todayCount = controller.todayEvents.length;
    return WeavingCard(
      color: AppColors.surfaceLowest.withValues(alpha: 0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '能力链路'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FlowMiniTile(
                  icon: Icons.history_rounded,
                  title: '回看',
                  summary: '${controller.confirmedEvents.length} 条资产',
                  background: AppColors.primarySoft,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _FlowMiniTile(
                  icon: Icons.shield_rounded,
                  title: '校验',
                  summary: '${controller.pendingNotices.length} 条待办',
                  background: AppColors.coral,
                  onTap: () => onNavigate(ProfileRoute.notificationInbox),
                ),
              ),
              const SizedBox(width: 6),
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
          const SizedBox(height: 10),
          _DetailInfoCard(
            title: '今日状态',
            value: todayCount > 0 ? '今天还有 $todayCount 项安排' : '今天留白',
            summary: '已确认、待处理和提醒状态会同步汇总，便于及时回看和处理。',
          ),
        ],
      ),
    );
  }
}

class _AgentCheckupEntryCard extends StatelessWidget {
  const _AgentCheckupEntryCard({
    required this.score,
    required this.issueCount,
    required this.onTap,
  });

  final int score;
  final int issueCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusText = issueCount == 0
        ? '运行清爽'
        : issueCount <= 2
        ? '建议微调'
        : '需要整理';
    return WeavingCard(
      color: AppColors.surfaceLowest.withValues(alpha: 0.94),
      onTap: onTap,
      interactionStyle: WeavingInteractionStyle.timelineSlide,
      child: Row(
        children: [
          _ProfileHeaderBubble(
            icon: Icons.check_circle_rounded,
            background: issueCount == 0
                ? AppColors.primarySoft
                : AppColors.gold,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '智能体一键体检',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    InfoChip(
                      label: '$score 分',
                      backgroundColor: issueCount == 0
                          ? AppColors.primarySoft
                          : AppColors.coral,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  issueCount == 0
                      ? '时间线、提醒、风险边界与消息收纳状态良好。'
                      : '发现 $issueCount 项可优化内容，点击进入逐项处理。',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _FlowMiniTile extends StatelessWidget {
  const _FlowMiniTile({
    required this.icon,
    required this.title,
    required this.summary,
    required this.background,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String summary;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: WeavingCard(
        color: background,
        onTap: onTap,
        interactionStyle: WeavingInteractionStyle.iconGlow,
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
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
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

class _AchievementPreviewCard extends StatelessWidget {
  const _AchievementPreviewCard({
    required this.controller,
    required this.onOpenAll,
  });

  final AppController controller;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '使用概览',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(onPressed: onOpenAll, child: const Text('查看全部')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _AchievementBadge(
                title: '已确认记录',
                subtitle: '累计沉淀 ${controller.confirmedEvents.length} 条安排',
                background: AppColors.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AchievementBadge(
                title: '待确认事项',
                subtitle: '仍有 ${controller.pendingNotices.length} 条待确认',
                background: AppColors.primarySoft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AchievementBadge(
                title: '已设置提醒',
                subtitle: '已挂载 ${controller.scheduledReminderCount} 条提醒',
                background: AppColors.coral,
              ),
            ),
          ],
        ),
      ],
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
    return SizedBox(
      height: 124,
      child: WeavingCard(
        color: background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_graph_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
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
          .toSet()
          .take(4),
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
              !ZhishiDateUtils.isToday(
                event.startTimeIso ?? event.deadlineIso,
              )) {
            return false;
          }
          if (_dateFilter == '本周') {
            final schedule = event.startTime ?? event.deadline;
            if (schedule == null) return false;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final eventDate = DateTime(
              schedule.year,
              schedule.month,
              schedule.day,
            );
            final windowStart = today.subtract(const Duration(days: 3));
            final windowEnd = today.add(const Duration(days: 7));
            if (eventDate.isBefore(windowStart) ||
                eventDate.isAfter(windowEnd)) {
              return false;
            }
          }
          if (_dateFilter == '待定' &&
              (event.startTime ?? event.deadline) != null) {
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _HistorySearchPanel(
          queryController: _query,
          dateFilter: _dateFilter,
          statusFilter: _statusFilter,
          sourceFilter: _sourceFilter,
          sourceOptions: sourceOptions,
          onQueryChanged: (_) => setState(() {}),
          onDateFilterChanged: (value) => setState(() => _dateFilter = value),
          onStatusFilterChanged: (value) =>
              setState(() => _statusFilter = value),
          onSourceFilterChanged: (value) =>
              setState(() => _sourceFilter = value),
        ),
        const SizedBox(height: 10),
        _HistoryResultSection(
          items: filtered,
          totalCount: events.length,
          onOpenTimeline: () => widget.controller.setTab(1),
          onReparse: widget.controller.reparseEvent,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: () => widget.controller.setTab(1),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('进入时间线总览'),
            style: FilledButton.styleFrom(shape: const StadiumBorder()),
          ),
        ),
      ],
    );
  }
}

class _HistorySearchPanel extends StatelessWidget {
  const _HistorySearchPanel({
    required this.queryController,
    required this.dateFilter,
    required this.statusFilter,
    required this.sourceFilter,
    required this.sourceOptions,
    required this.onQueryChanged,
    required this.onDateFilterChanged,
    required this.onStatusFilterChanged,
    required this.onSourceFilterChanged,
  });

  final TextEditingController queryController;
  final String dateFilter;
  final String statusFilter;
  final String sourceFilter;
  final List<String> sourceOptions;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onDateFilterChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final ValueChanged<String> onSourceFilterChanged;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      color: AppColors.surfaceLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ProfileHeaderBubble(
                icon: Icons.search_rounded,
                background: AppColors.primarySoft,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '历史资产检索',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '按标题、地点、来源快速定位',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: queryController,
            onChanged: onQueryChanged,
            cursorColor: AppColors.primary,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
              ),
              hintText: '搜索讲座、教室、截图来源...',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.42),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _HistoryFilterRow(
            options: const ['全部', '今日', '本周', '待定'],
            selected: dateFilter,
            onSelected: onDateFilterChanged,
          ),
          const SizedBox(height: 10),
          _HistoryFilterRow(
            options: const ['全部', '已确认', '待校验'],
            selected: statusFilter,
            onSelected: onStatusFilterChanged,
          ),
          const SizedBox(height: 10),
          _HistoryFilterRow(
            options: sourceOptions,
            selected: sourceFilter,
            onSelected: onSourceFilterChanged,
          ),
        ],
      ),
    );
  }
}

class _HistoryFilterRow extends StatelessWidget {
  const _HistoryFilterRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < options.take(5).length; index++) ...[
          Expanded(
            child: SizedBox(
              height: 42,
              child: WeavingCard(
                padding: EdgeInsets.zero,
                color: options[index] == selected
                    ? AppColors.gold
                    : Colors.white.withValues(alpha: 0.5),
                onTap: () => onSelected(options[index]),
                interactionStyle: WeavingInteractionStyle.iconGlow,
                child: Center(
                  child: Text(
                    options[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: options[index] == selected
                          ? AppColors.primary
                          : AppColors.muted,
                      fontWeight: options[index] == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (index < options.take(5).length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _HistoryResultSection extends StatelessWidget {
  const _HistoryResultSection({
    required this.items,
    required this.totalCount,
    required this.onOpenTimeline,
    required this.onReparse,
  });

  final List<EventItem> items;
  final int totalCount;
  final VoidCallback onOpenTimeline;
  final Future<void> Function(EventItem event) onReparse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailSectionHeader(
          title: '检索结果',
          summary: '当前命中 ${items.length} / $totalCount 条，可回看或重新解析。',
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          WeavingCard(
            color: AppColors.surfaceLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ProfileHeaderBubble(
                  icon: Icons.query_stats_rounded,
                  background: AppColors.gold,
                ),
                const SizedBox(height: 10),
                Text(
                  '暂未找到匹配记录',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '可以切换日期、状态或来源筛选，也可以回到时间线查看全部沉淀。',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: onOpenTimeline,
                    icon: const Icon(Icons.timeline_rounded),
                    label: const Text('查看全部时间线'),
                    style: FilledButton.styleFrom(shape: const StadiumBorder()),
                  ),
                ),
              ],
            ),
          )
        else
          ...items
              .take(12)
              .map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _HistoryRecordCard(
                    event: event,
                    onOpenTimeline: onOpenTimeline,
                    onReparse: () => onReparse(event),
                  ),
                ),
              ),
      ],
    );
  }
}

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({
    required this.event,
    required this.onOpenTimeline,
    required this.onReparse,
  });

  final EventItem event;
  final VoidCallback onOpenTimeline;
  final VoidCallback onReparse;

  @override
  Widget build(BuildContext context) {
    final statusColor = event.status.contains('待')
        ? AppColors.coral
        : AppColors.primarySoft;
    return WeavingCard(
      color: AppColors.surfaceLowest,
      onTap: onReparse,
      interactionStyle: WeavingInteractionStyle.timelineSlide,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeaderBubble(
                icon: Icons.history_rounded,
                background: statusColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title.trim().isEmpty ? '未命名校园事项' : event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _historyRecordSummary(event),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        InfoChip(
                          label: event.status.trim().isEmpty
                              ? '待校验'
                              : event.status,
                          backgroundColor: statusColor,
                        ),
                        InfoChip(
                          label: event.source.label.trim().isEmpty
                              ? '未知来源'
                              : event.source.label,
                          backgroundColor: AppColors.gold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HistoryMiniAction(
                  icon: Icons.timeline_rounded,
                  label: '查看时间线',
                  onTap: onOpenTimeline,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _HistoryMiniAction(
                  icon: Icons.replay_rounded,
                  label: '重新解析',
                  onTap: onReparse,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryMiniAction extends StatelessWidget {
  const _HistoryMiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: WeavingCard(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.surfaceWarm,
        onTap: onTap,
        interactionStyle: WeavingInteractionStyle.primaryPress,
        borderRadius: 999,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _historyRecordSummary(EventItem event) {
  final schedule = event.startTime ?? event.deadline;
  final rawTime = event.startTimeIso ?? event.deadlineIso;
  final allDay =
      schedule != null &&
      schedule.hour == 0 &&
      schedule.minute == 0 &&
      !ZhishiDateUtils.hasExplicitTime(rawTime);
  final time = schedule == null
      ? '时间待校验'
      : '${ZhishiDateUtils.formatDay(schedule)} '
            '${allDay ? '全天' : ZhishiDateUtils.formatTime(schedule)}';
  final location = (event.location ?? '').trim().isEmpty
      ? '地点待校验'
      : event.location!.trim();
  final summary = (event.description ?? '').trim().isEmpty
      ? '从校园碎片中沉淀的时间资产'
      : event.description!.trim();
  return '$time · $location · $summary';
}

class _StatisticsPage extends StatelessWidget {
  const _StatisticsPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final sourceCount = controller.confirmedEvents
        .map((event) => event.source.label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .length;
    final locationReadyCount = controller.confirmedEvents
        .where((event) => event.location?.trim().isNotEmpty == true)
        .length;
    final recentRecognizedCount = controller.confirmedEvents
        .where(
          (event) =>
              event.description?.trim().isNotEmpty == true ||
              event.startTimeIso?.trim().isNotEmpty == true ||
              event.deadlineIso?.trim().isNotEmpty == true,
        )
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.timeline_rounded,
              value: '${controller.confirmedEvents.length}',
              label: '已沉淀',
              color: AppColors.gold,
            ),
            _MetricBox(
              icon: Icons.notifications_active_rounded,
              value: '${controller.scheduledReminderCount}',
              label: '待提醒',
              color: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.calendar_month_rounded,
              value: '${controller.todayEvents.length}',
              label: '今日',
              color: AppColors.surfaceWarm,
            ),
            _MetricBox(
              icon: Icons.shield_rounded,
              value: '${controller.pendingNotices.length}',
              label: '待校验',
              color: AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DetailSectionHeader(title: '数据切面'),
            const SizedBox(height: 6),
            _NavGrid(
              items: [
                _NavItemSpec(
                  Icons.history_rounded,
                  '来源数',
                  '$sourceCount 个常用来源',
                  null,
                  color: AppColors.gold,
                ),
                _NavItemSpec(
                  Icons.location_on_rounded,
                  '地点完整',
                  '$locationReadyCount 条可直接导航',
                  null,
                  color: AppColors.primarySoft,
                ),
                _NavItemSpec(
                  Icons.psychology_rounded,
                  '识别沉淀',
                  '$recentRecognizedCount 条已有解析结果',
                  null,
                  color: AppColors.surfaceWarm,
                ),
                _NavItemSpec(
                  Icons.notifications_active_rounded,
                  '消息箱',
                  '${controller.inboxMessages.length} 条消息待回看',
                  null,
                  color: AppColors.coral,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: () => controller.setTab(1),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('查看时间线资产'),
            style: FilledButton.styleFrom(shape: const StadiumBorder()),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.storage_rounded,
              value: '$confirmedCount',
              label: '沉淀',
              color: AppColors.gold,
            ),
            _MetricBox(
              icon: Icons.notifications_active_rounded,
              value: '$reminderCount',
              label: '提醒',
              color: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(title: '记录概览'),
        const SizedBox(height: 6),
        _NavGrid(
          items: [
            _NavItemSpec(
              Icons.auto_graph_rounded,
              '已确认记录',
              '已累计沉淀 $confirmedCount 条安排',
              null,
              color: AppColors.gold,
            ),
            _NavItemSpec(
              Icons.notifications_active_rounded,
              '已设置提醒',
              '已挂载 $reminderCount 条提醒',
              null,
              color: AppColors.primarySoft,
            ),
            _NavItemSpec(
              Icons.shield_rounded,
              '待确认事项',
              '$pendingCount 条待确认，保留人工确认',
              null,
              color: AppColors.coral,
            ),
            const _NavItemSpec(
              Icons.timeline_rounded,
              '时间线记录',
              '持续整理讲座、会议和群通知',
              null,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(title: '整理建议'),
        const SizedBox(height: 6),
        WeavingCard(
          color: AppColors.surfaceLowest,
          child: const Column(
            children: [
              _DetailGuideRow(
                icon: Icons.history_rounded,
                title: '持续整理',
                summary: '把讲座、会议和群通知转为时间线，方便后续回看。',
              ),
              SizedBox(height: 10),
              _DetailGuideRow(
                icon: Icons.query_stats_rounded,
                title: '低置信度校验',
                summary: '主动修正时间和地点字段，减少误写入风险。',
              ),
              SizedBox(height: 10),
              _DetailGuideRow(
                icon: Icons.download_rounded,
                title: '定期备份',
                summary: '按需整理时间线记录，方便归档和分享。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _DetailInfoCard(
          title: '下一步建议',
          value: '持续整理',
          summary: '继续把讲座、会议和群通知转为时间线，保持记录可检索、可提醒。',
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        WeavingCard(
          color: AppColors.surfaceLowest,
          child: Column(
            children: [
              _SwitchTile(
                icon: Icons.shield_rounded,
                title: '高风险动作拦截',
                subtitle: '遇到低确定性或越权操作时先停在你这里',
                value: preference.blockHighRisk,
                onChanged: (value) => controller.savePreference(
                  preference.copyWith(blockHighRisk: value),
                ),
              ),
              const SizedBox(height: 10),
              _SwitchTile(
                icon: Icons.notifications_active_rounded,
                title: '低置信度静默处理',
                subtitle: '置信度不够时避免自动推进，等你来确认',
                value: preference.muteLowConfidence,
                onChanged: (value) => controller.savePreference(
                  preference.copyWith(muteLowConfidence: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        WeavingCard(
          color: AppColors.surfaceLowest,
          child: Column(
            children: [
              _ReminderLeadDaysTile(controller: controller),
              const SizedBox(height: 10),
              _ReminderLeadTile(controller: controller),
              const SizedBox(height: 10),
              _SwitchTile(
                icon: Icons.timeline_rounded,
                title: '地点识别联动',
                subtitle: '识别到地点后自动补足导航兜底能力',
                value: preference.autoMapLink,
                onChanged: (value) => controller.savePreference(
                  preference.copyWith(autoMapLink: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _DetailInfoCard(
          title: '使用建议',
          value: '按需调整',
          summary: '可根据使用习惯快速调整提醒、确认和地点联动策略。',
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        const _DetailSectionHeader(title: '账号与设置'),
        const SizedBox(height: 6),
        _NavGrid(
          items: [
            _NavItemSpec(
              Icons.manage_accounts_rounded,
              '当前账号',
              controller.currentAccountLabel.trim().isEmpty
                  ? '未登录'
                  : controller.currentAccountLabel,
              null,
            ),
            _NavItemSpec(
              Icons.person_rounded,
              '个人资料',
              '管理头像、签名与校园身份',
              () => onNavigate(ProfileRoute.personalInfo),
              color: AppColors.gold,
            ),
            _NavItemSpec(
              Icons.notifications_active_rounded,
              '提醒设置',
              '管理默认提前量与提醒方式',
              () => onNavigate(ProfileRoute.reminderCenter),
              color: AppColors.primarySoft,
            ),
            _NavItemSpec(
              Icons.shield_rounded,
              '隐私与安全',
              '管理确认策略与风险拦截',
              () => onNavigate(ProfileRoute.privacySecurity),
              color: AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(title: '运行与策略'),
        const SizedBox(height: 6),
        _NavGrid(
          items: [
            _NavItemSpec(
              Icons.psychology_rounded,
              '运行状态',
              '查看智能解析与设备能力',
              () => onNavigate(ProfileRoute.runtimeStatus),
              color: AppColors.primarySoft,
            ),
            _NavItemSpec(
              Icons.tune_rounded,
              '确认策略',
              '管理低置信度事项的确认方式',
              () => onNavigate(ProfileRoute.preferences),
              color: AppColors.gold,
            ),
          ],
        ),
      ],
    );
  }
}

class _PersonalInfoPage extends StatefulWidget {
  const _PersonalInfoPage({required this.controller, required this.onSaved});

  final AppController controller;
  final VoidCallback onSaved;

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
    final nickname = _nickname.text.trim();
    final profileLine = [
      widget.controller.currentAccountLabel.trim(),
      _school.text.trim(),
      _major.text.trim(),
      _grade.text.trim(),
    ].where((value) => value.isNotEmpty).join(' · ');
    final brief = _buildProfileBrief(
      birthday: _birthday.text.trim(),
      age: _age.text.trim(),
      gender: _gender.text.trim(),
      hometown: _hometown.text.trim(),
    );
    final avatarReady =
        _avatarPath.isNotEmpty && File(_avatarPath).existsSync();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        WeavingCard(
          color: AppColors.surfaceLowest.withValues(alpha: 0.94),
          onTap: _showAvatarSheet,
          child: Row(
            children: [
              CircleAvatar(
                radius: 41,
                backgroundColor: AppColors.coral,
                backgroundImage: avatarReady
                    ? FileImage(File(_avatarPath))
                    : null,
                child: avatarReady
                    ? null
                    : Text(
                        nickname.isEmpty
                            ? (widget.controller.currentAccountLabel.isEmpty
                                  ? '织'
                                  : widget
                                        .controller
                                        .currentAccountLabel
                                        .characters
                                        .first)
                            : nickname.characters.first,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname.isEmpty ? '织时用户' : nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profileLine.isEmpty ? '完善校园身份资料' : profileLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _signature.text.trim().isEmpty
                          ? brief
                          : _signature.text.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ProfileEditGroup(
          title: '公开展示',
          child: Column(
            children: [
              _InputField(
                controller: _nickname,
                icon: Icons.person_rounded,
                label: '昵称',
                placeholder: '输入你的昵称',
                maxLength: 24,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _InputField(
                controller: _signature,
                icon: Icons.drive_file_rename_outline_rounded,
                label: '个性签名',
                placeholder: '如：把校园碎片织成自己的节奏',
                maxLines: 3,
                maxLength: 80,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ProfileEditGroup(
          title: '校园身份',
          child: Column(
            children: [
              _InputField(
                controller: _school,
                icon: Icons.school_rounded,
                label: '学校',
                placeholder: '如：华南理工大学',
                maxLength: 40,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _InputField(
                controller: _major,
                icon: Icons.badge_rounded,
                label: '专业',
                placeholder: '如：人工智能',
                maxLength: 40,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _InputField(
                controller: _grade,
                icon: Icons.home_work_rounded,
                label: '年级',
                placeholder: '如：大二 / 2024级',
                maxLength: 24,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ProfileEditGroup(
          title: '基础信息',
          child: Column(
            children: [
              _InputField(
                controller: _birthday,
                icon: Icons.cake_rounded,
                label: '生日',
                placeholder: '如：2005-05-14',
                maxLength: 20,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _InputField(
                controller: _age,
                icon: Icons.person_rounded,
                label: '年龄',
                placeholder: '如：21',
                maxLength: 3,
                digitsOnly: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _InputField(
                controller: _gender,
                icon: Icons.manage_accounts_rounded,
                label: '性别',
                placeholder: '如：男 / 女 / 不展示',
                maxLength: 12,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _InputField(
                controller: _hometown,
                icon: Icons.location_on_rounded,
                label: '家乡',
                placeholder: '如：广东广州',
                maxLength: 40,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.manage_accounts_rounded),
            label: const Text('保存个人资料'),
          ),
        ),
      ],
    );
  }

  Future<void> _showAvatarSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceWarm,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '更换头像',
                style: Theme.of(sheetContext).textTheme.headlineMedium
                    ?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              _AvatarSheetAction(
                icon: Icons.photo_library_rounded,
                title: '从相册选择',
                subtitle: '从本机图片中选择一张作为头像',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAvatar(SourceType.album);
                },
              ),
              const SizedBox(height: 10),
              _AvatarSheetAction(
                icon: Icons.camera_alt_rounded,
                title: '拍照更换',
                subtitle: '直接拍一张新的照片作为头像',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAvatar(SourceType.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar(SourceType type) async {
    final path = await widget.controller.pickImage(type);
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
    if (!mounted) return;
    widget.onSaved();
  }
}

class _ReminderCenterPage extends StatelessWidget {
  const _ReminderCenterPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final preference = controller.preference;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.notifications_active_rounded,
              value: '${controller.scheduledReminderCount}',
              label: '已挂载',
              color: AppColors.gold,
            ),
            _MetricBox(
              icon: Icons.tune_rounded,
              value: '${preference.reminderLeadMinutes}',
              label: '提前量',
              color: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 10),
        WeavingCard(
          color: AppColors.surfaceLowest,
          child: Column(
            children: [
              _ReminderLeadDaysTile(controller: controller),
              const SizedBox(height: 10),
              _ReminderLeadTile(controller: controller),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(
          title: '提醒策略',
          summary: '参考成熟任务应用的多层提醒思路，但只保留校园高频场景。',
        ),
        const SizedBox(height: 6),
        const _NavGrid(
          items: [
            _NavItemSpec(
              Icons.shield_rounded,
              '高风险先确认',
              '考试 / 截止 / 地点不明先停下',
              null,
              color: AppColors.coral,
            ),
            _NavItemSpec(
              Icons.calendar_month_rounded,
              '日级预热',
              '先给准备窗口，避免临时赶场',
              null,
              color: AppColors.gold,
            ),
            _NavItemSpec(
              Icons.notifications_active_rounded,
              '分钟级提醒',
              '出门前再次触达',
              null,
              color: AppColors.primarySoft,
            ),
            _NavItemSpec(Icons.map_rounded, '地点兜底', '明确地点后可联动导航', null),
          ],
        ),
        const SizedBox(height: 10),
        const _DetailInfoCard(
          title: '策略说明',
          value: '人在回路',
          summary: '织时不会绕过确认卡直接替你建立高风险提醒；字段可信后才进入本地提醒。',
        ),
      ],
    );
  }
}

class _TimelineAssetsPage extends StatelessWidget {
  const _TimelineAssetsPage({
    required this.controller,
    required this.onNavigate,
  });

  final AppController controller;
  final ValueChanged<ProfileRoute> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.storage_rounded,
              value: '${controller.confirmedEvents.length}',
              label: '已确认',
              color: AppColors.gold,
              onTap: () => controller.setTab(1),
            ),
            _MetricBox(
              icon: Icons.query_stats_rounded,
              value: '${controller.todayEvents.length}',
              label: '今日',
              color: AppColors.primarySoft,
              onTap: () => controller.setTab(1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.shield_rounded,
              value: '${controller.pendingNotices.length}',
              label: '待校验',
              color: AppColors.coral,
              onTap: () => controller.setTab(1),
            ),
            _MetricBox(
              icon: Icons.notifications_active_rounded,
              value: '${controller.scheduledReminderCount}',
              label: '待提醒',
              color: AppColors.surfaceWarm,
              onTap: () => controller.setTab(1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _DetailInfoCard(
          title: '资产状态',
          value: '持续织入',
          summary: '每一次确认写入都会把零散通知变成可检索、可提醒、可整理的个人时间线记录。',
        ),
        const SizedBox(height: 10),
        _TimelineExportEntryCard(
          onTap: () => onNavigate(ProfileRoute.exportRecords),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => controller.setTab(1),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('打开时间线'),
          ),
        ),
      ],
    );
  }
}

class _TimelineExportEntryCard extends StatelessWidget {
  const _TimelineExportEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      color: AppColors.surfaceLowest,
      onTap: onTap,
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 48,
            child: _ProfileHeaderBubble(
              icon: Icons.download_rounded,
              background: AppColors.gold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '记录导出',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '导出和备份时间线记录',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _ExportRecordsPage extends StatelessWidget {
  const _ExportRecordsPage({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.timeline_rounded,
              value: '${controller.confirmedEvents.length}',
              label: '时间线',
              color: AppColors.gold,
            ),
            _MetricBox(
              icon: Icons.notifications_active_rounded,
              value: '${controller.scheduledReminderCount}',
              label: '提醒',
              color: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(title: '导出类型'),
        const SizedBox(height: 6),
        _NavGrid(
          items: [
            _NavItemSpec(
              Icons.download_rounded,
              'PDF 归档',
              '导出本月时间线 PDF',
              controller.exportTimelinePdf,
              color: AppColors.gold,
            ),
            _NavItemSpec(
              Icons.query_stats_rounded,
              'PNG 长图',
              '导出本月时间线图片',
              controller.exportTimelinePng,
              color: AppColors.primarySoft,
            ),
            _NavItemSpec(
              Icons.photo_library_rounded,
              'JPG 图片',
              '导出本月时间线图片',
              controller.exportTimelineJpg,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _DetailInfoCard(
          title: '导出建议',
          value: '先筛选，再导出',
          summary: '建议先在时间线页切换日 / 周 / 月视图，再导出需要的记录。',
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => controller.setTab(1),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('打开时间线'),
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
      ApiConfig.appId.trim().isNotEmpty,
      ApiConfig.apiKey.trim().isNotEmpty,
      controller.dataStoreReady,
      controller.currentAccountLabel.trim().isNotEmpty,
      controller.cameraPermissionReady,
      controller.microphonePermissionReady,
    ].where((item) => item).length;
    final rows = <_RuntimeBoardSpec>[
      _RuntimeBoardSpec(
        icon: Icons.psychology_rounded,
        title: '智能解析',
        summary: controller.runtimeModelName,
        ready: ApiConfig.hasChatConfig && ApiConfig.appId.trim().isNotEmpty,
      ),
      _RuntimeBoardSpec(
        icon: Icons.document_scanner_rounded,
        title: '图文 OCR',
        summary: _endpointTail(controller.ocrEndpoint),
        ready: controller.ocrEndpoint.trim().isNotEmpty,
      ),
      _RuntimeBoardSpec(
        icon: Icons.storage_rounded,
        title: '本地数据',
        summary:
            '${controller.confirmedEvents.length + controller.pendingNotices.length} 条记录 / ${controller.inboxMessages.length} 条消息',
        ready: controller.dataStoreReady,
      ),
      _RuntimeBoardSpec(
        icon: Icons.notifications_active_rounded,
        title: '提醒调度',
        summary: '${controller.scheduledReminderCount} 条提醒策略',
        ready: true,
      ),
      _RuntimeBoardSpec(
        icon: Icons.manage_accounts_rounded,
        title: '账号会话',
        summary: controller.currentAccountLabel.trim().isEmpty ? '未登录' : '已登录',
        ready: controller.currentAccountLabel.trim().isNotEmpty,
      ),
      _RuntimeBoardSpec(
        icon: Icons.photo_camera_rounded,
        title: '相机入口',
        summary: controller.cameraPermissionReady ? '可用' : '待授权',
        ready: controller.cameraPermissionReady,
      ),
      _RuntimeBoardSpec(
        icon: Icons.tune_rounded,
        title: '语音入口',
        summary: controller.microphonePermissionReady ? '可用' : '待授权',
        ready: controller.microphonePermissionReady,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.check_circle_rounded,
              value: '$readyCount/6',
              label: '就绪模块',
              color: readyCount >= 5 ? AppColors.primarySoft : AppColors.gold,
            ),
            _MetricBox(
              icon: Icons.storage_rounded,
              value:
                  '${controller.confirmedEvents.length + controller.pendingNotices.length}',
              label: '本地记录',
              color: AppColors.gold,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _DetailInfoCard(
          title: '解析服务',
          value: ApiConfig.hasChatConfig && ApiConfig.appId.trim().isNotEmpty
              ? '可用'
              : '待配置',
          summary:
              '当前智能解析服务为 ${controller.runtimeModelName}，图文识别服务 ${_endpointTail(controller.ocrEndpoint)}。',
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(title: '模块状态', summary: '以下为当前应用可读取到的运行状态。'),
        const SizedBox(height: 6),
        WeavingCard(
          color: AppColors.surfaceLowest,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                _RuntimeStatusRow(row: rows[i]),
                if (i < rows.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(
          title: '运行建议',
          summary: '保持模型配置、权限和本地记录状态可用。',
        ),
        const SizedBox(height: 6),
        const _NavGrid(
          items: [
            _NavItemSpec(
              Icons.psychology_rounded,
              '智能解析',
              '保持网络与服务配置可用',
              null,
              color: AppColors.primarySoft,
            ),
            _NavItemSpec(Icons.storage_rounded, '数据记录', '保持时间线记录及时整理', null),
            _NavItemSpec(
              Icons.notifications_active_rounded,
              '提醒状态',
              '确认提醒数量和权限状态',
              null,
              color: AppColors.coral,
            ),
          ],
        ),
      ],
    );
  }
}

class _RuntimeStatusRow extends StatelessWidget {
  const _RuntimeStatusRow({required this.row});

  final _RuntimeBoardSpec row;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: row.ready ? AppColors.primarySoft : AppColors.coral,
              shape: BoxShape.circle,
            ),
            child: Icon(row.icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  row.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
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
    final filtered = _filterInboxMessages(
      controller.inboxMessages,
      _filter,
    ).take(20).toList();
    final pendingCount = controller.inboxMessages
        .where(
          (message) =>
              message.status.contains('待') || message.status.contains('未读'),
        )
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.shield_rounded,
              value: '${controller.pendingNotices.length}',
              label: '待校验',
              color: AppColors.coral,
            ),
            _MetricBox(
              icon: Icons.notifications_active_rounded,
              value: '${controller.scheduledReminderCount}',
              label: '已提醒',
              color: AppColors.gold,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(title: '消息概览'),
        const SizedBox(height: 6),
        _NavGrid(
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
        const SizedBox(height: 10),
        _DetailSectionHeader(title: _inboxSectionTitle(_filter)),
        const SizedBox(height: 6),
        if (filtered.isEmpty)
          const _DetailInfoCard(
            title: '收纳箱',
            value: '干净',
            summary: '当你导入图片、确认日程、取消执行或遇到低置信度结果时，这里会保留可回看的系统记录。',
          )
        else
          WeavingCard(
            color: AppColors.surfaceLowest,
            child: Column(
              children: [
                for (var i = 0; i < filtered.length; i++) ...[
                  _InboxMessageRow(
                    message: filtered[i],
                    onTap: () => _openMessageDetail(context, filtered[i]),
                  ),
                  if (i < filtered.length - 1) const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        if (filtered.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: controller.clearInboxMessages,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('清空通知中心'),
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => widget.onNavigate(ProfileRoute.preferences),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('调整通知策略'),
          ),
        ),
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

class _InboxMessageRow extends StatelessWidget {
  const _InboxMessageRow({required this.message, required this.onTap});

  final InboxMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = _inboxMessageBackground(message.type, message.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _inboxMessageIcon(message.type, message.status),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.title.isEmpty ? '织时消息' : message.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InfoChip(
                          label: message.status.isEmpty ? '未读' : message.status,
                          backgroundColor: background,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.summary.isEmpty ? '暂无摘要' : message.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ZhishiDateUtils.formatExport(
                        DateTime.fromMillisecondsSinceEpoch(
                          message.createdAtMillis,
                        ),
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        WeavingCard(
          color: AppColors.surfaceLowest,
          child: Column(
            children: [
              _SwitchTile(
                icon: Icons.shield_rounded,
                title: '高风险动作拦截',
                subtitle: '考试、截止、地点不明等事项必须先经你确认。',
                value: preference.blockHighRisk,
                onChanged: (value) => controller.savePreference(
                  preference.copyWith(blockHighRisk: value),
                ),
              ),
              const SizedBox(height: 10),
              _SwitchTile(
                icon: Icons.notifications_active_rounded,
                title: '低置信度静默处理',
                subtitle: '置信度不足时不自动推进，减少误写入风险。',
                value: preference.muteLowConfidence,
                onChanged: (value) => controller.savePreference(
                  preference.copyWith(muteLowConfidence: value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(
          title: '安全边界',
          summary: '所有高风险操作都保留确认环节，避免自动误写入。',
        ),
        const SizedBox(height: 6),
        const _NavGrid(
          items: [
            _NavItemSpec(
              Icons.security_rounded,
              '人在回路',
              '确认后才写入高风险日程',
              null,
              color: AppColors.coral,
            ),
            _NavItemSpec(
              Icons.storage_rounded,
              '本地沉淀',
              '账号与偏好保存在设备侧',
              null,
              color: AppColors.gold,
            ),
            _NavItemSpec(
              Icons.psychology_rounded,
              '解析可追溯',
              '保留信心指数与结构化字段',
              null,
              color: AppColors.primarySoft,
            ),
            _NavItemSpec(Icons.map_rounded, '地点兜底', '地点明确才联动导航', null),
          ],
        ),
        const SizedBox(height: 10),
        const _DetailInfoCard(
          title: '隐私说明',
          value: '最小必要',
          summary: '织时只围绕校园通知解析、日程确认、提醒和时间线沉淀组织数据，不把低置信度结果直接越权执行。',
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.timeline_rounded,
              value: '${controller.confirmedEvents.length}',
              label: '已确认',
              color: AppColors.gold,
            ),
            _MetricBox(
              icon: Icons.shield_rounded,
              value: '${controller.pendingNotices.length}',
              label: '待处理',
              color: AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.notifications_active_rounded,
              value: '${controller.scheduledReminderCount}',
              label: '提醒',
              color: AppColors.primarySoft,
            ),
            _MetricBox(
              icon: Icons.storage_rounded,
              value: controller.dataStoreReady ? 'ON' : 'OFF',
              label: '本地库',
              color: Colors.white,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(title: '数据分层'),
        const SizedBox(height: 6),
        _NavGrid(
          items: [
            const _NavItemSpec(
              Icons.history_rounded,
              '导入来源',
              '文本、截图、海报和语音统一建模',
              null,
              color: AppColors.gold,
            ),
            const _NavItemSpec(
              Icons.psychology_rounded,
              '解析结果',
              '保留结构化字段和信心指数',
              null,
              color: AppColors.primarySoft,
            ),
            _NavItemSpec(
              Icons.timeline_rounded,
              '时间资产',
              '确认后沉淀到专属时间线',
              () => controller.setTab(1),
            ),
            _NavItemSpec(
              Icons.download_rounded,
              '导出记录',
              '生成 PDF / PNG / JPG 文件',
              () => onNavigate(ProfileRoute.exportRecords),
              color: AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => controller.setTab(1),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('查看时间线资产'),
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
    final confirmedItems = controller.confirmedEvents;
    if (confirmed + pending < 3) {
      return const _PersonaSummary(
        title: '画像生成中',
        description: '继续确认时间线记录后，系统会生成更准确的使用偏好参考。',
        tags: ['资料不足'],
        evidence: ['当前可用记录较少'],
      );
    }

    final tags = <String>[];
    final evidence = <String>[];
    final sourceLabels = confirmedItems
        .map((event) => event.source.label)
        .toList();
    final imageSourceCount = sourceLabels
        .where(
          (label) =>
              label.contains('图片') ||
              label.contains('相册') ||
              label.contains('拍摄'),
        )
        .length;
    final textSourceCount = sourceLabels
        .where(
          (label) =>
              label.contains('文本') ||
              label.contains('剪贴板') ||
              label.contains('手动') ||
              label.contains('分享'),
        )
        .length;
    final locationReadyCount = confirmedItems
        .where(
          (event) =>
              (event.location?.trim().isNotEmpty ?? false) &&
              event.location?.trim() != '无地点',
        )
        .length;
    final locationCompleteRate = confirmedItems.isEmpty
        ? 0.0
        : locationReadyCount / confirmedItems.length;
    final now = DateTime.now();
    final expiredItemCount = confirmedItems
        .where((event) => event.startTime?.isBefore(now) ?? false)
        .length;

    if (reminders >= 3 || (confirmed > 0 && reminders * 2 >= confirmed)) {
      tags.add('提醒依赖型');
      evidence.add('已有 $reminders 项事项挂载后续提醒');
    }
    if (confirmed >= 5) {
      tags.add('时间线沉淀型');
      evidence.add('已确认 $confirmed 条时间线记录');
    }
    if (expiredItemCount > 0) {
      tags.add('过期事项沉淀');
      evidence.add('时间线中有 $expiredItemCount 条记录已过期，可作为作息与提醒策略参考');
    }
    if (pending >= 3 || pending > confirmed) {
      tags.add('待确认偏多');
      evidence.add('仍有 $pending 条事项等待确认或补充');
    }
    if (locationCompleteRate >= 0.7 && confirmedItems.isNotEmpty) {
      tags.add('地点信息完整');
      evidence.add('多数已确认记录包含地点信息');
    }
    if (imageSourceCount > textSourceCount && imageSourceCount > 0) {
      tags.add('图片导入常用');
      evidence.add('常通过图片入口导入校园通知');
    } else if (textSourceCount > 0) {
      tags.add('文本整理常用');
      evidence.add('常通过文本、剪贴板或系统分享导入通知');
    }
    if (tags.isEmpty) {
      tags.add('稳态整理');
      evidence.add('当前记录、提醒与确认状态较均衡');
    }

    final title = tags.contains('过期事项沉淀')
        ? '提醒节奏需要回看'
        : tags.contains('待确认偏多')
        ? '待确认事项需要回看'
        : tags.contains('提醒依赖型')
        ? '提醒辅助型'
        : tags.contains('时间线沉淀型')
        ? '时间线整理型'
        : '稳态整理型';

    return _PersonaSummary(
      title: title,
      description: expiredItemCount > 0
          ? '根据已确认记录、提醒设置、导入来源与过期事项动态生成，帮助你回看自己的时间管理节奏。'
          : '根据已确认记录、提醒设置和导入来源动态生成，仅作为使用偏好参考。',
      tags: tags.toSet().take(4).toList(),
      evidence: evidence.toSet().take(5).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final persona = _buildPersona();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.calendar_month_rounded,
              value: '${controller.todayEvents.length}',
              label: '今日',
              color: AppColors.gold,
            ),
            _MetricBox(
              icon: Icons.notifications_active_rounded,
              value: '${controller.scheduledReminderCount}',
              label: '提醒',
              color: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _DetailInfoCard(
          title: '当前画像',
          value: persona.title,
          summary: persona.description,
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(title: '偏好标签'),
        const SizedBox(height: 6),
        _NavGrid(
          items: persona.tags.indexed
              .map(
                (entry) => _NavItemSpec(
                  Icons.check_circle_rounded,
                  entry.$2,
                  '动态生成',
                  null,
                  color: switch (entry.$1 % 4) {
                    0 => AppColors.gold,
                    1 => AppColors.coral,
                    2 => AppColors.primarySoft,
                    _ => AppColors.surfaceWarm,
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(title: '生成依据'),
        const SizedBox(height: 6),
        WeavingCard(
          color: AppColors.surfaceLowest,
          child: Column(
            children: [
              for (var i = 0; i < persona.evidence.length; i++) ...[
                _DetailGuideRow(
                  icon: Icons.query_stats_rounded,
                  title: persona.evidence[i],
                  summary: '基于当前本机记录计算',
                ),
                if (i < persona.evidence.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _DetailInfoCard(
          title: '最近更新',
          value: '实时计算',
          summary: '每次确认记录、补充地点或调整提醒后，使用偏好画像会随当前数据刷新。',
        ),
      ],
    );
  }
}

class _PersonaSummary {
  const _PersonaSummary({
    required this.title,
    required this.description,
    required this.tags,
    required this.evidence,
  });

  final String title;
  final String description;
  final List<String> tags;
  final List<String> evidence;
}

class _AgentCheckupPage extends StatelessWidget {
  const _AgentCheckupPage({
    required this.controller,
    required this.onNavigate,
    required this.onBack,
  });

  final AppController controller;
  final ValueChanged<ProfileRoute> onNavigate;
  final VoidCallback onBack;

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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: [
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.query_stats_rounded,
              value: '$score',
              label: '健康分',
              color: score >= 90 ? AppColors.primarySoft : AppColors.gold,
            ),
            _MetricBox(
              icon: Icons.shield_rounded,
              value: '$actionCount',
              label: '需处理',
              color: actionCount == 0 ? AppColors.primarySoft : AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MetricRow(
          children: [
            _MetricBox(
              icon: Icons.notifications_active_rounded,
              value: '$watchCount',
              label: '观察项',
              color: watchCount == 0 ? AppColors.surfaceWarm : AppColors.gold,
            ),
            _MetricBox(
              icon: Icons.timeline_rounded,
              value: '${controller.confirmedEvents.length}',
              label: '已沉淀',
              color: AppColors.primarySoft,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _DetailInfoCard(
          title: '体检结论',
          value: _buildCheckupConclusion(score, actionCount, watchCount),
          summary: '系统会汇总待确认、提醒覆盖、地点缺失和时间冲突等问题，并提供对应处理入口。',
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(
          title: '体检清单',
          summary: '点击条目进入对应处理页面，保持问题发现到处理的完整闭环。',
        ),
        const SizedBox(height: 6),
        WeavingCard(
          color: AppColors.surfaceLowest,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _CheckupItemRow(
                  item: items[i],
                  onTap: () => onNavigate(items[i].route),
                ),
                if (i < items.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _DetailSectionHeader(
          title: '快速补强',
          summary: '集中处理消息、偏好、安全和时间线记录。',
        ),
        const SizedBox(height: 6),
        _NavGrid(
          items: [
            _NavItemSpec(
              Icons.notifications_active_rounded,
              '处理消息',
              '${controller.inboxMessages.length} 条系统记录',
              () => onNavigate(ProfileRoute.notificationInbox),
              color: AppColors.coral,
            ),
            _NavItemSpec(
              Icons.tune_rounded,
              '调整偏好',
              '提醒与安全边界',
              () => onNavigate(ProfileRoute.preferences),
              color: AppColors.gold,
            ),
            _NavItemSpec(
              Icons.timeline_rounded,
              '回看资产',
              '${controller.confirmedEvents.length} 条时间线',
              () => onNavigate(ProfileRoute.timelineAssets),
              color: AppColors.primarySoft,
            ),
            _NavItemSpec(
              Icons.security_rounded,
              '安全策略',
              '人在回路与静默阈值',
              () => onNavigate(ProfileRoute.privacySecurity),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.psychology_rounded),
            label: const Text('返回功能中心'),
          ),
        ),
      ],
    );
  }
}

class _CheckupItemRow extends StatelessWidget {
  const _CheckupItemRow({required this.item, required this.onTap});

  final _CheckupItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.level.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 19, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InfoChip(
                          label: item.level.label,
                          backgroundColor: item.level.backgroundColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileEditGroup extends StatelessWidget {
  const _ProfileEditGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      color: AppColors.surfaceLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _AvatarSheetAction extends StatelessWidget {
  const _AvatarSheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      color: Colors.white.withValues(alpha: 0.5),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.maxLength,
    required this.onChanged,
    this.maxLines = 1,
    this.digitsOnly = false,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String placeholder;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final bool digitsOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: maxLines,
              inputFormatters: [
                if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(maxLength),
              ],
              decoration: InputDecoration(
                labelText: label,
                hintText: placeholder,
                counterText: '',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.2),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ProfileHeaderBubble(icon: icon, background: AppColors.primarySoft),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ReminderLeadDaysTile extends StatelessWidget {
  const _ReminderLeadDaysTile({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final leadDays = controller.preference.reminderLeadDays
        .clamp(1, 14)
        .toInt();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLeadDaysDialog(context, leadDays),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const _ProfileHeaderBubble(
                icon: Icons.calendar_month_rounded,
                background: AppColors.primarySoft,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '日级提前天数',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '重要事项开始前 $leadDays 天提醒',
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InfoChip(label: '$leadDays 天', backgroundColor: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLeadDaysDialog(
    BuildContext context,
    int initialDays,
  ) async {
    var selected = initialDays.toDouble();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedDays = selected.round();
            return AlertDialog(
              title: const Text('日级提前天数'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('当前：$selectedDays 天'),
                  Slider(
                    min: 1,
                    max: 14,
                    divisions: 13,
                    value: selected,
                    label: '$selectedDays 天',
                    onChanged: (value) {
                      setDialogState(() {
                        selected = value.roundToDouble();
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
                        reminderLeadDays: selectedDays,
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

class _ReminderLeadTile extends StatelessWidget {
  const _ReminderLeadTile({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final leadMinutes = controller.preference.reminderLeadMinutes
        .clamp(5, 180)
        .toInt();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLeadDialog(context, leadMinutes),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const _ProfileHeaderBubble(
                icon: Icons.tune_rounded,
                background: AppColors.primarySoft,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '提醒提前量',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '重要事项开始前 $leadMinutes 分钟提醒',
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
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
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: WeavingCard(
        color: color,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 25,
                height: 31 / 25,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSectionHeader extends StatelessWidget {
  const _DetailSectionHeader({required this.title, this.summary = ''});

  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            summary,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({
    required this.title,
    required this.value,
    required this.summary,
  });

  final String title;
  final String value;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 104),
      child: WeavingCard(
        color: AppColors.surfaceLowest,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRowGroup extends StatelessWidget {
  const _DetailRowGroup({required this.title, required this.items});

  final String title;
  final List<_NavItemSpec> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailSectionHeader(title: title),
        const SizedBox(height: 6),
        WeavingCard(
          color: AppColors.surfaceLowest,
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _DetailNavRow(item: items[index]),
                if (index < items.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailNavRow extends StatelessWidget {
  const _DetailNavRow({required this.item});

  final _NavItemSpec item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _ProfileHeaderBubble(
                  icon: item.icon,
                  background: AppColors.primarySoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavGrid extends StatelessWidget {
  const _NavGrid({required this.items});

  final List<_NavItemSpec> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  height: 124,
                  child: WeavingCard(
                    color: item.color ?? AppColors.surfaceLowest,
                    onTap: item.onTap,
                    interactionStyle: WeavingInteractionStyle.iconGlow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.48),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          item.summary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
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
    required this.icon,
    required this.title,
    required this.summary,
    required this.level,
    required this.route,
  });

  final IconData icon;
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
      Icons.check_circle_rounded,
      '一键体检',
      '校验待办、提醒、冲突和策略',
      () => onNavigate(ProfileRoute.agentCheckup),
      color: AppColors.gold,
    ),
    _NavItemSpec(
      Icons.timeline_rounded,
      '时间线资产',
      '回看已确认记录与提醒沉淀',
      () => onNavigate(ProfileRoute.timelineAssets),
      color: AppColors.primarySoft,
    ),
    _NavItemSpec(
      Icons.notifications_active_rounded,
      '通知中心',
      '回看待处理与系统消息',
      () => onNavigate(ProfileRoute.notificationInbox),
      color: AppColors.coral,
    ),
    _NavItemSpec(
      Icons.emoji_events_rounded,
      '使用概览',
      '记录、提醒与待确认事项',
      () => onNavigate(ProfileRoute.achievements),
      color: AppColors.gold,
    ),
    _NavItemSpec(
      Icons.shield_rounded,
      '隐私与安全',
      '人在回路与风险拦截',
      () => onNavigate(ProfileRoute.privacySecurity),
      color: AppColors.coral,
    ),
    _NavItemSpec(
      Icons.storage_rounded,
      '数据空间',
      '本地存储与缓存边界',
      () => onNavigate(ProfileRoute.dataSpace),
      color: AppColors.primarySoft,
    ),
    _NavItemSpec(
      Icons.speed_rounded,
      '运行状态',
      '智能解析、图文识别与提醒状态',
      () => onNavigate(ProfileRoute.runtimeStatus),
      color: AppColors.surfaceWarm,
    ),
  ];
}

List<_NavItemSpec> _agentCenterSystemItems(
  ValueChanged<ProfileRoute> onNavigate,
) {
  return [
    _NavItemSpec(
      Icons.download_rounded,
      '导出记录',
      '导出和备份时间线记录',
      () => onNavigate(ProfileRoute.exportRecords),
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
  required String school,
  required String major,
  required String grade,
  required String fallback,
}) {
  final parts = [
    school,
    major,
    grade,
  ].map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  return parts.isEmpty ? fallback : parts.join(' · ');
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
  return parts.isEmpty ? '请完善学校、专业和年级资料' : parts.join(' · ');
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
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
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
                const SizedBox(height: 2),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
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
  final missingLocationCount = confirmedItems.where((item) {
    final location = (item.location ?? '').trim();
    return location.isEmpty ||
        location.contains('待') ||
        location.contains('未知');
  }).length;
  final reminderCoverageLow =
      confirmedItems.isNotEmpty &&
      controller.scheduledReminderCount < confirmedItems.length;
  final sortedTimes =
      confirmedItems.where((item) => item.startTime != null).toList()
        ..sort((left, right) => left.startTime!.compareTo(right.startTime!));
  var conflictCount = 0;
  for (var i = 0; i < sortedTimes.length - 1; i++) {
    final minutes = sortedTimes[i].startTime!
        .difference(sortedTimes[i + 1].startTime!)
        .inMinutes
        .abs();
    if (minutes <= 90) conflictCount++;
  }
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
      icon: Icons.shield_rounded,
      title: '待确认池',
      summary: controller.pendingNotices.isEmpty
          ? '当前没有待校验日程，人在回路链路保持干净。'
          : '还有 ${controller.pendingNotices.length} 条事项等待复核，建议先处理后再继续使用。',
      level: controller.pendingNotices.isEmpty
          ? _CheckupLevel.ready
          : _CheckupLevel.action,
      route: ProfileRoute.notificationInbox,
    ),
    _CheckupItem(
      icon: Icons.calendar_month_rounded,
      title: '时间字段',
      summary: missingTimeCount == 0
          ? '已沉淀事项均有可解析时间，时间线排序稳定。'
          : '$missingTimeCount 条记录缺少精确时间，可能影响提醒和日历展示。',
      level: missingTimeCount == 0 ? _CheckupLevel.ready : _CheckupLevel.action,
      route: ProfileRoute.history,
    ),
    _CheckupItem(
      icon: Icons.location_on_rounded,
      title: '地点字段',
      summary: missingLocationCount == 0 && controller.preference.autoMapLink
          ? '地点线索完整，地图联动已开启。'
          : !controller.preference.autoMapLink
          ? '地图联动未开启，地点识别不会自动生成导航兜底。'
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
      icon: Icons.notifications_active_rounded,
      title: '提醒覆盖',
      summary: reminderCoverageLow
          ? '已确认事项多于提醒数，建议检查默认提醒策略。'
          : '提醒托管状态正常，关键时间点已有系统守护。',
      level: reminderCoverageLow ? _CheckupLevel.watch : _CheckupLevel.ready,
      route: ProfileRoute.reminderCenter,
    ),
    _CheckupItem(
      icon: Icons.security_rounded,
      title: '安全边界',
      summary: controller.preference.blockHighRisk
          ? controller.preference.muteLowConfidence
                ? '高风险拦截与低置信度静默均已开启，当前策略较稳妥，适合日常使用。'
                : '高风险拦截已开启，低置信度静默可按使用习惯开启。'
          : '高风险拦截未开启，建议开启人在回路确认。',
      level: controller.preference.blockHighRisk
          ? controller.preference.muteLowConfidence
                ? _CheckupLevel.ready
                : _CheckupLevel.watch
          : _CheckupLevel.action,
      route: ProfileRoute.privacySecurity,
    ),
    _CheckupItem(
      icon: Icons.timeline_rounded,
      title: '时间冲突',
      summary: conflictCount == 0
          ? '未发现 90 分钟内的密集冲突，时间线节奏清晰。'
          : '发现 $conflictCount 组相近安排，建议进入时间线资产复核。',
      level: conflictCount == 0 ? _CheckupLevel.ready : _CheckupLevel.watch,
      route: ProfileRoute.timelineAssets,
    ),
    _CheckupItem(
      icon: Icons.notifications_active_rounded,
      title: '消息收纳',
      summary: pendingInboxCount == 0
          ? '通知中心没有未处理消息，系统状态清爽。'
          : '通知中心还有 $pendingInboxCount 条待处理记录，可集中清理。',
      level: pendingInboxCount == 0 ? _CheckupLevel.ready : _CheckupLevel.watch,
      route: ProfileRoute.notificationInbox,
    ),
    _CheckupItem(
      icon: Icons.storage_rounded,
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
  return score.clamp(0, 100);
}

String _buildCheckupConclusion(int score, int actionCount, int watchCount) {
  if (score >= 92) return '状态良好';
  if (actionCount > 0) return '先处理 $actionCount 项';
  if (watchCount > 0) return '建议微调 $watchCount 项';
  return '状态稳定';
}

String _endpointTail(String endpoint) {
  final normalized = endpoint.trim().replaceFirst(RegExp(r'^https?://'), '');
  if (normalized.isEmpty) return '未配置';
  return normalized.length <= 36
      ? normalized
      : normalized.substring(normalized.length - 36);
}

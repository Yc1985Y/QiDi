import 'package:flutter/material.dart';

import '../app.dart';
import '../widgets/weaving_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nickname;
  late final TextEditingController _school;
  late final TextEditingController _major;
  late final TextEditingController _grade;

  @override
  void initState() {
    super.initState();
    final preference = widget.controller.preference;
    _nickname = TextEditingController(text: preference.nickname);
    _school = TextEditingController(text: preference.school);
    _major = TextEditingController(text: preference.major);
    _grade = TextEditingController(text: preference.grade);
  }

  @override
  void dispose() {
    _nickname.dispose();
    _school.dispose();
    _major.dispose();
    _grade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final preference = controller.preference;
    return WeavingBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Text('我的', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          WeavingCard(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.coral,
                      child: Text(
                        preference.nickname.trim().isEmpty
                            ? '织'
                            : preference.nickname.trim().characters.first,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preference.nickname,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            [
                                  preference.school,
                                  preference.major,
                                  preference.grade,
                                ]
                                .where((item) => item.trim().isNotEmpty)
                                .join(' · '),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    MetricTile(
                      value: '${controller.confirmedEvents.length}',
                      label: '已确认',
                      color: AppColors.primarySoft,
                    ),
                    const SizedBox(width: 10),
                    MetricTile(
                      value: '${controller.pendingNotices.length}',
                      label: '待确认',
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 10),
                    MetricTile(
                      value: '${controller.scheduledReminderCount}',
                      label: '提醒',
                      color: AppColors.coral,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ProfileForm(
            nickname: _nickname,
            school: _school,
            major: _major,
            grade: _grade,
            onSave: () {
              controller.savePreference(
                preference.copyWith(
                  nickname: _nickname.text.trim().isEmpty
                      ? '织时用户'
                      : _nickname.text.trim(),
                  school: _school.text.trim(),
                  major: _major.text.trim(),
                  grade: _grade.text.trim(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _PreferenceBoard(controller: controller),
        ],
      ),
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.nickname,
    required this.school,
    required this.major,
    required this.grade,
    required this.onSave,
  });

  final TextEditingController nickname;
  final TextEditingController school;
  final TextEditingController major;
  final TextEditingController grade;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('个人资料', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _TextField(label: '昵称', controller: nickname),
          _TextField(label: '学校', controller: school),
          _TextField(label: '专业', controller: major),
          _TextField(label: '年级', controller: grade),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('保存资料'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceBoard extends StatelessWidget {
  const _PreferenceBoard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final preference = controller.preference;
    return WeavingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('提醒与偏好', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            value: preference.dayReminderEnabled,
            title: const Text('提前1天提醒'),
            onChanged: (value) => controller.savePreference(
              preference.copyWith(dayReminderEnabled: value),
            ),
          ),
          SwitchListTile(
            value: preference.hourReminderEnabled,
            title: const Text('短时提醒'),
            onChanged: (value) => controller.savePreference(
              preference.copyWith(hourReminderEnabled: value),
            ),
          ),
          ListTile(
            title: Text('短时提醒：${preference.reminderLeadMinutes} 分钟'),
            subtitle: Slider(
              value: preference.reminderLeadMinutes.toDouble(),
              min: 15,
              max: 120,
              divisions: 7,
              label: '${preference.reminderLeadMinutes}分钟',
              onChanged: (value) => controller.savePreference(
                preference.copyWith(reminderLeadMinutes: value.round()),
              ),
            ),
          ),
          SwitchListTile(
            value: preference.blockHighRisk,
            title: const Text('拦截高风险动作'),
            onChanged: (value) => controller.savePreference(
              preference.copyWith(blockHighRisk: value),
            ),
          ),
          SwitchListTile(
            value: preference.muteLowConfidence,
            title: const Text('静默低置信度结果'),
            onChanged: (value) => controller.savePreference(
              preference.copyWith(muteLowConfidence: value),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.isBusy
                  ? null
                  : controller.rescheduleReminders,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('重新排程提醒'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

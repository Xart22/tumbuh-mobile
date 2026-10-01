import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/health_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Small online/offline pill driven by periodic backend health checks.
/// Falls back to a static "Local" label when no [HealthService] is provided.
class ConnectionBadge extends StatefulWidget {
  const ConnectionBadge({super.key});

  @override
  State<ConnectionBadge> createState() => _ConnectionBadgeState();
}

class _ConnectionBadgeState extends State<ConnectionBadge> {
  HealthService? _health;
  Timer? _timer;
  bool? _online;

  @override
  void initState() {
    super.initState();
    try {
      _health = context.read<HealthService>();
    } catch (_) {
      _health = null;
    }
    if (_health != null) {
      _check();
      _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final online = await _health!.check();
    if (!mounted) return;
    setState(() => _online = online);
  }

  @override
  Widget build(BuildContext context) {
    final online = _online;
    final color = online == null
        ? LpColors.textSecondary
        : (online ? LpColors.primaryLight : LpColors.critical);
    final label = online == null ? 'Local' : (online ? 'Online' : 'Offline');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111923),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: LpTypography.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

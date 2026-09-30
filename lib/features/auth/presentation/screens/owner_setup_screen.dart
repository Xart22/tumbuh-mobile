import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/outlet_summary.dart';
import '../../../../routing/app_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../bloc/auth_bloc.dart';

/// First-run tablet provisioning: owner logs in, picks the outlet this till
/// belongs to, then the cashier PIN screen can authenticate against it.
class OwnerSetupScreen extends StatefulWidget {
  const OwnerSetupScreen({super.key});

  @override
  State<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends State<OwnerSetupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _workspace = TextEditingController();
  String? _error;
  List<OutletSummary> _outlets = const [];
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _workspace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() {
          _loading = state is AuthLoading;
          if (state is AuthOwnerOutletsLoaded) {
            _outlets = state.outlets;
            _error = null;
          } else if (state is AuthFailure) {
            _error = state.message;
          } else if (state is AuthOutletConfigured) {
            context.go(AppRouter.loginKasir);
          }
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1116),
        appBar: AppBar(
          backgroundColor: const Color(0xFF171B22),
          title: const Text('Setup Outlet'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRouter.loginKasir),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Login Owner', style: LpTypography.headlineMd.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    'Sekali saja per tablet, untuk mengikat perangkat ke outlet.',
                    style: LpTypography.bodySm.copyWith(color: LpColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  _field(_email, 'Email Owner', keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field(_password, 'Password', obscure: true),
                  const SizedBox(height: 12),
                  _field(_workspace, 'Workspace (opsional, slug)'),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: LpTypography.bodySm.copyWith(color: LpColors.critical)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Masuk Owner'),
                  ),
                  if (_outlets.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Pilih Outlet', style: LpTypography.headlineSm.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    ..._outlets.map(
                      (o) => Card(
                        color: const Color(0xFF171B22),
                        child: ListTile(
                          title: Text(o.name, style: const TextStyle(color: Colors.white)),
                          subtitle: o.city != null
                              ? Text(o.city!, style: const TextStyle(color: LpColors.textSecondary))
                              : null,
                          trailing: const Icon(Icons.chevron_right, color: LpColors.textSecondary),
                          onTap: () => context
                              .read<AuthBloc>()
                              .add(AuthSelectOutletRequested(o.id)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: LpColors.textSecondary),
        filled: true,
        fillColor: const Color(0xFF171B22),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _login() {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi.');
      return;
    }
    context.read<AuthBloc>().add(
          AuthOwnerLoginRequested(
            email: _email.text.trim(),
            password: _password.text,
            tenantSlug: _workspace.text.trim().isEmpty ? null : _workspace.text.trim(),
          ),
        );
  }
}

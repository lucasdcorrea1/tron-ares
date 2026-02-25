import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../bloc/tron_project_bloc.dart';

class TronOnboardingPage extends StatefulWidget {
  const TronOnboardingPage({super.key});

  @override
  State<TronOnboardingPage> createState() => _TronOnboardingPageState();
}

class _TronOnboardingPageState extends State<TronOnboardingPage> {
  final _pageController = PageController();
  int _currentStep = 0;

  final _projectNameController = TextEditingController();
  final _projectDescController = TextEditingController();
  final _repoUrlController = TextEditingController();
  String _repoOption = 'import';

  @override
  void dispose() {
    _pageController.dispose();
    _projectNameController.dispose();
    _projectDescController.dispose();
    _repoUrlController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TronProjectBloc, TronProjectState>(
      listener: (context, state) {
        if (state.successMessage != null && _currentStep == 1) {
          _nextStep();
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: SafeArea(
          child: Column(
            children: [
              _buildProgressBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWelcomePage(),
                    _buildCreateProjectPage(),
                    _buildRepoPage(),
                    _buildAnalyzingPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              icon: Icon(Icons.arrow_back_rounded,
                  color: AppColors.textSecondary),
              onPressed: _prevStep,
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          ...List.generate(4, (i) {
            return Container(
              width: i == _currentStep ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i <= _currentStep
                    ? AppColors.primary
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            );
          }),
          const Spacer(),
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text('Pular',
                style: AppTypography.bodySmall(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded,
                size: 48, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Bem-vindo ao TRON',
              style: AppTypography.headlineMedium(),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sua equipe de agentes IA para desenvolvimento.\n'
            'PM planeja, Dev codifica, QA testa.\nVoce e o CIO.',
            style: AppTypography.bodyLarge(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeightLg,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              child: Text('Comecar', style: AppTypography.button()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateProjectPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Crie seu projeto', style: AppTypography.headlineSmall()),
          const SizedBox(height: AppSpacing.sm),
          Text('Um projeto agrupa seus repositorios e agentes.',
              style:
                  AppTypography.bodyMedium(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xl),
          Text('Nome do projeto', style: AppTypography.labelLarge()),
          const SizedBox(height: AppSpacing.sm),
          _buildTextField(_projectNameController, 'Ex: Meu App Mobile'),
          const SizedBox(height: AppSpacing.lg),
          Text('Descricao', style: AppTypography.labelLarge()),
          const SizedBox(height: AppSpacing.sm),
          _buildTextField(_projectDescController, 'Descreva seu projeto...',
              maxLines: 3),
          const Spacer(),
          BlocBuilder<TronProjectBloc, TronProjectState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeightLg,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          if (_projectNameController.text.trim().isEmpty) {
                            return;
                          }
                          context.read<TronProjectBloc>().add(
                                CreateProjectEvent(
                                  name:
                                      _projectNameController.text.trim(),
                                  description:
                                      _projectDescController.text.trim(),
                                ),
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Criar Projeto',
                          style: AppTypography.button()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRepoPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Adicionar repositorio',
              style: AppTypography.headlineSmall()),
          const SizedBox(height: AppSpacing.sm),
          Text('Importe um repo existente ou crie um novo.',
              style:
                  AppTypography.bodyMedium(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _buildOptionChip('Importar', 'import'),
              const SizedBox(width: AppSpacing.sm),
              _buildOptionChip('Criar novo', 'create'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_repoOption == 'import') ...[
            Text('URL do repositorio', style: AppTypography.labelLarge()),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(
              _repoUrlController,
              'https://github.com/user/repo',
              prefixIcon: Icons.link_rounded,
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Icon(Icons.create_new_folder_rounded,
                      size: 48, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Um novo repositorio sera criado para o projeto',
                    style: AppTypography.bodyMedium(
                        color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/tron/dashboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.divider),
                    minimumSize:
                        const Size(0, AppSpacing.buttonHeightLg),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  child: const Text('Depois'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    final bloc = context.read<TronProjectBloc>();
                    final projectId =
                        bloc.state.selectedProject?.id ?? '';
                    if (_repoOption == 'import' &&
                        _repoUrlController.text.trim().isNotEmpty) {
                      bloc.add(ImportRepoEvent(
                        projectId: projectId,
                        repoUrl: _repoUrlController.text.trim(),
                      ));
                    }
                    _nextStep();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize:
                        const Size(0, AppSpacing.buttonHeightLg),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                  child: Text('Continuar',
                      style: AppTypography.button()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingPage() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Analisando repositorio...',
              style: AppTypography.headlineSmall(),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Os agentes estao mapeando a estrutura,\n'
            'identificando padroes e criando tarefas.',
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildAnalysisStep(
              Icons.folder_open_rounded, 'Mapeando arquivos', true),
          _buildAnalysisStep(
              Icons.code_rounded, 'Analisando codigo', true),
          _buildAnalysisStep(
              Icons.bug_report_rounded, 'Identificando issues', false),
          _buildAnalysisStep(
              Icons.task_alt_rounded, 'Criando tarefas', false),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeightLg,
            child: ElevatedButton(
              onPressed: () => context.go('/tron/dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              child: Text('Ir para Dashboard',
                  style: AppTypography.button()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1, IconData? prefixIcon}) {
    return TextField(
      controller: controller,
      style: AppTypography.bodyLarge(),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.cardDark,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textMuted)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildOptionChip(String label, String value) {
    final isSelected = _repoOption == value;
    return GestureDetector(
      onTap: () => setState(() => _repoOption = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge(
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildAnalysisStep(IconData icon, String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: done ? AppColors.income : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label,
              style: AppTypography.bodyMedium(
                  color: done
                      ? AppColors.textPrimary
                      : AppColors.textMuted)),
        ],
      ),
    );
  }
}

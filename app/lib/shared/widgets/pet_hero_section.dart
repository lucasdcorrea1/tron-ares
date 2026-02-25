import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Cores FIXAS do Pet Card
class _PetColors {
  static const Color background = Color(0xFF5A4875);
}

/// Hero section with pet
class PetHeroSection extends StatefulWidget {
  final PetStats stats;
  final VoidCallback? onTap;
  final VoidCallback? onPetTap;

  const PetHeroSection({
    super.key,
    required this.stats,
    this.onTap,
    this.onPetTap,
  });

  @override
  State<PetHeroSection> createState() => _PetHeroSectionState();
}

class _PetHeroSectionState extends State<PetHeroSection> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() async {
    _videoController = VideoPlayerController.asset('assets/videos/pato-01.mp4');
    try {
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.setVolume(0);
      await _videoController.play();
      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _PetColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Header
          _buildHeader(),

          const SizedBox(height: 8),

          // Pet + Stats
          _buildContent(),

          const SizedBox(height: 12),

          // Progress
          _buildProgress(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Saldo principal
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.stats.totalCoins.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'COINS',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Saldo secundário
        Text(
          'R\$ ${widget.stats.realBalance.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pet no centro/fundo
          Positioned(
            bottom: 20,
            child: GestureDetector(
              onTap: widget.onPetTap,
              child: _buildPetVideo(),
            ),
          ),

          // Stats nas laterais
          Positioned.fill(
            child: Row(
              children: [
                // Coluna esquerda
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat(Icons.touch_app, '+${widget.stats.earningsPerTap}', 'Toque'),
                        _buildStat(Icons.emoji_events, widget.stats.currentLeague, 'Liga'),
                        _buildStat(Icons.trending_up, '+${widget.stats.profitPerHour}/h', 'Lucro'),
                      ],
                    ),
                  ),
                ),

                // Espaço do pet
                const SizedBox(width: 160),

                // Coluna direita
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat(Icons.local_fire_department, '${widget.stats.streakDays}d', 'Streak'),
                        _buildStat(Icons.bolt, '${widget.stats.energyPercent}%', 'Energia'),
                        _buildStat(Icons.pets, 'Lv.${widget.stats.petLevel}', 'Pet'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetVideo() {
    const double size = 200;

    if (!_isVideoInitialized) {
      return Container(
        width: size,
        height: size,
        color: _PetColors.background,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white54,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: size * 1.3,
          maxHeight: size,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController.value.size.width,
              height: _videoController.value.size.height,
              child: VideoPlayer(_videoController),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final progress = widget.stats.energy / widget.stats.maxEnergy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.white60, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.stats.energy}/${widget.stats.maxEnergy}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              Text(
                widget.stats.currentLeague.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats data model
class PetStats {
  final double totalCoins;
  final double realBalance;
  final double savingsBalance;
  final int earningsPerTap;
  final String currentLeague;
  final int profitPerHour;
  final int streakDays;
  final int energyPercent;
  final int petLevel;
  final int energy;
  final int maxEnergy;
  final double experience;

  const PetStats({
    this.totalCoins = 0,
    this.realBalance = 0,
    this.savingsBalance = 0,
    this.earningsPerTap = 1,
    this.currentLeague = 'Bronze',
    this.profitPerHour = 0,
    this.streakDays = 0,
    this.energyPercent = 100,
    this.petLevel = 1,
    this.energy = 500,
    this.maxEnergy = 500,
    this.experience = 0,
  });

  PetStats copyWith({
    double? totalCoins,
    double? realBalance,
    double? savingsBalance,
    int? earningsPerTap,
    String? currentLeague,
    int? profitPerHour,
    int? streakDays,
    int? energyPercent,
    int? petLevel,
    int? energy,
    int? maxEnergy,
    double? experience,
  }) {
    return PetStats(
      totalCoins: totalCoins ?? this.totalCoins,
      realBalance: realBalance ?? this.realBalance,
      savingsBalance: savingsBalance ?? this.savingsBalance,
      earningsPerTap: earningsPerTap ?? this.earningsPerTap,
      currentLeague: currentLeague ?? this.currentLeague,
      profitPerHour: profitPerHour ?? this.profitPerHour,
      streakDays: streakDays ?? this.streakDays,
      energyPercent: energyPercent ?? this.energyPercent,
      petLevel: petLevel ?? this.petLevel,
      energy: energy ?? this.energy,
      maxEnergy: maxEnergy ?? this.maxEnergy,
      experience: experience ?? this.experience,
    );
  }
}

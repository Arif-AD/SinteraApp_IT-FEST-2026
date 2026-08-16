import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';

class ImpactSummaryCard extends ConsumerStatefulWidget {
  const ImpactSummaryCard({
    super.key,
    required this.organicKg,
    required this.inorganicKg,
    required this.co2e,
    required this.trees,
    required this.organicRatio,
    this.isPetani = false,
  });

  final int organicKg;
  final int inorganicKg;
  final int co2e;
  final int trees;
  final double organicRatio;
  final bool isPetani;

  @override
  ConsumerState<ImpactSummaryCard> createState() => _ImpactSummaryCardState();
}

class _ImpactSummaryCardState extends ConsumerState<ImpactSummaryCard> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final List<Animation<double>> _scaleAnimations;
  
  // State untuk nilai filter dropdown, default ke 'Semua'
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: false);

    _scaleAnimations = List.generate(4, (index) {
      final double start = index * 0.2;
      final double end = (start + 0.5).clamp(0.0, 1.0);
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.08).chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(start, end, curve: Curves.linear),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showStatInfoDialog(
    BuildContext context, {
    required String title,
    required String description,
    required String imageName,
    required Color activeColor,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: Colors.white,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 340.w),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 36.w,
                      height: 36.w,
                      child: Image.asset('assets/images/icon/icon_$imageName.png', fit: BoxFit.contain),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                      ),
                      child: Text(
                        'Mengerti',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isPetani ? const Color(0xFF1B3B6F) : AppColors.primary;

    final bool isOrganicZero = widget.organicKg == 0;
    final bool isInorganicZero = widget.inorganicKg == 0;
    final bool isCo2Zero = widget.co2e == 0;
    final bool isTreeZero = widget.trees == 0;

    final String organicDesc = isOrganicZero
        ? 'Kamu belum pernah setor limbah organik nih. Yuk, mulai kumpulkan sisa dapur atau daun dan setor sekarang untuk bantu bumi!'
        : 'Yay, kamu hebat! Total limbah organik yang berhasil kamu setor sudah mencapai ${widget.organicKg} kg. Kontribusi ini sangat berarti untuk mengurangi tumpukan sampah secara alami.';

    final String inorganicDesc = isInorganicZero
        ? 'Belum ada limbah anorganik yang disetor. Yuk, kumpulkan botol atau plastik bekasmu dan mulai langkah kecil hari ini!'
        : 'Keren banget! Kamu telah berhasil menyetor ${widget.inorganicKg} kg limbah anorganik. Langkah kecilmu ini mencegah pencemaran lingkungan dalam jangka panjang.';

    final String co2Desc = isCo2Zero
        ? 'Belum ada emisi CO₂e yang dicegah dalam rentang waktu ini. Yuk, mulai setor sampah rutinmu agar angka pengurangan karbonnya makin meningkat!'
        : 'Luar biasa! Total emisi karbon sebesar ${widget.co2e} kg CO₂e berhasil kamu pangkas dan cegah dari lingkungan. Ini adalah bukti nyata kepedulianmu pada bumi.';

    final String treeDesc = isTreeZero
        ? 'Belum ada pohon aktif nih. Yuk, tingkatkan setoran sampahmu untuk capai setara 1 pohon pertama!'
        : 'Yay, kontribusi hebatmu dalam menyetor limbah setara dengan kinerja ${widget.trees} pohon loh! Kamu pahlawan lingkungan yang sesungguhnya.';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: SectionHeader(title: 'Ringkasan Dampak', actionLabel: ''),
            ),
            // PopupMenuButton untuk fungsionalitas pilihan filter (Semua, Minggu, Bulan, Tahun)
            PopupMenuButton<String>(
              initialValue: _selectedFilter,
              onSelected: (String newValue) {
                setState(() {
                  _selectedFilter = newValue;
                });
                // Anda bisa menambahkan logika fetch / filter data di sini berdasarkan `newValue`
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Semua',
                  child: Text('Semua'),
                ),
                const PopupMenuItem<String>(
                  value: 'Minggu',
                  child: Text('Minggu'),
                ),
                const PopupMenuItem<String>(
                  value: 'Bulan',
                  child: Text('Bulan'),
                ),
                const PopupMenuItem<String>(
                  value: 'Tahun',
                  child: Text('Tahun'),
                ),
              ],
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedFilter,
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    SizedBox(width: 4.w),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        
        CustomCard(
          padding: EdgeInsets.all(12.w),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
          child: _ComparisonBar(organicRatio: widget.organicRatio, isPetani: widget.isPetani),
        ),
        
        SizedBox(height: AppSpacing.md.h),
        
        Row(
          children: [
            Expanded(
              child: ScaleTransition(
                scale: _scaleAnimations[0],
                child: _StatCard(
                  imageName: 'organik',
                  value: '${widget.organicKg} kg',
                  label: 'Limbah Organik',
                  valueOnTop: true,
                  activeColor: activeColor,
                  onTap: () => _showStatInfoDialog(
                    context,
                    title: 'Limbah Organik',
                    description: organicDesc,
                    imageName: 'organik',
                    activeColor: activeColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: ScaleTransition(
                scale: _scaleAnimations[1],
                child: _StatCard(
                  imageName: 'anorganik',
                  value: '${widget.inorganicKg} kg',
                  label: 'Limbah Anorganik',
                  valueOnTop: true,
                  activeColor: activeColor,
                  onTap: () => _showStatInfoDialog(
                    context,
                    title: 'Limbah Anorganik',
                    description: inorganicDesc,
                    imageName: 'anorganik',
                    activeColor: activeColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md.h),
        Row(
          children: [
            Expanded(
              child: ScaleTransition(
                scale: _scaleAnimations[2],
                child: _StatCard(
                  imageName: 'co2',
                  value: '${widget.co2e} kg',
                  label: 'CO₂e\nHilang',
                  valueOnTop: false,
                  activeColor: activeColor,
                  onTap: () => _showStatInfoDialog(
                    context,
                    title: 'CO₂e Hilang',
                    description: co2Desc,
                    imageName: 'co2',
                    activeColor: activeColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: ScaleTransition(
                scale: _scaleAnimations[3],
                child: _StatCard(
                  imageName: 'pohon',
                  value: '${widget.trees} pohon',
                  label: 'Setara Kinerja',
                  valueOnTop: false,
                  activeColor: activeColor,
                  onTap: () => _showStatInfoDialog(
                    context,
                    title: 'Setara Kinerja',
                    description: treeDesc,
                    imageName: 'pohon',
                    activeColor: activeColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.imageName, 
    required this.value, 
    required this.label, 
    required this.valueOnTop,
    required this.activeColor,
    required this.onTap,
  });

  final String imageName;
  final String value;
  final String label;
  final bool valueOnTop;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: CustomCard(
        padding: EdgeInsets.all(AppSpacing.md.w),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.0.r),
              ),
              child: SizedBox(
                width: 32.w,
                height: 32.w,
                child: Image.asset('assets/images/icon/icon_$imageName.png'),
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: valueOnTop 
                  ? [
                      Text(
                        value, 
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                      Text(
                        label, 
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ]
                  : [
                      Text(
                        label,
                        maxLines: 2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary, 
                          height: 1.15,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        value, 
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({required this.organicRatio, required this.isPetani});

  final double organicRatio;
  final bool isPetani;

  @override
  Widget build(BuildContext context) {
    final organic = (organicRatio * 100).round();
    final inorganic = (100 - organic).round();
    final primaryColor = isPetani ? const Color(0xFF1B3B6F) : AppColors.primary;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            height: 10.h,
            child: Row(
              children: [
                Expanded(flex: organic, child: Container(color: primaryColor)),
                Expanded(flex: inorganic, child: Container(color: const Color(0xFF007BC4))),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        Row(
          children: [
            _LegendDot(color: primaryColor, label: 'Organik $organic%'),
            const Spacer(),
            _LegendDot(color: const Color(0xFF007BC4), label: 'Anorganik $inorganic%'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        ),
        SizedBox(width: AppSpacing.xs.w),
        Text(
          label, 
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}
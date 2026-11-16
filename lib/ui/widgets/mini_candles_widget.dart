import 'package:flutter/cupertino.dart';
import '../../models/token_data.dart';

class MiniCandlesRow extends StatelessWidget {
  final Map<String, PeriodMetric> metrics;
  final bool showVolume;

  const MiniCandlesRow({
    super.key,
    required this.metrics,
    this.showVolume = true,
  });

  @override
  Widget build(BuildContext context) {
    const periods = ['1J', '7J', '30J', '90J', '180J'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: periods.map((p) {
        final metric = metrics[p] ??
            const PeriodMetric(priceChangePct: 0, volumeChangePct: 0);
        final val =
            showVolume ? metric.volumeChangePct : metric.priceChangePct;
        final isPositive = val >= 0;
        final color = isPositive
            ? const Color(0xFF30D158)
            : const Color(0xFFFF453A);

        final bodyHeight = (val.abs() * 0.35).clamp(6.0, 26.0);

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E).withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.25),
                width: 0.7,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 1.2, height: 3, color: color),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        width: 9,
                        height: bodyHeight,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2.5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.35),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1.2, height: 3, color: color),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isPositive ? "+" : ""}${val.toStringAsFixed(1)}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';

class CustomCircularProgress extends StatelessWidget {
  final double progress;

  const CustomCircularProgress({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<double> valueNotifier =
        ValueNotifier<double>(progress.toDouble());
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width * 0.3, // Adjusted size
                maxHeight: MediaQuery.of(context).size.width * 0.3,
              ),
              child: DashedCircularProgressBar.aspectRatio(
                aspectRatio: 1,
                valueNotifier: valueNotifier,
                progress: progress,
                maxProgress: 100,
                corners: StrokeCap.round,
                foregroundColor: const Color(0xFF000000),
                backgroundColor: const Color(0xffeeeeee),
                foregroundStrokeWidth: 8,
                backgroundStrokeWidth: 8,
                animation: true,
                child: Center(
                  child: ValueListenableBuilder<double>(
                    valueListenable: valueNotifier,
                    builder: (_, value, __) => Text(
                      '${value.toInt()}%',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.01,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AdminStatisticsShimmer extends StatelessWidget {
  const AdminStatisticsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              SizedBox(height: 20),
              /// Stat Box Grid
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) => Expanded(child: _buildShimmerBox(context))),
                ),
              SizedBox(height: MediaQuery.of(context).size.height / 30),
              /// Top Users Container
              _buildTopUsersContainerShimmer(context),
              SizedBox(height: MediaQuery.of(context).size.height / 30),
              // Usage Stats Box
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: MediaQuery.of(context).size.height / 5.5,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
                ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBox(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.15,
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildTopUsersContainerShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
      child: Container(
        height: MediaQuery.of(context).size.height / 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/app_theme.dart';

class UserCard extends StatelessWidget {
  final UserProfile user;
  const UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      width: MediaQuery.of(context).size.width * 0.92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2031) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 25,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 55,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image(
                image: user.photos.first.startsWith('assets') 
                    ? AssetImage(user.photos.first) as ImageProvider 
                    : NetworkImage(user.photos.first),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Expanded(
            flex: 45,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${user.fullName}, ${user.age}', 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900), 
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: AppColors.electricBlue, size: 22),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.university, 
                    style: const TextStyle(color: AppColors.electricBlue, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        user.bio,
                        style: TextStyle(
                          fontSize: 15, 
                          color: isDark ? Colors.white70 : AppColors.graphite, 
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: user.interests.map((it) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue.withValues(alpha: 0.08), 
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          it, 
                          style: const TextStyle(color: AppColors.electricBlue, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
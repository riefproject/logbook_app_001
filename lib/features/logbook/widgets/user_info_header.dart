import 'package:flutter/material.dart';

class UserInfoHeader extends StatelessWidget {
  const UserInfoHeader({super.key, required this.role, required this.teamId});
  final String role;
  final String teamId;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Role: $role • Team: $teamId',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blueGrey,
            ),
      ),
    );
  }
}

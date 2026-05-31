import 'package:flutter/material.dart';
import 'package:haramain_pro/features/group/models/group_model.dart';
import 'package:haramain_pro/features/group/services/group_service.dart';
import 'screens/group_detail_screen.dart';
import 'screens/join_group_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/my_groups_screen.dart';
import 'screens/broadcast_screen.dart';

/// Route names for group feature
class GroupRoutes {
  static const String create = '/group/create';
  static const String join = '/group/join';
  static const String detail = '/group/detail';
  static const String myGroups = '/group/my-groups';
  static const String broadcast = '/group/broadcast';
  static const String qr = '/group/qr';

  /// Get all group routes
  static Map<String, WidgetBuilder> get routes => {
        create: (context) => _getCreateGroupScreen(context),
        join: (context) => _getJoinGroupScreen(context),
        myGroups: (context) => _getMyGroupsScreen(context),
      };

  /// Generate route for group detail
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

    // /group/:id
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'group') {
      final groupId = uri.pathSegments[1];
      final args = settings.arguments as Map<String, dynamic>?;

      if (groupId == 'create') {
        return MaterialPageRoute(
          builder: (context) => CreateGroupScreen(
            muthawifId: args?['muthawifId'] ?? '',
            muthawifName: args?['muthawifName'] ?? '',
          ),
        );
      }

      if (groupId == 'join') {
        return MaterialPageRoute(
          builder: (context) => JoinGroupScreen(
            userId: args?['userId'] ?? '',
            userName: args?['userName'] ?? '',
          ),
        );
      }

      if (groupId == 'my-groups') {
        return MaterialPageRoute(
          builder: (context) => MyGroupsScreen(
            userId: args?['userId'] ?? '',
            userName: args?['userName'] ?? '',
          ),
        );
      }

      // /group/:id (detail)
      return MaterialPageRoute(
        builder: (context) => _buildGroupDetailFromId(groupId, args),
      );
    }

    // /group/:id/broadcast
    if (uri.pathSegments.length == 3 &&
        uri.pathSegments[0] == 'group' &&
        uri.pathSegments[2] == 'broadcast') {
      final groupId = uri.pathSegments[1];
      final args = settings.arguments as Map<String, dynamic>?;

      return MaterialPageRoute(
        builder: (context) => _buildBroadcastScreen(groupId, args),
      );
    }

    return null;
  }

  static Widget _getCreateGroupScreen(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return CreateGroupScreen(
      muthawifId: args?['muthawifId'] ?? '',
      muthawifName: args?['muthawifName'] ?? '',
    );
  }

  static Widget _getJoinGroupScreen(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return JoinGroupScreen(
      userId: args?['userId'] ?? '',
      userName: args?['userName'] ?? '',
    );
  }

  static Widget _getMyGroupsScreen(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return MyGroupsScreen(
      userId: args?['userId'] ?? '',
      userName: args?['userName'] ?? '',
    );
  }

  static Widget _buildGroupDetailFromId(String groupId, Map<String, dynamic>? args) {
    // This would normally fetch the group from the service
    // For now, return a placeholder that loads the group
    return FutureBuilder<GroupModel?>(
      future: GroupService.instance.getGroup(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Not Found')),
            body: const Center(child: Text('Group not found')),
          );
        }

        return GroupDetailScreen(
          group: snapshot.data!,
          currentUserId: args?['currentUserId'] ?? '',
        );
      },
    );
  }

  static Widget _buildBroadcastScreen(String groupId, Map<String, dynamic>? args) {
    return FutureBuilder<GroupModel?>(
      future: GroupService.instance.getGroup(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Not Found')),
            body: const Center(child: Text('Group not found')),
          );
        }

        return BroadcastScreen(
          groupId: groupId,
          groupName: args?['groupName'] ?? '',
          currentUserId: args?['currentUserId'] ?? '',
          currentUserName: args?['currentUserName'] ?? 'Muthawif',
        );
      },
    );
  }
}

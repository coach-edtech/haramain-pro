import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';
import 'broadcast_screen.dart';
import 'group_qr_screen.dart';

/// Screen showing group details and member list
class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  final String currentUserId;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late GroupModel _group;
  late List<MemberModel> _members;
  bool _isLoading = true;

  bool get _isMuthawif => _group.muthawifId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);

    final members = await GroupService.instance.getGroupMembers(_group.id);

    if (mounted) {
      setState(() {
        _members = members;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_group.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isMuthawif) ...[
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: _showQRCode,
              tooltip: 'Show QR Code',
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _navigateToBroadcast,
              tooltip: 'Broadcast',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: Column(
          children: [
            // Group Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_members.length} / ${_group.maxMembers} members',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                  if (_isMuthawif) ...[
                    const SizedBox(height: 8),
                    Text(
                      'You are the Muthawif of this group',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ],
              ),
            ),

            // Members List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _members.isEmpty
                      ? const Center(child: Text('No members yet'))
                      : ListView.builder(
                          itemCount: _members.length,
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            return _MemberTile(
                              member: member,
                              isCurrentUser: member.userId == widget.currentUserId,
                              onRemove: member.userId != widget.currentUserId
                                  ? () => _removeMember(member)
                                  : null,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget? _buildBottomBar() {
    if (_isMuthawif) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _navigateToBroadcast,
            icon: const Icon(Icons.send),
            label: const Text('Broadcast Schedule'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton.icon(
          onPressed: _leaveGroup,
          icon: const Icon(Icons.exit_to_app, color: Colors.red),
          label: const Text(
            'Leave Group',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }

  void _showQRCode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupQRScreen(
          group: _group,
          muthawifId: widget.currentUserId,
        ),
      ),
    );
  }

  void _navigateToBroadcast() {
    // Find current user's name from members list
    final currentMember = _members.firstWhere(
      (m) => m.userId == widget.currentUserId,
      orElse: () => MemberModel(
        userId: widget.currentUserId,
        userName: 'Muthawif',
        role: GroupRole.owner,
        joinedAt: DateTime.now(),
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BroadcastScreen(
          groupId: _group.id,
          groupName: _group.name,
          currentUserId: widget.currentUserId,
          currentUserName: currentMember.userName,
        ),
      ),
    );
  }

  Future<void> _removeMember(MemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.userName} from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await GroupService.instance.removeMember(
      muthawifId: widget.currentUserId,
      memberId: member.userId,
      groupId: _group.id,
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.userName} removed from group'),
          backgroundColor: Colors.green,
        ),
      );
      _loadMembers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to remove member'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? You can rejoin later with a new PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await GroupService.instance.leaveGroup(
      jamaahId: widget.currentUserId,
      groupId: _group.id,
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have left the group'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Return to previous screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to leave group'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _MemberTile extends StatelessWidget {
  final MemberModel member;
  final bool isCurrentUser;
  final VoidCallback? onRemove;

  const _MemberTile({
    required this.member,
    required this.isCurrentUser,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: member.isOwner
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary,
        child: Text(
          member.userName.isNotEmpty ? member.userName[0].toUpperCase() : '?',
          style: TextStyle(
            color: member.isOwner
                ? Colors.white
                : Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(member.userName),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'You',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Icon(
            member.isOwner ? Icons.star : Icons.person,
            size: 16,
            color: member.isOwner
                ? Colors.amber.shade700
                : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            member.isOwner ? 'Owner' : 'Member',
            style: TextStyle(
              color: member.isOwner
                  ? Colors.amber.shade700
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Joined ${_formatDate(member.joinedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
      trailing: member.isOwner && onRemove != null
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: onRemove,
              tooltip: 'Remove member',
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:interstellar/src/api/content_sources.dart';
import 'package:interstellar/src/api/messages.dart';
import 'package:interstellar/src/api/users.dart' as api_users;
import 'package:interstellar/src/models/user.dart';
import 'package:interstellar/src/screens/entries/entries_list.dart';
import 'package:interstellar/src/screens/feed_screen.dart';
import 'package:interstellar/src/screens/posts/posts_list.dart';
import 'package:interstellar/src/screens/profile/message_thread_screen.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/markdown.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:provider/provider.dart';

class UserScreen extends StatefulWidget {
  final int userId;
  final DetailedUserModel? initData;
  final void Function(DetailedUserModel)? onUpdate;

  const UserScreen(this.userId, {super.key, this.initData, this.onUpdate});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  DetailedUserModel? _data;
  FeedMode _feedMode = FeedMode.entries;
  TextEditingController? _messageController;

  @override
  void initState() {
    super.initState();

    _data = widget.initData;

    if (_data == null) {
      api_users
          .fetchUser(
            context.read<SettingsController>().httpClient,
            context.read<SettingsController>().instanceHost,
            widget.userId,
          )
          .then((value) => setState(() {
                _data = value;
              }));
    }
  }

  Widget _userDetails() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (_data!.avatar?.storageUrl != null)
                Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Avatar(_data!.avatar!.storageUrl, radius: 32)),
              Expanded(
                child: Text(
                  _data!.username,
                  style: Theme.of(context).textTheme.titleLarge,
                  softWrap: true,
                ),
              ),
              OutlinedButton(
                style: ButtonStyle(
                    foregroundColor: _data!.isFollowedByUser == true
                        ? MaterialStatePropertyAll(Colors.purple.shade400)
                        : null),
                onPressed: whenLoggedIn(context, () async {
                  var newValue = await api_users.putFollow(
                      context.read<SettingsController>().httpClient,
                      context.read<SettingsController>().instanceHost,
                      _data!.userId,
                      !_data!.isFollowedByUser!);

                  setState(() {
                    _data = newValue;
                  });
                  if (widget.onUpdate != null) {
                    widget.onUpdate!(newValue);
                  }
                }),
                child: Row(
                  children: [
                    const Icon(Icons.group),
                    Text(' ${intFormat(_data!.followersCount)}'),
                  ],
                ),
              ),
              if (!_data!.username.contains('@'))
                IconButton(
                  onPressed: () {
                    setState(() {
                      _messageController = TextEditingController();
                    });
                  },
                  icon: const Icon(Icons.mail),
                  tooltip: 'Send message',
                )
            ],
          ),
          if (_messageController != null)
            Column(children: [
              TextEditor(
                _messageController!,
                isMarkdown: true,
                label: 'Message',
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      setState(() {
                        _messageController = null;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final newThread = await postMessage(
                        context.read<SettingsController>().httpClient,
                        context.read<SettingsController>().instanceHost,
                        _data!.userId,
                        _messageController!.text,
                      );

                      setState(() {
                        _messageController = null;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                MessageThreadScreen(initData: newThread),
                          ),
                        );
                      });
                    },
                    child: const Text('Send'),
                  )
                ],
              )
            ]),
          if (_data!.about != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Markdown(_data!.about!),
            )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_data?.username ?? ''),
          actions: [
            SegmentedButton(
              segments: const [
                ButtonSegment(
                  value: FeedMode.entries,
                  label: Text("Threads"),
                ),
                ButtonSegment(
                  value: FeedMode.posts,
                  label: Text("Posts"),
                ),
              ],
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity(horizontal: -3, vertical: -3),
              ),
              selected: <FeedMode>{_feedMode},
              onSelectionChanged: (Set<FeedMode> newSelection) {
                setState(() {
                  _feedMode = newSelection.first;
                });
              },
            ),
          ],
        ),
        body: switch (_feedMode) {
          FeedMode.entries => EntriesListView(
              contentSource: ContentUser(widget.userId),
              details: _data != null ? _userDetails() : null,
            ),
          FeedMode.posts => PostsListView(
              contentSource: ContentUser(widget.userId),
              details: _data != null ? _userDetails() : null,
            ),
        });
  }
}

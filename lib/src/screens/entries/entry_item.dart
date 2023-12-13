import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:interstellar/src/api/content_sources.dart';
import 'package:interstellar/src/api/entries.dart' as api_entries;
import 'package:interstellar/src/screens/entries/entries_screen.dart';
import 'package:interstellar/src/utils.dart';
import 'package:interstellar/src/widgets/display_name.dart';
import 'package:url_launcher/url_launcher.dart';

class EntryItem extends StatelessWidget {
  const EntryItem(
    this.item, {
    super.key,
    this.isPreview = false,
  });

  final api_entries.EntryItem item;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (item.image?.storageUrl != null)
          isPreview
              ? Image.network(
                  item.image!.storageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height / 2,
                  ),
                  child: Image.network(
                    item.image!.storageUrl,
                  )),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              item.type == 'link' && item.url != null
                  ? InkWell(
                      child: Text(
                        item.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .apply(decoration: TextDecoration.underline),
                      ),
                      onTap: () {
                        launchUrl(Uri.parse(item.url!));
                      },
                    )
                  : Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
              const SizedBox(height: 10),
              Row(
                children: [
                  DisplayName(
                    item.magazine.name,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EntriesScreen(
                            title: item.magazine.name,
                            contentSource:
                                ContentMagazine(item.magazine.magazineId),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      timeDiffFormat(item.createdAt),
                      style: const TextStyle(fontWeight: FontWeight.w300),
                    ),
                  ),
                  DisplayName(
                    item.user.username,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EntriesScreen(
                            title: item.user.username,
                            contentSource: ContentUser(item.user.userId),
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: IconButton(
                      tooltip: item.domain.name,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EntriesScreen(
                              title: item.domain.name,
                              contentSource:
                                  ContentDomain(item.domain.domainId),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.public),
                      iconSize: 16,
                      style: const ButtonStyle(
                          minimumSize:
                              MaterialStatePropertyAll(Size.fromRadius(16))),
                    ),
                  ),
                ],
              ),
              if (item.body != null && item.body!.isNotEmpty)
                const SizedBox(height: 10),
              if (item.body != null && item.body!.isNotEmpty)
                isPreview
                    ? Text(
                        item.body!,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      )
                    : MarkdownBody(data: item.body!),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  const Icon(Icons.comment),
                  const SizedBox(width: 4),
                  Text(intFormat(item.numComments)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.rocket_launch),
                    onPressed: () {},
                  ),
                  Text(intFormat(item.uv)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: () {},
                  ),
                  Text(intFormat(item.favourites - item.dv)),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
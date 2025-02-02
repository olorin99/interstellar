import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/api/content_sources.dart';
import 'package:interstellar/src/api/entries.dart' as api_entries;
import 'package:interstellar/src/models/entry.dart';
import 'package:interstellar/src/screens/entries/entry_item.dart';
import 'package:interstellar/src/screens/entries/entry_page.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:provider/provider.dart';

class EntriesListView extends StatefulWidget {
  const EntriesListView({
    super.key,
    this.contentSource = const ContentAll(),
    this.details,
  });

  final ContentSource contentSource;
  final Widget? details;

  @override
  State<EntriesListView> createState() => _EntriesListViewState();
}

class _EntriesListViewState extends State<EntriesListView> {
  ContentSort sort = ContentSort.hot;

  final PagingController<int, EntryModel> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newPage = await api_entries.fetchEntries(
        context.read<SettingsController>().httpClient,
        context.read<SettingsController>().instanceHost,
        widget.contentSource,
        page: pageKey,
        sort: sort,
      );

      // Check BuildContext
      if (!mounted) return;

      final isLastPage =
          newPage.pagination.currentPage == newPage.pagination.maxPage;
      // Prevent duplicates
      final currentItemIds =
          _pagingController.itemList?.map((e) => e.entryId) ?? [];
      final newItems = newPage.items
          .where((e) => !currentItemIds.contains(e.entryId))
          .toList();

      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.sync(
        () => _pagingController.refresh(),
      ),
      child: CustomScrollView(
        slivers: [
          if (widget.details != null)
            SliverToBoxAdapter(
              child: widget.details,
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  DropdownButton<ContentSort>(
                    value: sort,
                    onChanged: (newSort) {
                      if (newSort != null) {
                        setState(() {
                          sort = newSort;
                          _pagingController.refresh();
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: ContentSort.hot,
                        child: Text('Hot'),
                      ),
                      DropdownMenuItem(
                        value: ContentSort.top,
                        child: Text('Top'),
                      ),
                      DropdownMenuItem(
                        value: ContentSort.newest,
                        child: Text('Newest'),
                      ),
                      DropdownMenuItem(
                        value: ContentSort.active,
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: ContentSort.commented,
                        child: Text('Commented'),
                      ),
                      DropdownMenuItem(
                        value: ContentSort.oldest,
                        child: Text('Oldest'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          PagedSliverList<int, EntryModel>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<EntryModel>(
              itemBuilder: (context, item, index) => Card(
                margin: const EdgeInsets.all(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EntryPage(item, (newValue) {
                          var newList = _pagingController.itemList;
                          newList![index] = newValue;
                          setState(() {
                            _pagingController.itemList = newList;
                          });
                        }),
                      ),
                    );
                  },
                  child: EntryItem(
                    item,
                    (newValue) {
                      var newList = _pagingController.itemList;
                      newList![index] = newValue;
                      setState(() {
                        _pagingController.itemList = newList;
                      });
                    },
                    isPreview: true,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}

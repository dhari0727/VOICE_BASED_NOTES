import 'package:flutter/material.dart';

class SimpleHeader extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final List<String> allTags;
  final String? selectedTag;
  final Function(String?) onTagSelected;
  final VoidCallback onClearFilters;

  const SimpleHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.allTags,
    required this.selectedTag,
    required this.onTagSelected,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(context),
          const SizedBox(height: 12),
          _buildSearchField(context),
          if (allTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTagFilters(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.mic, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          'Speak and Save',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (searchController.text.isNotEmpty || selectedTag != null)
          IconButton(
            onPressed: onClearFilters,
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Clear filters',
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search voice notes...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
          suffixIcon:
              searchController.text.isNotEmpty
                  ? IconButton(
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    icon: Icon(
                      Icons.clear,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      size: 18,
                    ),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTagFilters(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: allTags.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildTagChip(
              context,
              'All',
              isSelected: selectedTag == null,
              onTap: () => onTagSelected(null),
            );
          }

          final tag = allTags[index - 1];
          return _buildTagChip(
            context,
            tag,
            isSelected: selectedTag == tag,
            onTap: () => onTagSelected(tag),
          );
        },
      ),
    );
  }

  Widget _buildTagChip(
    BuildContext context,
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF6C5CE7)
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF6C5CE7)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

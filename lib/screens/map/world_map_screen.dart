import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/explore/explore_cubit.dart';
import '../../cubits/explore/explore_state.dart';
import '../../models/language.dart';
import 'widgets/archival_map_canvas.dart';
import 'widgets/featured_echo_card.dart';

/// Screen 2: World Map & Living Atlas Discovery Screen.
/// Loads dynamic dialect pins, languages, and featured echo from ExploreCubit.
class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filterChips = const ['All Continents', 'Featured'];
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ensure atlas data is loaded
    context.read<ExploreCubit>().loadAtlasData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer,
              ),
              child: const Icon(
                Icons.graphic_eq,
                color: AppColors.primaryFixed,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ECHOES',
                    style: AppTypography.labelSm.copyWith(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Living Atlas',
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<AuthCubit, EchoesAuthState>(
            builder: (context, authState) {
              if (authState is Authenticated) {
                return IconButton(
                  tooltip: 'Sign Out (${authState.profile.displayName})',
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: () => context.read<AuthCubit>().signOut(),
                );
              }
              return TextButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Sign In'),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<ExploreCubit, ExploreState>(
        builder: (context, state) {
          // 1. Loading State
          if (state is ExploreLoading || state is ExploreInitial) {
            return _buildLoadingState();
          }

          // 2. Error State
          if (state is ExploreError) {
            return _buildErrorState(state.message);
          }

          // 3. Loaded State
          if (state is ExploreLoaded) {
            if (state.isEmpty) {
              return _buildEmptyState();
            }
            return _buildLoadedContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: _buildEditorialBottomBar(),
    );
  }

  // ---------------------------------------------------------------------------
  // Editorial Loading State
  // ---------------------------------------------------------------------------
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withValues(alpha: 0.1),
            ),
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Unfolding the Living Atlas...',
            style: AppTypography.headlineSm.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            'Connecting with global dialect custodians & archival recordings',
            style: AppTypography.bodySm.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error State
  // ---------------------------------------------------------------------------
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.public_off,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "We couldn't load the atlas.",
              style: AppTypography.headlineSm.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTypography.bodySm.copyWith(color: AppColors.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<ExploreCubit>().loadAtlasData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hearing_disabled,
              size: 48,
              color: AppColors.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'The atlas is quiet for now.',
              style: AppTypography.headlineSm.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              'New voices are being preserved.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<ExploreCubit>().loadAtlasData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Atlas'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Loaded Atlas Content
  // ---------------------------------------------------------------------------
  Widget _buildLoadedContent(ExploreLoaded state) {
    final filteredPins = state.filteredPins;
    final filteredLanguages = state.filteredLanguages;
    final featuredWord = state.featuredEcho;

    Language? featuredLanguage;
    if (featuredWord != null) {
      try {
        featuredLanguage = state.languages.firstWhere(
          (l) => l.id == featuredWord.languageId,
        );
      } catch (_) {}
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore voices around the world',
                  style: AppTypography.headlineLg,
                ),
                const SizedBox(height: 12),

                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (query) {
                    context.read<ExploreCubit>().setSearchQuery(query);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search languages, places, or dialects...',
                    hintStyle: AppTypography.bodySm,
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.onSurfaceVariant,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ExploreCubit>().setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: const OutlineInputBorder(
                      borderRadius: AppRadii.lg,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterChips.map((chip) {
                      final isSelected = state.activeFilter == chip;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(chip),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          labelStyle: AppTypography.labelMd.copyWith(
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.full,
                          ),
                          side: BorderSide.none,
                          onSelected: (_) {
                            context.read<ExploreCubit>().setFilter(chip);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 2. Archival Map Canvas with Normalized Coordinate Pins from Supabase
          ArchivalMapCanvas(
            pins: filteredPins,
            onPinSelected: (languageId) {
              context.push('/language/$languageId');
            },
          ),

          // 3. Featured Echo of the Day
          if (featuredWord != null)
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FeaturedEchoCard(
                  word: featuredWord,
                  language: featuredLanguage,
                  onDetailsTap: () => context.push('/word/${featuredWord.id}'),
                ),
              ),
            ),

          // 4. Preserved Dialects Grid / List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Preserved Dialects',
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${filteredLanguages.length} Languages',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal scroll tray of dialect language cards
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredLanguages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final lang = filteredLanguages[index];
                return _buildLanguageQuickCard(lang);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLanguageQuickCard(Language language) {
    return GestureDetector(
      onTap: () => context.push('/language/${language.id}'),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.lg,
          boxShadow: AppShadows.paperCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        language.countryEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          language.name,
                          style: AppTypography.headlineSm,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: AppRadii.sm,
                  ),
                  child: Text(
                    language.isoCode.toUpperCase(),
                    style: AppTypography.labelSm,
                  ),
                ),
              ],
            ),
            Text(
              language.nativeScript,
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${language.verifiedAudioCount} voices',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Editorial Bottom Bar with Center Tactile Record Button
  // ---------------------------------------------------------------------------
  Widget _buildEditorialBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(27, 28, 25, 0.06),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(child: _buildNavTab(0, Icons.public, 'Atlas')),
              Expanded(child: _buildNavTab(1, Icons.auto_stories, 'Archive')),

              // Elevated Center Record Expedition Button
              GestureDetector(
                onTap: () => context.push('/record'),
                child: Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: AppColors.onPrimary,
                    size: 24,
                  ),
                ),
              ),

              Expanded(child: _buildNavTab(2, Icons.bookmark_border, 'Saved')),
              Expanded(child: _buildNavTab(3, Icons.person_outline, 'Custodian')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

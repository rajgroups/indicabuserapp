import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:indicab/core/config/Config.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:uuid/uuid.dart';

class GooglePlacesInput extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final Function(dynamic prediction) onPlaceSelected;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const GooglePlacesInput({
    super.key,
    required this.hintText,
    required this.controller,
    required this.onPlaceSelected,
    required this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onClear,
  });

  @override
  State<GooglePlacesInput> createState() => _GooglePlacesInputState();
}

class _GooglePlacesInputState extends State<GooglePlacesInput> {
  final Dio _dio = Dio();
  final FocusNode _focusNode = FocusNode();
  final List<_PlaceSuggestion> _suggestions = <_PlaceSuggestion>[];
  static const Uuid _uuid = Uuid();

  Timer? _debounce;
  bool _isLoading = false;
  String? _errorText;

  /// Session token for grouping autocomplete + place details into one billing session.
  String? _sessionToken;

  /// The query string that was last successfully fetched (prevents duplicate requests).
  String? _lastFetchedQuery;

  /// Monotonically increasing generation counter to discard stale responses.
  int _fetchGeneration = 0;

  /// Active CancelToken — cancelled when a new request supersedes the previous one.
  CancelToken? _activeCancelToken;

  /// Minimum number of characters required before sending an autocomplete request.
  static const int _minQueryLength = 3;

  bool get _hasValidPlacesKey => AppEnv.hasGooglePlacesApiKey;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _activeCancelToken?.cancel('Widget disposed');
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearInput() {
    widget.controller.clear();
    _debounce?.cancel();
    _activeCancelToken?.cancel('Input cleared');
    _resetSession();
    setState(() {
      _isLoading = false;
      _errorText = null;
      _suggestions.clear();
    });
    widget.onClear?.call();
  }

  /// Reset the Places session token so the next search starts a new billing session.
  void _resetSession() {
    _sessionToken = null;
    _lastFetchedQuery = null;
  }

  /// Ensure a session token exists; create one if this is the start of a new session.
  String _ensureSessionToken() {
    _sessionToken ??= _uuid.v4();
    return _sessionToken!;
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      widget.onTap?.call();
    } else if (mounted) {
      setState(() {
        _suggestions.clear();
      });
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      _activeCancelToken?.cancel('Empty input');
      setState(() {
        _isLoading = false;
        _errorText = null;
        _suggestions.clear();
      });
      return;
    }

    // Don't fire API requests for very short queries — reduces unnecessary calls.
    if (trimmed.length < _minQueryLength) {
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 700), () {
      _fetchPredictions(trimmed);
    });
  }

  Future<void> _fetchPredictions(String query) async {
    if (!_hasValidPlacesKey) {
      return;
    }

    // Skip if this exact query was already fetched (e.g. user typed, deleted, retyped).
    if (query == _lastFetchedQuery && _suggestions.isNotEmpty) {
      return;
    }

    // Cancel any in-flight request before starting a new one.
    _activeCancelToken?.cancel('Superseded by newer query');
    _activeCancelToken = CancelToken();

    final int generation = ++_fetchGeneration;
    final String sessionToken = _ensureSessionToken();

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    assert(() {
      debugPrint('[GOOGLE PLACES] Autocomplete request: "$query" (session=${sessionToken.substring(0, 8)}...)');
      return true;
    }());

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: <String, dynamic>{
          'input': query,
          'key': AppEnv.googlePlacesApiKey,
          'language': 'en',
          'sessiontoken': sessionToken,
        },
        cancelToken: _activeCancelToken,
      );

      // Discard stale response if a newer request was already launched.
      if (generation != _fetchGeneration || !mounted) {
        return;
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );
      final String status = (data['status'] as String? ?? '').trim();
      final String? errorMessage = data['error_message'] as String?;

      if (status == 'OK' || status == 'ZERO_RESULTS') {
        final List<dynamic> predictions =
            data['predictions'] as List<dynamic>? ?? <dynamic>[];

        _lastFetchedQuery = query;

        setState(() {
          _suggestions
            ..clear()
            ..addAll(
              predictions.map(
                (dynamic item) => _PlaceSuggestion.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              ),
            );
          _isLoading = false;
          _errorText = null;
        });
        return;
      }

      throw _PlacesApiException(
        _buildPlacesErrorMessage(status, errorMessage),
      );
    } catch (error) {
      // Don't treat Dio cancellations as errors.
      if (error is DioException && error.type == DioExceptionType.cancel) {
        return;
      }

      if (generation != _fetchGeneration || !mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _suggestions.clear();
        _errorText = _mapErrorToMessage(error);
      });
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    widget.controller.text = suggestion.description;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );

    // Cancel any pending autocomplete request.
    _activeCancelToken?.cancel('Place selected');

    // Use the same session token that was used for autocomplete requests.
    // After this Place Details call, the session ends.
    final String? sessionToken = _sessionToken;

    setState(() {
      _isLoading = true;
      _errorText = null;
      _suggestions.clear();
    });

    assert(() {
      debugPrint('[GOOGLE PLACES] Place Details request: placeId=${suggestion.placeId}'
          ' (session=${sessionToken?.substring(0, 8) ?? 'none'}...)');
      return true;
    }());

    try {
      final queryParams = <String, dynamic>{
        'place_id': suggestion.placeId,
        'fields': 'name,formatted_address,geometry',
        'key': AppEnv.googlePlacesApiKey,
      };

      // Include session token to complete the billing session.
      if (sessionToken != null) {
        queryParams['sessiontoken'] = sessionToken;
      }

      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: queryParams,
      );

      // Session is complete — reset for the next search.
      _resetSession();

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );
      final String status = (data['status'] as String? ?? '').trim();
      final String? errorMessage = data['error_message'] as String?;

      if (status != 'OK') {
        throw _PlacesApiException(
          _buildPlacesErrorMessage(status, errorMessage),
        );
      }

      final Map<String, dynamic> result = Map<String, dynamic>.from(
        data['result'] as Map? ?? <String, dynamic>{},
      );
      final Map<String, dynamic> geometry = Map<String, dynamic>.from(
        result['geometry'] as Map? ?? <String, dynamic>{},
      );
      final Map<String, dynamic> location = Map<String, dynamic>.from(
        geometry['location'] as Map? ?? <String, dynamic>{},
      );

      final place = PlaceSelection(
        placeId: suggestion.placeId,
        name: (result['name'] as String?) ?? suggestion.description,
        description: suggestion.description,
        formattedAddress:
            (result['formatted_address'] as String?) ?? suggestion.description,
        lat: '${location['lat'] ?? ''}',
        lng: '${location['lng'] ?? ''}',
      );

      if (!mounted) {
        return;
      }

      widget.controller.text = place.formattedAddress;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );

      setState(() {
        _isLoading = false;
        _errorText = null;
      });

      widget.onPlaceSelected(place);
      _focusNode.unfocus();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorText = _mapErrorToMessage(error);
      });
    }
  }

  String _mapErrorToMessage(Object error) {
    if (error is _PlacesApiException) {
      return error.message;
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Google Places request timed out. Please try again.';
      }

      return 'Unable to reach Google Places. Check your internet connection.';
    }

    return 'Location search failed. Please try again.';
  }

  String _buildPlacesErrorMessage(String status, String? errorMessage) {
    final String cleanMessage = (errorMessage ?? '').trim();
    final String lower = cleanMessage.toLowerCase();

    if (status == 'REQUEST_DENIED') {
      if (lower.contains('not authorized') ||
          lower.contains('api project is not authorized') ||
          lower.contains('referer restrictions') ||
          lower.contains('ip') && lower.contains('authorized')) {
        return 'This Places key is being rejected by Google. Enable Places API and allow this key to call Places Web Service requests.';
      }

      if (cleanMessage.isNotEmpty) {
        return cleanMessage;
      }
    }

    if (status == 'OVER_QUERY_LIMIT') {
      return 'Google Places quota has been reached for this API key.';
    }

    if (status == 'INVALID_REQUEST') {
      return cleanMessage.isNotEmpty
          ? cleanMessage
          : 'Google Places rejected the request.';
    }

    if (cleanMessage.isNotEmpty) {
      return cleanMessage;
    }

    return 'Google Places request failed with status $status.';
  }

  Widget? _buildSuffixIcon() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final bool hasText = widget.controller.text.isNotEmpty;

    if (hasText) {
      final clearButton = IconButton(
        icon: const Icon(
          Icons.cancel_rounded,
          size: 20,
          color: AppColors.textMuted,
        ),
        onPressed: _clearInput,
        tooltip: 'Clear text',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      );

      if (widget.suffixIcon != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            clearButton,
            widget.suffixIcon!,
          ],
        );
      }
      return clearButton;
    }

    return widget.suffixIcon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(16),
      //   border: Border.all(color: AppColors.borderSoft, width: 1),
      //   // boxShadow: const <BoxShadow>[
      //   //   BoxShadow(
      //   //     blurRadius: 12,
      //   //     offset: Offset(0, 4),
      //   //     color: Color.fromARGB(14, 0, 0, 0),
      //   //   ),
      //   // ],
      // ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            readOnly: !_hasValidPlacesKey,
            onTap: widget.onTap,
            onChanged: _hasValidPlacesKey ? _onChanged : null,
            decoration: InputDecoration(
              hintText: widget.hintText,
              errorText: !_hasValidPlacesKey
                  ? 'Missing GOOGLE_PLACES_API_KEY in .env.'
                  : _errorText,
              prefixIcon: Icon(widget.prefixIcon, color: AppColors.primaryDark),
              suffixIcon: _buildSuffixIcon(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              hintStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E), // Navy blue
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 208),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white24),
                  itemBuilder: (BuildContext context, int index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 0,
                      ),
                      leading: const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.white70,
                      ),
                      title: Text(
                        suggestion.description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () => _selectSuggestion(suggestion),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PlaceSelection {
  final String placeId;
  final String name;
  final String description;
  final String formattedAddress;
  final String? vicinity;
  final String lat;
  final String lng;
  final List<String> types;

  const PlaceSelection({
    required this.placeId,
    required this.name,
    required this.description,
    required this.formattedAddress,
    this.vicinity,
    required this.lat,
    required this.lng,
    this.types = const <String>[],
  });

  @override
  String toString() => 'PlaceSelection(name: $name, lat: $lat, lng: $lng)';
}

class _PlaceSuggestion {
  final String description;
  final String placeId;

  const _PlaceSuggestion({
    required this.description,
    required this.placeId,
  });

  factory _PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return _PlaceSuggestion(
      description: json['description'] as String? ?? '',
      placeId: json['place_id'] as String? ?? '',
    );
  }
}

class _PlacesApiException implements Exception {
  final String message;

  const _PlacesApiException(this.message);
}

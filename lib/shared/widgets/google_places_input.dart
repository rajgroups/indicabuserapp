import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:indicab/core/config/Config.dart';
import 'package:indicab/core/constants/Colors.dart';

class GooglePlacesInput extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final Function(dynamic prediction) onPlaceSelected;
  final IconData prefixIcon;
  final Widget? suffixIcon;

  const GooglePlacesInput({
    super.key,
    required this.hintText,
    required this.controller,
    required this.onPlaceSelected,
    required this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<GooglePlacesInput> createState() => _GooglePlacesInputState();
}

class _GooglePlacesInputState extends State<GooglePlacesInput> {
  final Dio _dio = Dio();
  final FocusNode _focusNode = FocusNode();
  final List<_PlaceSuggestion> _suggestions = <_PlaceSuggestion>[];

  Timer? _debounce;
  bool _isLoading = false;
  String? _errorText;

  bool get _hasValidPlacesKey => AppEnv.hasGooglePlacesApiKey;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && mounted) {
      setState(() {
        _suggestions.clear();
      });
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorText = null;
        _suggestions.clear();
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchPredictions(value.trim());
    });
  }

  Future<void> _fetchPredictions(String query) async {
    if (!_hasValidPlacesKey) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: <String, dynamic>{
          'input': query,
          'key': AppEnv.googlePlacesApiKey,
          'language': 'en',
        },
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );
      final String status = (data['status'] as String? ?? '').trim();
      final String? errorMessage = data['error_message'] as String?;

      if (status == 'OK' || status == 'ZERO_RESULTS') {
        final List<dynamic> predictions =
            data['predictions'] as List<dynamic>? ?? <dynamic>[];

        if (!mounted) {
          return;
        }

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
      if (!mounted) {
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

    setState(() {
      _isLoading = true;
      _errorText = null;
      _suggestions.clear();
    });

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: <String, dynamic>{
          'place_id': suggestion.placeId,
          'fields': 'formatted_address,geometry',
          'key': AppEnv.googlePlacesApiKey,
        },
      );

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
        description:
            (result['formatted_address'] as String?) ?? suggestion.description,
        lat: '${location['lat'] ?? ''}',
        lng: '${location['lng'] ?? ''}',
      );

      if (!mounted) {
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 2),
            color: Color.fromARGB(18, 0, 0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            readOnly: !_hasValidPlacesKey,
            onChanged: _hasValidPlacesKey ? _onChanged : null,
            decoration: InputDecoration(
              hintText: widget.hintText,
              errorText: !_hasValidPlacesKey
                  ? 'Missing GOOGLE_PLACES_API_KEY in .env.'
                  : _errorText,
              prefixIcon: Icon(widget.prefixIcon, color: AppColors.primaryDark),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : widget.suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          if (_suggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(suggestion.description),
                    onTap: () => _selectSuggestion(suggestion),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class PlaceSelection {
  final String description;
  final String lat;
  final String lng;

  const PlaceSelection({
    required this.description,
    required this.lat,
    required this.lng,
  });
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

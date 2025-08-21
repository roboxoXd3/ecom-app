import 'package:flutter/material.dart';
import '../../../core/services/google_maps_service.dart';

class GooglePlacesAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(PlaceDetails) onPlaceSelected;
  final InputDecoration? decoration;

  const GooglePlacesAutocomplete({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onPlaceSelected,
    this.decoration,
  });

  @override
  State<GooglePlacesAutocomplete> createState() =>
      _GooglePlacesAutocompleteState();
}

class _GooglePlacesAutocompleteState extends State<GooglePlacesAutocomplete> {
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.length > 2) {
      _searchPlaces(text);
    } else {
      _clearPredictions();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  Future<void> _searchPlaces(String input) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final predictions = await GoogleMapsService.getPlacePredictions(input);
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
      _showOverlay();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _predictions = [];
      });
    }
  }

  void _clearPredictions() {
    setState(() {
      _predictions = [];
    });
    _removeOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    if (_predictions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width:
                MediaQuery.of(context).size.width - 32, // Account for padding
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 60),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _predictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, size: 20),
                        title: Text(
                          prediction.mainText,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          prediction.secondaryText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        onTap: () => _onPredictionSelected(prediction),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _onPredictionSelected(PlacePrediction prediction) async {
    widget.controller.text = prediction.description;
    _removeOverlay();
    _focusNode.unfocus();

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final placeDetails = await GoogleMapsService.getPlaceDetails(
        prediction.placeId,
      );
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        if (placeDetails != null) {
          widget.onPlaceSelected(placeDetails);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading address details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration:
            widget.decoration ??
            InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : widget.controller.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          widget.controller.clear();
                          _clearPredictions();
                        },
                      )
                      : null,
              border: const OutlineInputBorder(),
            ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter an address';
          }
          return null;
        },
      ),
    );
  }
}

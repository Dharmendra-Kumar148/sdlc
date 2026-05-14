import 'package:flutter/material.dart';

enum FilterType {
  none,
  brightness,
  contrast,
  grayscale,
  sepia,
  vintage,
  cinematicWarm,
  cinematicCool,
  skinSmoothing,
  glow,
  glitch,
}

enum FilterCategory {
  basic,
  cinematic,
  beauty,
  effects,
}

class EffectLayer {
  final String id;
  final FilterType type;
  final double intensity;
  final double opacity;
  final bool isVisible;
  final BlendMode blendMode;

  EffectLayer({
    required this.id,
    required this.type,
    this.intensity = 0.5,
    this.opacity = 1.0,
    this.isVisible = true,
    this.blendMode = BlendMode.srcOver,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'intensity': intensity,
    'opacity': opacity,
    'isVisible': isVisible,
    'blendMode': blendMode.index,
  };

  factory EffectLayer.fromJson(Map<String, dynamic> json) => EffectLayer(
    id: json['id'],
    type: FilterType.values.firstWhere((e) => e.name == json['type']),
    intensity: json['intensity'],
    isVisible: json['isVisible'],
    blendMode: BlendMode.values[json['blendMode']],
  );
}

class FilterPreset {
  final String id;
  final String name;
  final List<EffectLayer> layers;
  final Map<String, dynamic> metadata;

  FilterPreset({
    required this.id,
    required this.name,
    required this.layers,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'layers': layers.map((l) => l.toJson()).toList(),
    'metadata': metadata,
  };

  factory FilterPreset.fromJson(Map<String, dynamic> json) => FilterPreset(
    id: json['id'],
    name: json['name'],
    layers: (json['layers'] as List).map((l) => EffectLayer.fromJson(l)).toList(),
    metadata: json['metadata'] ?? {},
  );

  static FilterPreset get none => FilterPreset(id: 'none', name: 'None', layers: []);
}

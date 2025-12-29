import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../themes/app_theme.dart';
import '../widgets/app_text.dart';
import '../localization/app_localizations_extension.dart';
import '../utils/theme_extensions.dart';

class AdhanSoundSelectionScreen extends StatefulWidget {
  final String? currentSoundPath;
  
  const AdhanSoundSelectionScreen({
    super.key,
    this.currentSoundPath,
  });

  @override
  State<AdhanSoundSelectionScreen> createState() => _AdhanSoundSelectionScreenState();
}

class _AdhanSoundSelectionScreenState extends State<AdhanSoundSelectionScreen> {
  static const String _defaultSoundKey = 'default_adhan_sound';
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _selectedSound;
  bool _isPlaying = false;
  String? _currentlyPlayingSound;
  
  // Built-in adhan sounds
  final List<AdhanSound> _builtInSounds = [
    AdhanSound(
      name: 'Adhan 1',
      description: 'Traditional Adhan',
      path: 'assets/adhan/azan1.mp3',
      isAsset: true,
    ),
    AdhanSound(
      name: 'Adhan 2',
      description: 'Melodious Adhan',
      path: 'assets/adhan/azan2.mp3',
      isAsset: true,
    ),
    AdhanSound(
      name: 'Adhan 3',
      description: 'Classical Adhan',
      path: 'assets/adhan/azan3.mp3',
      isAsset: true,
    ),
    AdhanSound(
      name: 'Adhan 4',
      description: 'Modern Adhan',
      path: 'assets/adhan/azan4.mp3',
      isAsset: true,
    ),
    AdhanSound(
      name: 'Adhan 5',
      description: 'Peaceful Adhan',
      path: 'assets/adhan/azan5.mp3',
      isAsset: true,
    ),
  ];
  
  String? _customSoundPath;

  @override
  void initState() {
    super.initState();
    _selectedSound = widget.currentSoundPath ?? 'assets/adhan/azan1.mp3';
    _loadCustomSound();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingSound = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCustomSound() async {
    final prefs = await SharedPreferences.getInstance();
    _customSoundPath = prefs.getString('custom_adhan_path');
    setState(() {});
  }

  Future<void> _saveCustomSound(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_adhan_path', path);
    _customSoundPath = path;
    setState(() {});
  }

  Future<void> _pickCustomSound() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        await _saveCustomSound(filePath);
        setState(() {
          _selectedSound = filePath;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Custom sound selected: ${result.files.single.name}'),
              backgroundColor: context.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking sound: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playSound(String path, bool isAsset) async {
    try {
      if (_isPlaying && _currentlyPlayingSound == path) {
        // Stop current sound
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
          _currentlyPlayingSound = null;
        });
        return;
      }

      // Stop any currently playing sound
      await _audioPlayer.stop();

      // Play new sound
      if (isAsset) {
        await _audioPlayer.play(AssetSource(path.replaceFirst('assets/', '')));
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
      }

      setState(() {
        _isPlaying = true;
        _currentlyPlayingSound = path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing sound: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isPlaying = false;
        _currentlyPlayingSound = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: AppText(context.l.selectAdhanSound),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppText(
                    context.l.builtInSounds,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                    ),
                  ),
                ),
                
                AppText(
                  '5 ${context.l.adhanSound}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                
                const SizedBox(height: 16),
                
                // Built-in sounds
                ..._builtInSounds.map((sound) => _buildSoundTile(
                  sound: sound,
                  isSelected: _selectedSound == sound.path,
                  isDark: isDark,
                  onTap: () {
                    setState(() => _selectedSound = sound.path);
                  },
                  onPlay: () => _playSound(sound.path, sound.isAsset),
                  isPlaying: _isPlaying && _currentlyPlayingSound == sound.path,
                )),
                
                const SizedBox(height: 24),
                
                // Custom sound section
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppText(
                    context.l.customSound,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                    ),
                  ),
                ),
                
                const AppText(
                  '',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                
                const SizedBox(height: 16),
                
                // Custom sound picker
                _buildCustomSoundTile(isDark),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? context.surfaceColor : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedSound);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.l.saveSelection,
                      style: const TextStyle(
                        fontFamily: 'Poppins Regular',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundTile({
    required AdhanSound sound,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    required VoidCallback onPlay,
    required bool isPlaying,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryColor.withOpacity(0.1)
              : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: context.primaryColor, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? context.primaryColor
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: isSelected ? Colors.white : Colors.grey,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    sound.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? context.primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    sound.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            // Play button
            IconButton(
              onPressed: onPlay,
              icon: Icon(
                isPlaying ? Icons.stop_circle : Icons.play_circle_filled,
                color: isSelected ? context.primaryColor : Colors.grey,
                size: 32,
              ),
            ),
            
            // Check icon
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: context.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSoundTile(bool isDark) {
    final hasCustomSound = _customSoundPath != null;
    final isCustomSelected = hasCustomSound && _selectedSound == _customSoundPath;
    
    return InkWell(
      onTap: hasCustomSound
          ? () => setState(() => _selectedSound = _customSoundPath)
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCustomSelected
              ? context.primaryColor.withOpacity(0.1)
              : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: isCustomSelected
              ? Border.all(color: context.primaryColor, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasCustomSound && isCustomSelected
                        ? context.primaryColor
                        : (isDark ? Colors.white12 : Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.upload_file_rounded,
                    color: hasCustomSound && isCustomSelected ? Colors.white : Colors.grey,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        hasCustomSound ? 'Custom Sound' : 'No custom sound',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCustomSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isCustomSelected ? context.primaryColor : null,
                        ),
                      ),
                      if (hasCustomSound) ...[
                        const SizedBox(height: 2),
                        AppText(
                          _customSoundPath!.split('/').last,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Play button (if custom sound exists)
                if (hasCustomSound)
                  IconButton(
                    onPressed: () => _playSound(_customSoundPath!, false),
                    icon: Icon(
                      _isPlaying && _currentlyPlayingSound == _customSoundPath
                          ? Icons.stop_circle
                          : Icons.play_circle_filled,
                      color: isCustomSelected ? context.primaryColor : Colors.grey,
                      size: 32,
                    ),
                  ),
                
                // Check icon
                if (isCustomSelected)
                  Icon(
                    Icons.check_circle,
                    color: context.primaryColor,
                    size: 24,
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Pick file button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickCustomSound,
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(
                  hasCustomSound ? 'Change Custom Sound' : 'Pick Custom Sound',
                  style: const TextStyle(fontFamily: 'Poppins Regular'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.primaryColor,
                  side: BorderSide(color: context.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdhanSound {
  final String name;
  final String description;
  final String path;
  final bool isAsset;

  AdhanSound({
    required this.name,
    required this.description,
    required this.path,
    required this.isAsset,
  });
}


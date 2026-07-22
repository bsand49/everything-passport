import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/country.dart';
import '../services/user_profile_service.dart';
import '../services/metadata_service.dart';
import '../utils/validators.dart';
import '../utils/image_utils.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/loading_button.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/country_autocomplete.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nationalityController = TextEditingController();

  DateTime? _dateOfBirth;
  Country? _nationality;
  File? _selectedImage;
  String? _currentPhotoUrl;

  Timer? _usernameDebounce;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  bool _isPublic = false;

  bool _isLoading = false;
  late Future<List<Country>> _countriesFuture;

  @override
  void initState() {
    super.initState();
    _countriesFuture =
        Provider.of<MetadataService>(context, listen: false).getCountries();

    final profile = context.read<UserProfile?>();
    if (profile != null) {
      _usernameController.text = profile.username;
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _dateOfBirth = profile.dateOfBirth;
      _currentPhotoUrl = profile.photoUrl;
      _isUsernameAvailable = profile.username.isNotEmpty ? true : null;
      _isPublic = profile.isPublic;

      _countriesFuture.then((countries) {
        if (profile.nationality != null) {
          setState(() {
            _nationality = countries.firstWhere(
              (c) => c.id == profile.nationality,
              orElse: () => countries.first,
            );
            _nationalityController.text = _nationality!.name;
          });
        }
      });
    }

    // Automatically use Google photo if no custom photo exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<User?>(context, listen: false);
      if (_currentPhotoUrl == null &&
          user?.photoURL != null &&
          _selectedImage == null) {
        useGooglePhoto(user!.photoURL!);
      }
    });
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final primaryColor = Theme.of(context).primaryColor;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        maxWidth: 512,
        maxHeight: 512,
        compressQuality: 70,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Profile Picture',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            cropStyle: CropStyle.circle,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: 'Edit Profile Picture',
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
      }
    }
  }

  void _onUsernameChanged(String value) {
    if (_usernameDebounce?.isActive ?? false) _usernameDebounce!.cancel();

    final trimmedValue = value.trim().toLowerCase();

    if (trimmedValue.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    final currentProfile = context.read<UserProfile?>();
    // Don't re-check if it's the same as current
    if (currentProfile?.username.toLowerCase() == trimmedValue) {
      setState(() {
        _isUsernameAvailable = true;
        _isCheckingUsername = false;
      });
      return;
    }

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isCheckingUsername = true);

      final userProfileService =
          Provider.of<UserProfileService>(context, listen: false);
      final user = Provider.of<User?>(context, listen: false);

      if (user != null) {
        final isAvailable = await userProfileService.isUsernameAvailable(
            username: trimmedValue, currentUserId: user.uid);
        if (mounted) {
          setState(() {
            _isUsernameAvailable = isAvailable;
            _isCheckingUsername = false;
          });
        }
      }
    });
  }

  @visibleForTesting
  Future<void> useGooglePhoto(String url) async {
    setState(() => _isLoading = true);
    try {
      final client = Provider.of<http.Client>(context, listen: false);
      final file = await ImageUtils.downloadAndSaveImage(url, client,
          fileName: 'google_profile_temp.jpg');

      if (file != null && mounted) {
        setState(() {
          _selectedImage = file;
        });
      } else if (file == null) {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load Google photo: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUsernameAvailable == false) return;

    final user = Provider.of<User?>(context, listen: false);
    final currentProfile = context.read<UserProfile?>();
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final userProfileService =
          Provider.of<UserProfileService>(context, listen: false);

      String? photoUrl = _currentPhotoUrl;
      if (_selectedImage != null) {
        photoUrl = await userProfileService.uploadProfilePicture(
            userId: user.uid, image: _selectedImage!);
      }

      final profile = UserProfile(
        userId: user.uid,
        email: user.email,
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        isPublic: _isPublic,
        dateOfBirth: _dateOfBirth,
        nationality: _nationality?.id,
        photoUrl: photoUrl,
      );

      await userProfileService.saveProfile(
          profile: profile, oldUsername: currentProfile?.username ?? '');
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not Logged In")));
    }

    final isNewUser =
        context.select<UserProfile?, bool>((p) => p == null || p.isIncomplete);
    final googlePhotoUrl = user.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewUser ? 'Complete Your Profile' : 'Edit Profile'),
      ),
      body: FutureBuilder<List<Country>>(
        future: _countriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final countries = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileAvatar(
                    photoUrl: _currentPhotoUrl ?? googlePhotoUrl,
                    selectedImage: _selectedImage,
                    onEditPressed: _pickImage,
                  ),
                  const SizedBox(height: 24),
                  AuthTextField(
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    readOnly: true,
                    filled: true,
                    fillColor: Colors.black12,
                    controller: TextEditingController(text: user.email),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _usernameController,
                    onChanged: _onUsernameChanged,
                    labelText: 'Username *',
                    prefixIcon: Icons.alternate_email,
                    suffixIcon: _buildUsernameSuffix(),
                    helperText: 'Must be unique and at least 3 characters',
                    validator: (v) => Validators.validateUsername(v,
                        isAvailable: _isUsernameAvailable),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _firstNameController,
                    labelText: 'First Name *',
                    validator: (v) =>
                        Validators.validateRequired(v, fieldName: 'First Name'),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _lastNameController,
                    labelText: 'Last Name *',
                    validator: (v) =>
                        Validators.validateRequired(v, fieldName: 'Last Name'),
                  ),
                  const SizedBox(height: 16),
                  DatePickerField(
                    labelText: 'Date of Birth (Optional)',
                    value: _dateOfBirth,
                    onChanged: (date) => setState(() => _dateOfBirth = date),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: Localizations.localeOf(context),
                  ),
                  const SizedBox(height: 16),
                  CountryAutocomplete(
                    countries: countries,
                    initialValue: _nationality,
                    onSelected: (selection) =>
                        setState(() => _nationality = selection),
                  ),
                  const SizedBox(height: 16),
                  _buildPublicToggle(),
                  const SizedBox(height: 32),
                  LoadingButton(
                    onPressed: _submitProfile,
                    isLoading: _isLoading,
                    child:
                        Text(isNewUser ? 'Complete Profile' : 'Save Changes'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsernameSuffix() {
    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_usernameController.text.trim().length < 3) {
      return const SizedBox.shrink();
    }

    if (_isUsernameAvailable == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (_isUsernameAvailable == false) {
      return const Icon(Icons.error, color: Colors.red);
    }

    return const SizedBox.shrink();
  }

  Widget _buildPublicToggle() {
    return SwitchListTile(
      title: const Text('Public Profile'),
      subtitle: const Text(
          'Allow others to find you and add you as a friend. Your data will only be available to friends once you have accepted a friend request.'),
      secondary: Icon(_isPublic ? Icons.public : Icons.lock_outline),
      value: _isPublic,
      onChanged: (bool value) {
        setState(() {
          _isPublic = value;
        });
      },
    );
  }
}

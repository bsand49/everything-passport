import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/user_profile.dart';
import '../models/country.dart';
import '../services/user_service.dart';
import '../services/metadata_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
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

  String get _formattedDate {
    if (_dateOfBirth == null) return '';
    final Locale deviceLocale = Localizations.localeOf(context);
    return DateFormat.yMd(deviceLocale.toString()).format(_dateOfBirth!);
  }

  Future<void> _selectDate(BuildContext context) async {
    final Locale deviceLocale = Localizations.localeOf(context);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: deviceLocale,
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
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

      final userService = Provider.of<UserService>(context, listen: false);
      final user = Provider.of<User?>(context, listen: false);

      if (user != null) {
        final isAvailable =
            await userService.isUsernameAvailable(trimmedValue, user.uid);
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
      final response = await client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = p.join(tempDir.path, 'google_profile_temp.jpg');
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() {
            _selectedImage = file;
          });
        }
      } else {
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
      final userService = Provider.of<UserService>(context, listen: false);

      String? photoUrl = _currentPhotoUrl;
      if (_selectedImage != null) {
        photoUrl =
            await userService.uploadProfilePicture(user.uid, _selectedImage!);
      }

      final profile = UserProfile(
        uid: user.uid,
        email: user.email,
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        isPublic: _isPublic,
        dateOfBirth: _dateOfBirth,
        nationality: _nationality?.id,
        photoUrl: photoUrl,
      );

      await userService.saveProfileWithUsername(
          profile, currentProfile?.username ?? '');
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
                  _buildProfilePicturePicker(),
                  const SizedBox(height: 24),
                  _buildReadOnlyEmailField(user.email ?? ''),
                  const SizedBox(height: 16),
                  _buildUsernameField(),
                  const SizedBox(height: 16),
                  _buildNameField(_firstNameController, 'First Name *'),
                  const SizedBox(height: 16),
                  _buildNameField(_lastNameController, 'Last Name *'),
                  const SizedBox(height: 16),
                  _buildDateOfBirthDatePicker(),
                  const SizedBox(height: 16),
                  _buildNationalityAutocomplete(countries),
                  const SizedBox(height: 16),
                  _buildPublicToggle(),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _submitProfile,
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

  Widget _buildProfilePicturePicker() {
    final user = Provider.of<User?>(context, listen: false);
    final googlePhotoUrl = user?.photoURL;

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : ((_currentPhotoUrl ?? googlePhotoUrl) != null
                    ? CachedNetworkImageProvider(
                        (_currentPhotoUrl ?? googlePhotoUrl)!,
                        maxWidth: 200,
                        maxHeight: 200,
                      )
                    : null) as ImageProvider?,
            child: (_selectedImage == null &&
                    _currentPhotoUrl == null &&
                    googlePhotoUrl == null)
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 20,
              child: IconButton(
                icon:
                    const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyEmailField(String email) {
    return TextFormField(
      initialValue: email,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
        filled: true,
        fillColor: Colors.black12,
      ),
      readOnly: true,
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      onChanged: _onUsernameChanged,
      decoration: InputDecoration(
        labelText: 'Username *',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.alternate_email),
        suffixIcon: _buildUsernameSuffix(),
        helperText: 'Must be unique and at least 3 characters',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Username is required';
        if (v.trim().length < 3) return 'Username too short';
        if (_isUsernameAvailable == false) return 'Username already taken';
        return null;
      },
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

  Widget _buildNameField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildDateOfBirthDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        isEmpty: _dateOfBirth == null,
        decoration: InputDecoration(
          labelText: 'Date of Birth (Optional)',
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: const OutlineInputBorder(),
          // Add a clear icon button if a date is selected
          suffixIcon: _dateOfBirth != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _dateOfBirth = null;
                    });
                  },
                )
              : null,
        ),
        child: Text(_formattedDate),
      ),
    );
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

  Widget _buildNationalityAutocomplete(List<Country> countries) {
    return Autocomplete<Country>(
      displayStringForOption: (Country option) => option.name,
      initialValue: TextEditingValue(text: _nationality?.name ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final sortedCountries = List<Country>.from(countries)
          ..sort((a, b) => a.name.compareTo(b.name));

        if (textEditingValue.text.isEmpty) {
          return sortedCountries;
        }
        return sortedCountries.where((Country country) {
          final query = textEditingValue.text.toLowerCase();
          return country.name.toLowerCase().contains(query) ||
              country.searchKeywords
                  .any((k) => k.toLowerCase().contains(query));
        });
      },
      onSelected: (Country selection) {
        setState(() => _nationality = selection);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              width: 300,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final Country option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(option.name),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Clear nationality state if user clears the text field
        controller.addListener(() {
          if (controller.text.isEmpty && _nationality != null) {
            setState(() => _nationality = null);
          }
        });

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Nationality (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.flag),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      setState(() => _nationality = null);
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}

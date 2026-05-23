import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'nrc_model.dart';
import 'nrc_service.dart';

class NrcFormPage extends StatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const NrcFormPage({
    super.key,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<NrcFormPage> createState() => _NrcFormPageState();
}

class _NrcFormPageState extends State<NrcFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isSaving = false;

  final _passportNumberController = TextEditingController();
  final _passportCountryController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _genderController = TextEditingController();
  final _visaNumberController = TextEditingController();
  final _visaTypeController = TextEditingController();
  DateTime? _passportExpiryDate;
  DateTime? _visaExpiryDate;

  final _accommodationNameController = TextEditingController();
  final _accommodationAddressController = TextEditingController();
  final _accommodationCityController = TextEditingController();
  final _accommodationPhoneController = TextEditingController();

  final List<String> _selectedItineraryDays = [];
  Uint8List? _passportImage;
  Uint8List? _visaImage;

  final _itineraryOptions = [
    'Makkah Arrival',
    'Umrah - Day 1',
    'Makkah Stay',
    'Medinah Visit',
    'Makkah Departure',
    'Jeddah Day Trip',
    'Arafah Visit',
    'Mina Stay',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingRegistration();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _passportNumberController.dispose();
    _passportCountryController.dispose();
    _fullNameController.dispose();
    _nationalityController.dispose();
    _birthDateController.dispose();
    _birthPlaceController.dispose();
    _genderController.dispose();
    _visaNumberController.dispose();
    _visaTypeController.dispose();
    _accommodationNameController.dispose();
    _accommodationAddressController.dispose();
    _accommodationCityController.dispose();
    _accommodationPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRegistration() async {
    setState(() => _isLoading = true);
    try {
      final nrc = await NrcService.instance.getCurrentUserNrc();
      if (nrc != null && mounted) {
        _populateForm(nrc);
      }
    } catch (e) {
      debugPrint('Error loading NRC: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateForm(NrcRegistration nrc) {
    _passportNumberController.text = nrc.passportNumber;
    _passportCountryController.text = nrc.passportCountry;
    _fullNameController.text = nrc.fullName;
    _nationalityController.text = nrc.nationality;
    _birthDateController.text = nrc.birthDate;
    _birthPlaceController.text = nrc.birthPlace;
    _genderController.text = nrc.gender;
    _visaNumberController.text = nrc.visaNumber;
    _visaTypeController.text = nrc.visaType;
    _accommodationNameController.text = nrc.accommodationName;
    _accommodationAddressController.text = nrc.accommodationAddress;
    _accommodationCityController.text = nrc.accommodationCity;
    _accommodationPhoneController.text = nrc.accommodationPhone;
    setState(() {
      _selectedItineraryDays.addAll(nrc.itineraryDays);
    });
  }

  Future<void> _pickImage(bool isPassport) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isPassport) {
          _passportImage = bytes;
        } else {
          _visaImage = bytes;
        }
      });
    }
  }

  Future<void> _selectDate(bool isPassportExpiry) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    
    if (date != null) {
      setState(() {
        if (isPassportExpiry) {
          _passportExpiryDate = date;
          _passportExpiryDate = date;
        } else {
          _visaExpiryDate = date;
        }
      });
    }
  }

  void _nextPage() {
    if (_validateCurrentPage()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _validatePassportInfo();
      case 1:
        return _validatePersonalInfo();
      case 2:
        return _validateAccommodationInfo();
      default:
        return true;
    }
  }

  bool _validatePassportInfo() {
    if (_passportNumberController.text.isEmpty) {
      _showError('Nomor paspor diperlukan');
      return false;
    }
    if (_passportCountryController.text.isEmpty) {
      _showError('Negara paspor diperlukan');
      return false;
    }
    if (_passportExpiryDate == null) {
      _showError('Tanggal kedaluwarsa paspor diperlukan');
      return false;
    }
    return true;
  }

  bool _validatePersonalInfo() {
    if (_fullNameController.text.isEmpty) {
      _showError('Nama lengkap diperlukan');
      return false;
    }
    if (_nationalityController.text.isEmpty) {
      _showError('Kewarganegaraan diperlukan');
      return false;
    }
    if (_birthDateController.text.isEmpty) {
      _showError('Tanggal lahir diperlukan');
      return false;
    }
    if (_genderController.text.isEmpty) {
      _showError('Jenis kelamin diperlukan');
      return false;
    }
    return true;
  }

  bool _validateAccommodationInfo() {
    if (_accommodationNameController.text.isEmpty) {
      _showError('Nama akomodasi diperlukan');
      return false;
    }
    if (_accommodationCityController.text.isEmpty) {
      _showError('Kota akomodasi diperlukan');
      return false;
    }
    if (_selectedItineraryDays.isEmpty) {
      _showError('Pilih minimal satu hari itinerary');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    try {
      final registration = _buildRegistration();
      await NrcService.instance.saveDraft(registration);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft tersimpan'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showError('Gagal menyimpan draft: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateCurrentPage()) return;

    setState(() => _isSaving = true);
    try {
      final registration = _buildRegistration();
      final saved = await NrcService.instance.saveDraft(registration);

      if (_passportImage != null) {
        await NrcService.instance.uploadPassportImage(saved.id, _passportImage!);
      }
      if (_visaImage != null) {
        await NrcService.instance.uploadVisaImage(saved.id, _visaImage!);
      }

      await NrcService.instance.submitNrc(saved.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran NRC submitted!'), backgroundColor: Colors.green),
        );
        widget.onComplete?.call();
      }
    } catch (e) {
      _showError('Gagal submit: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  NrcRegistration _buildRegistration() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return NrcRegistration.create(
      userId: user.id,
      passportNumber: _passportNumberController.text,
      passportExpiryDate: _passportExpiryDate?.toIso8601String() ?? '',
      passportCountry: _passportCountryController.text,
      fullName: _fullNameController.text,
      nationality: _nationalityController.text,
      birthDate: _birthDateController.text,
      birthPlace: _birthPlaceController.text,
      gender: _genderController.text,
      visaNumber: _visaNumberController.text,
      visaType: _visaTypeController.text,
      visaExpiryDate: _visaExpiryDate?.toIso8601String() ?? '',
      accommodationName: _accommodationNameController.text,
      accommodationAddress: _accommodationAddressController.text,
      accommodationCity: _accommodationCityController.text,
      accommodationPhone: _accommodationPhoneController.text,
      itineraryDays: _selectedItineraryDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SDAIA NRC Registration'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveDraft,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save Draft', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProgressIndicator(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (page) => setState(() => _currentPage = page),
                      children: [
                        _buildPassportPage(),
                        _buildPersonalPage(),
                        _buildAccommodationPage(),
                        _buildReviewPage(),
                      ],
                    ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressIndicator() {
    final pages = ['Passport', 'Personal', 'Stay', 'Review'];
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(pages.length, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPassportPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Passport Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passportNumberController,
            decoration: const InputDecoration(labelText: 'Passport Number', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passportCountryController,
            decoration: const InputDecoration(labelText: 'Issuing Country', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Expiry Date'),
            subtitle: Text(_passportExpiryDate?.toString().split(' ')[0] ?? 'Select date'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(true),
          ),
          const SizedBox(height: 16),
          _buildImagePicker('Passport Photo', _passportImage, true),
        ],
      ),
    );
  }

  Widget _buildPersonalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full Name (as in passport)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nationalityController,
            decoration: const InputDecoration(labelText: 'Nationality', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _birthDateController,
            decoration: const InputDecoration(labelText: 'Birth Date (YYYY-MM-DD)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _birthPlaceController,
            decoration: const InputDecoration(labelText: 'Birth Place', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _genderController.text.isEmpty ? null : _genderController.text,
            decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
            ],
            onChanged: (value) => _genderController.text = value ?? '',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _visaNumberController,
            decoration: const InputDecoration(labelText: 'Visa Number', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _visaTypeController,
            decoration: const InputDecoration(labelText: 'Visa Type', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Visa Expiry Date'),
            subtitle: Text(_visaExpiryDate?.toString().split(' ')[0] ?? 'Select date'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(false),
          ),
          const SizedBox(height: 16),
          _buildImagePicker('Visa Photo', _visaImage, false),
        ],
      ),
    );
  }

  Widget _buildAccommodationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Accommodation & Itinerary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accommodationNameController,
            decoration: const InputDecoration(labelText: 'Hotel/Accommodation Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accommodationAddressController,
            decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accommodationCityController,
            decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accommodationPhoneController,
            decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          const Text('Itinerary Days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _itineraryOptions.map((day) {
              final isSelected = _selectedItineraryDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedItineraryDays.add(day);
                    } else {
                      _selectedItineraryDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review & Submit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Passport', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Number: ${_passportNumberController.text}'),
                  Text('Country: ${_passportCountryController.text}'),
                  Text('Expiry: ${_passportExpiryDate?.toString().split(' ')[0]}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Name: ${_fullNameController.text}'),
                  Text('Nationality: ${_nationalityController.text}'),
                  Text('Gender: ${_genderController.text}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Accommodation', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Name: ${_accommodationNameController.text}'),
                  Text('City: ${_accommodationCityController.text}'),
                  Text('Itinerary: ${_selectedItineraryDays.join(", ")}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(String label, Uint8List? image, bool isPassport) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        if (image != null)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.memory(image, fit: BoxFit.cover),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _pickImage(isPassport),
          icon: const Icon(Icons.upload),
          label: Text(image != null ? 'Change Photo' : 'Upload Photo'),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                child: const Text('Previous'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == 3 ? _submit : _nextPage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_currentPage == 3 ? 'Submit' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}



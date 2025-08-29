import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UserDetailScreen extends StatefulWidget {
  final Function(Map<String, String>) onContinue;
  const UserDetailScreen({super.key, required this.onContinue});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();
  String? _gender;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Text(
            'Name*',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: 8,
          ),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
              labelStyle: TextStyle(color: Colors.black),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          Text(
            'Gender*',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: _gender == 'Male' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: RadioListTile<String>(
                    activeColor: Colors.black,
                    title: const Text('Male'),
                    value: 'Male',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: _gender == 'Female' ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: RadioListTile<String>(
                    activeColor: Colors.black,
                    title: const Text('Female'),
                    value: 'Female',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_gender == null)
            const Text(
              'Please select your gender',
              style: TextStyle(color: Colors.red),
            ),
          const SizedBox(height: 16.0),
          Text(
            'Date of Birth*',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: 8,
          ),
          TextFormField(
            controller: _dobController,
            decoration: const InputDecoration(
              hintText: 'dd/MM/yyyy',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
              labelStyle: TextStyle(color: Colors.black),
            ),
            keyboardType: TextInputType.datetime,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              DateInputFormatter(),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your date of birth';
              }
              final date = DateFormat('dd/MM/yyyy').parse(value, true);
              final now = DateTime.now();
              final age = now.year - date.year;
              if (age < 13 ||
                  (age == 13 &&
                      now.isBefore(date.add(Duration(days: 365 * 13))))) {
                return 'You must be at least 13 years old';
              }
              return null;
            },
          ),
          const SizedBox(height: 16.0),
          Text(
            'Mobile Number*',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: 8,
          ),
          TextFormField(
            controller: _mobileController,
            decoration: const InputDecoration(
              hintText: '00000 00000',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
              labelStyle: TextStyle(color: Colors.black),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your mobile number';
              }
              if (value.length != 10) {
                return 'Mobile number must be 10 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 35.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate() && _gender != null) {
                  widget.onContinue({
                    'name': _nameController.text,
                    'gender': _gender!,
                    'dob': _dobController.text,
                    'mobile': _mobileController.text,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    text = text.replaceAll(RegExp(r'[^0-9]'), '');
    StringBuffer formattedText = StringBuffer();
    if (text.length > 2) {
      formattedText.write('${text.substring(0, 2)}/');
    } else {
      formattedText.write(text);
    }
    if (text.length > 4) {
      formattedText.write('${text.substring(2, 4)}/');
    } else if (text.length > 2) {
      formattedText.write(text.substring(2));
    }
    if (text.length > 4) {
      formattedText.write(text.substring(4));
    }
    return TextEditingValue(
      text: formattedText.toString(),
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

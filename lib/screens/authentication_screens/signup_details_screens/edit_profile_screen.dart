import 'package:flutter/material.dart';

import '../../../widgets/custom_text_field1.dart';

class EditProfileScreen extends StatefulWidget {
  final Function(Map<String, String>) profileDetails;
  const EditProfileScreen({super.key, required this.profileDetails});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController currentCity = TextEditingController();
  TextEditingController currentPinCode = TextEditingController();
  bool pinCode = false;
  bool isVisible = false;
  String? selectedState;
  List<String> states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Chandigarh',
    'Delhi',
    'Lakshadweep',
    'Puducherry'
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black
                  ),
                  dropdownColor: Colors.white,
                  value: selectedState,
                  onChanged: (String? value) {
                    setState(() {
                      selectedState = value!;
                    });
                  },
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF000000), width: 2),
                    ),
                    floatingLabelStyle:
                    TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
                    labelText: 'Current State*',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: states.map((String state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: CustomTextField1(
                  labelText: 'Current city',
                  hintText: 'e.g: Kolkata',
                  keyboardType: TextInputType.text,
                  text: (p0) => setState(() {
                    currentCity.text = p0;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Current pincode*',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: currentPinCode,
            onChanged: (p0) {
              if (p0.length != 6) {
                setState(() {
                  pinCode = true;
                });
              } else if (p0.length == 6) {
                setState(() {
                  pinCode = false;
                });
              }
            },
            decoration: InputDecoration(
                errorText: pinCode ? 'Please Enter 6 digit pincode' : null,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(0xFFC1272D), width: 1),
                ),
                hintText: '609609',
                floatingLabelBehavior: FloatingLabelBehavior.never,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Color(0xFF808080), width: 2),
                )),
            keyboardType: TextInputType.phone,
          ),
          Visibility(
            visible: isVisible,
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 25.0),
                child: Text(
                  'Required fields are incomplete.\nFill them out to move forward.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (selectedState == null ||
                    currentCity.text.isEmpty ||
                    currentPinCode.text.isEmpty) {
                  if (currentPinCode.text.length != 6) {
                    setState(() {
                      isVisible = true;
                    });
                  }
                } else {
                  setState(() {
                    isVisible = false;
                  });
                  widget.profileDetails(
                      {
                        'state': selectedState!,
                        'city': currentCity.text,
                        'pinCode': currentPinCode.text
                      }
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000000),
                fixedSize: Size(size.width * 0.8, size.height * 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 17, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Privacy Policy",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text('''
Privacy Policy

Effective Date: July 18, 2025

This privacy policy applies to the Joy-a-Bloom app (hereby referred to as "Application") for mobile devices that was created by Sanjay (hereby referred to as "Service Provider") as a Free service. This service is intended for use "AS IS".

Information Collection and Use

The Application collects information when you download and use it. This information may include:

- Your device's Internet Protocol address (e.g., IP address)
- The pages of the Application that you visit, the time and date of your visit, time spent on pages
- The time spent in the Application
- The operating system you use on your mobile device

The Application collects your device's location, which helps the Service Provider determine your approximate geographical location and use it in the following ways:

- Geolocation Services: To provide features like personalized content, relevant recommendations, and location-based services.
- Analytics and Improvements: To analyze user behavior and improve performance and functionality.
- Third-Party Services: Aggregated, anonymized location data may be sent to external services to enhance the Application and optimize offerings.

The Service Provider may use the information you provided to contact you from time to time with important information, notices, and marketing promotions.

For a better experience, while using the Application, the Service Provider may require you to provide personally identifiable information. This information will be retained and used as described in this privacy policy.

Third Party Access

Only aggregated, anonymized data is periodically transmitted to external services to improve the Application and service. The Service Provider may share your information with third parties as described below:

- Google Play Services

The Service Provider may disclose User Provided and Automatically Collected Information:

- As required by law (e.g., subpoena or legal process)
- When disclosure is necessary to protect rights, safety, investigate fraud, or respond to a government request
- With trusted service providers who work on behalf of the Service Provider, under strict privacy agreements

Opt-Out Rights

You can stop all collection of information by uninstalling the Application using the standard uninstall processes from your device or app store.

Data Retention Policy

The Service Provider will retain User Provided data as long as you use the Application and for a reasonable time afterward. You can request deletion of your data by contacting: dev.ersanju@gmail.com.

Children

The Application is not intended for children under 13. The Service Provider does not knowingly collect personal data from children under 13. If such data is discovered, it will be deleted. Parents or guardians should contact the Service Provider to request deletion if necessary.

Security

The Service Provider is committed to safeguarding the confidentiality of your information and uses physical, electronic, and procedural safeguards to protect the data.

Changes

This Privacy Policy may be updated periodically. You are encouraged to review this page for changes. Continued use of the Application is considered acceptance of the changes.

Your Consent

By using the Application, you consent to the processing of your information in accordance with this Privacy Policy, now and as amended.

Contact Us

If you have any questions about this policy or the Application's data practices, please contact:

Email: dev.ersanju@gmail.com
''', style: TextStyle(fontSize: 15, height: 1.5)),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:ephysicsapp/globals/constants.dart';
import 'package:http/http.dart' as http;

class MailServices {

  Future<void> sendEmail({
    required String name,
    required String email,
    required String classDiv,
    required String rollNo,
    required String message,
    List<String>? attachmentUrls,
  }) async {

    final mailtrapToken = mailTrapToken;
    final mailtrapEndpoint = mailTrapHost;

    final htmlBody = """
  <div style="font-family: 'Segoe UI', Roboto, Arial, sans-serif; background:#f4f6f9; color:#333; padding:30px 15px;">
    <div style="background:#fff; border-radius:12px; padding:30px; max-width:620px; margin:auto; box-shadow:0 4px 12px rgba(0,0,0,0.05);">
      <h3 style="color:#2a61b5; font-size:24px; margin-bottom:24px; text-align:center;">New Student Query</h3>
      <p style="font-size:16px; line-height:1.7; margin-bottom:20px;">
        A new query has been raised by <strong>$name</strong>, a student from <strong>$classDiv</strong> (Roll No: <strong>$rollNo</strong>).
        You can reach them at <strong>$email</strong> for further communication.
      </p>
      <p style="font-size:16px; line-height:1.7; margin-bottom:20px;">
        <strong>Message:</strong><br>$message
      </p>
      ${attachmentUrls != null && attachmentUrls.isNotEmpty ? """
      <div style="margin-top:30px; padding-top:15px; border-top:1px solid #e0e0e0;">
        <h3 style="font-size:18px; margin-bottom:10px; color:#2a61b5;">Attachments</h3>
        ${attachmentUrls.map((url) => '<a href="$url" target="_blank" style="display:block; margin-bottom:8px; color:#007BFF; text-decoration:none;">Download File</a>').join()}
      </div>
      """ : ""}
      <div style="text-align:center; margin-top:40px; font-size:13px; color:#999;">
        This is an automated email sent from the Philo Physics Mobile App.
      </div>
    </div>
  </div>
  """;

    final payload = {
      "from": {
        "email": "hello@demomailtrap.co",
        "name": "Philo Physics App"
      },
      "to": [
        {
          "email": "physicsapp.sakec@gmail.com",
          "name": "Support Team"
        }
      ],
      "subject": "New Student Query Submitted",
      "html": htmlBody,
      "category": "StudentQuery"
    };

    final response = await http.post(
      Uri.parse(mailtrapEndpoint),
      headers: {
        "Authorization": "Bearer $mailtrapToken",
        "Content-Type": "application/json"
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 202) {
      print("✅ Email sent successfully");
    } else {
      print("❌ Failed to send email: ${response.statusCode}\n${response.body}");
    }
  }

}


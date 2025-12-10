# Google Cloud Storage (GCS) Setup Guide

This guide will help you set up Google Cloud Storage in your Dreamflow Flutter project to upload files larger than 10GB.

## Overview

Your project now includes:
- ✅ `googleapis` and `googleapis_auth` packages
- ✅ `GCSService` - Service class for interacting with GCS
- ✅ `GCSUploadPage` - UI component for uploading files to GCS

## Setup Steps

### Step 1: Get Your Firebase Project ID

1. Open the [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click the gear icon (⚙️) > Project Settings
4. Copy your **Project ID**

### Step 2: Create a Google Cloud Storage Bucket

1. Open the [Google Cloud Console](https://console.cloud.google.com)
2. Make sure your Firebase project is selected in the project dropdown
3. Navigate to **Storage** > **Cloud Storage** > **Buckets**
4. Click **CREATE BUCKET**
5. Configure your bucket:
   - **Name**: Choose a globally unique name (e.g., `your-app-uploads`)
   - **Location**: Choose a region close to your users
   - **Storage class**: Standard
   - **Access control**: Fine-grained
   - **Protection tools**: Leave defaults
6. Click **CREATE**

### Step 3: Configure Bucket Permissions

#### Option A: Public Access (Simplest)
If you want files to be publicly accessible:

1. Go to your bucket > **Permissions** tab
2. Click **GRANT ACCESS**
3. Add principal: `allUsers`
4. Role: `Storage Object Viewer`
5. Click **SAVE**

#### Option B: Authenticated Access (Recommended)
For secure, authenticated access:

1. Go to your bucket > **Permissions** tab
2. Make sure the Firebase service account has access (should be automatic)
3. Your Firebase Authentication tokens will be used to authenticate uploads

### Step 4: Configure CORS (For Web Apps)

1. Open Cloud Shell in Google Cloud Console (icon in top-right)
2. Create a file called `cors.json`:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "responseHeader": ["Content-Type", "Authorization"],
    "maxAgeSeconds": 3600
  }
]
```

3. Run the command:
```bash
gsutil cors set cors.json gs://YOUR-BUCKET-NAME
```

Replace `YOUR-BUCKET-NAME` with your actual bucket name.

### Step 5: Update Your Flutter Code

Open `lib/services/gcs_service.dart` and update:

```dart
static const String _projectId = 'YOUR_PROJECT_ID'; // Replace with your Firebase project ID
static const String _bucketName = 'YOUR_BUCKET_NAME'; // Replace with your GCS bucket name
```

### Step 6: Set Up Firebase Security Rules (Optional)

If you're also using Firestore to store file metadata, update your security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /documents/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.resource.data.uploadedBy == request.auth.uid;
    }
  }
}
```

## Usage in Your App

### Basic Upload (Files < 100MB)

```dart
import 'package:breakaway365_web/services/gcs_service.dart';

// Upload small file
final downloadUrl = await GCSService.uploadFile(
  fileName: 'my-file.pdf',
  fileBytes: fileBytes,
  contentType: 'application/pdf',
  onProgress: (progress) {
    print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
  },
);

print('File available at: $downloadUrl');
```

### Large File Upload (Files > 100MB, up to 5TB)

```dart
import 'package:breakaway365_web/services/gcs_service.dart';

// Upload large file with stream
final downloadUrl = await GCSService.uploadLargeFile(
  fileName: 'large-video.mp4',
  fileStream: fileStream,
  fileSize: fileSize,
  contentType: 'video/mp4',
  onProgress: (progress) {
    print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
  },
);
```

### Using the Upload Page

Add the GCS Upload page to your navigation:

```dart
import 'package:breakaway365_web/pages/gcs_upload_page.dart';

// Navigate to upload page
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const GCSUploadPage()),
);
```

## File Size Limits

| Storage Solution | Maximum File Size | Best For |
|-----------------|-------------------|----------|
| Firebase Storage | 10GB | Small to medium files |
| Google Cloud Storage | 5TB | Large files, videos, backups |

## Cost Considerations

### Google Cloud Storage Pricing (US Region)
- **Storage**: ~$0.02 per GB per month
- **Upload (ingress)**: Free
- **Download (egress)**: ~$0.12 per GB

### Example Costs:
- Storing 100GB: ~$2/month
- Storing 1TB: ~$20/month

For detailed pricing: [GCS Pricing Calculator](https://cloud.google.com/products/calculator)

## Troubleshooting

### "Permission denied" errors
- Make sure you're authenticated with Firebase Auth
- Check that your bucket permissions are configured correctly
- Verify the service account has Storage Admin role

### CORS errors (Web only)
- Make sure you've configured CORS for your bucket
- The origin in cors.json should match your web app domain

### "Bucket not found" errors
- Double-check the bucket name in `gcs_service.dart`
- Make sure the bucket exists in the same project

### Authentication errors
- Ensure the user is signed in to Firebase Auth
- Check that the Firebase Auth token is valid

## Advanced Features

### Delete Files
```dart
await GCSService.deleteFile('filename.pdf');
```

### List Files
```dart
final files = await GCSService.listFiles(prefix: 'uploads/');
for (final file in files) {
  print('File: ${file.name}, Size: ${file.size}');
}
```

### Get Download URL
```dart
final url = GCSService.getDownloadUrl('filename.pdf');
```

## Security Best Practices

1. **Never expose bucket credentials in client code**
2. **Use Firebase Authentication** to verify user identity
3. **Implement server-side validation** for sensitive operations
4. **Set up lifecycle policies** to auto-delete old files
5. **Monitor usage** in Google Cloud Console to detect abuse

## Next Steps

1. ✅ Complete the setup steps above
2. ✅ Test with a small file first
3. ✅ Test with a large file (>10GB)
4. ✅ Implement in your production workflow
5. ✅ Set up monitoring and alerts in GCP

## Support

- [Google Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dreamflow Support](https://dreamflow.ai/support)

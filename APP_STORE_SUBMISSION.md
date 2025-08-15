# App Store Submission Checklist for Pergamene

## ✅ Prerequisites Completed

- [x] App icons configured (all sizes from 1024x1024 source)
- [x] Launch screen configured (LaunchScreen.storyboard)
- [x] Version set to 1.0.0
- [x] Build number set to 1
- [x] Bundle ID: pm.moonlight.Pergamene
- [x] Minimum iOS version: 15.0
- [x] Category: Books
- [x] Export compliance: No encryption

## 📱 Manual Steps Required

### 1. Apple Developer Account Setup
- [ ] Ensure you have an active Apple Developer account ($99/year)
- [ ] Sign in to App Store Connect: https://appstoreconnect.apple.com

### 2. App Store Connect - Create New App
1. Go to "My Apps" → Click "+" → "New App"
2. Fill in the following:
   - **Platform**: iOS
   - **App Name**: Pergamene
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select "pm.moonlight.Pergamene"
   - **SKU**: pergamene-bible-reader (or any unique identifier)

### 3. App Information Tab
- [ ] **Category**: Books
- [ ] **Content Rights**: Check "No third-party content"
- [ ] **Age Rating**: Complete questionnaire (likely 4+)
   - No objectionable content
   - No violence
   - No mature content

### 4. Pricing and Availability
- [ ] **Price**: Free (or select your pricing tier)
- [ ] **Availability**: Select all countries/regions

### 5. App Store Listing (Prepare these texts)

#### Description
```
Pergamene is a focused Bible reading app featuring the Brenton Septuagint (Old Testament) and Berean Standard Bible (New Testament).

FEATURES:
• Clean, minimalist reading interface
• Brenton Septuagint - Complete Old Testament with Apocrypha
• Berean Standard Bible - Modern, accurate New Testament translation
• Smooth horizontal chapter navigation
• Automatic reading position memory
• Optional verse numbers
• Verse sharing with native iOS share sheet
• Offline reading - no internet required

DESIGNED FOR READERS:
Pergamene removes distractions to help you focus on the text. No ads, no commentary, no study notes - just pure scripture in a beautiful reading environment.

TYPOGRAPHY:
Carefully selected fonts including Cardo for optimal readability and Gothic drop caps that evoke the tradition of illuminated manuscripts.

Perfect for daily reading, study, and meditation. Your reading position is automatically saved and remembered for each chapter.
```

#### Keywords
```
bible, septuagint, berean, scripture, reading, old testament, new testament, apocrypha, offline, minimalist
```

#### What's New (for updates)
```
Version 1.0.0
- Initial release
- Complete Brenton Septuagint (Old Testament)
- Complete Berean Standard Bible (New Testament)
- Chapter navigation and bookmarking
- Verse sharing functionality
```

### 6. Screenshots Required (Use iPhone SE 3rd Gen Simulator)
You need 2-8 screenshots for each device size. Take these screenshots:

1. **Home screen** - Show Genesis 1 with drop cap
2. **Book selection** - Open book selector
3. **New Testament** - Show Matthew 1 or John 1
4. **Settings panel** - Pull down settings showing verse numbers toggle
5. **Verse sharing** - Show verse selection sheet
6. **Different book** - Show Psalms or Proverbs

Required sizes:
- [ ] 6.7" (iPhone 15 Pro Max): 1290 × 2796
- [ ] 6.5" (iPhone 14 Plus): 1284 × 2778 or 1242 × 2688
- [ ] 5.5" (iPhone 8 Plus): 1242 × 2208
- [ ] 6.9" (Optional - iPhone 15 Pro Max): 1320 × 2868

### 7. Build and Archive in Xcode

1. **Set up signing**:
   ```bash
   # In DeveloperConfig.xcconfig, ensure:
   DEVELOPMENT_TEAM = YOUR_TEAM_ID
   ```

2. **Clean and Archive**:
   - Open Xcode
   - Select "Any iOS Device" as destination
   - Product → Clean Build Folder
   - Product → Archive
   - Wait for archive to complete

3. **Upload to App Store Connect**:
   - In Organizer window → Select your archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Choose "Upload"
   - Select automatic signing
   - Upload

### 8. TestFlight (Recommended)
- [ ] After upload, go to TestFlight tab in App Store Connect
- [ ] Add internal testers (your email)
- [ ] Test the app thoroughly on real devices
- [ ] Fix any issues found

### 9. Submit for Review
- [ ] Fill in all required metadata
- [ ] Upload all screenshots
- [ ] Add app preview video (optional)
- [ ] Answer export compliance questions
- [ ] Add notes for reviewer if needed
- [ ] Submit for review

### 10. Privacy Policy & Support
You'll need:
- [ ] **Privacy Policy URL**: Create a simple privacy policy stating you don't collect data
- [ ] **Support URL**: Can be a simple website or GitHub page

Example Privacy Policy:
```
Pergamene Privacy Policy

Pergamene does not collect, store, or transmit any personal information or usage data.
All reading preferences and positions are stored locally on your device only.

The app works completely offline and makes no network requests.

Contact: [your-email]
Last updated: August 11, 2025
```

## 🚀 Build Commands

```bash
# Regenerate project
tuist generate

# Build for release
xcodebuild -workspace Pergamene.xcworkspace \
  -scheme Pergamene \
  -configuration Release \
  -archivePath ./build/Pergamene.xcarchive \
  archive

# Or use Xcode GUI (recommended for first submission)
```

## ⚠️ Common Rejection Reasons to Avoid

1. **Incomplete metadata** - Fill everything out completely
2. **Copyright issues** - We're using public domain texts (Brenton, BSB)
3. **Crashes** - Test thoroughly on real devices
4. **Missing features** - Ensure all advertised features work
5. **Guidelines violations** - Review App Store guidelines

## 📝 Notes

- First review typically takes 24-48 hours
- Have TestFlight build ready before submission
- Consider soft launch in limited countries first
- App Store optimization (ASO) can be improved after launch

## Support Information Needed

Create these before submission:
1. Support email address
2. Simple website or GitHub page for support
3. Privacy policy page (can be GitHub gist)
4. Terms of use (optional for free apps)

## Post-Launch Checklist

- [ ] Monitor crash reports in App Store Connect
- [ ] Respond to user reviews
- [ ] Plan update schedule
- [ ] Set up analytics (optional)
- [ ] Create marketing materials

---

Good luck with your submission! 🎉

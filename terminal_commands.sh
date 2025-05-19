
# Remove existing gradle wrapper
rm -rf android/.gradle
rm -rf android/gradlew
rm -rf android/gradlew.bat
rm -rf android/gradle/

# Create fresh gradle wrapper
cd android
gradle wrapper
cd ..

# Set permissions
chmod +x android/gradlew

# Clean and rebuild
flutter clean
flutter pub get

# Try running with verbose output
flutter run -v

cd android
./gradlew assembleDebug --stacktrace --info

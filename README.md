# MinuteMeet

MinuteMeet is a service that helps groups of people decide on a meeting place by taking into account the real-time locations of all participants. The core idea is to find a centralized, optimal meeting spot that minimizes the overall travel distance for the entire group.

## Features
- **Real-time Location Tracking**: Users' locations are updated periodically and stored securely.
- **Group Creation**: Create a meeting group and invite friends by selecting them from your phone's contacts.
- **Optimal Meeting Spot Calculation**: The backend automatically calculates the geographical centroid (center point) based on the current locations of all group members.
- **Interactive Maps**: View the finalized meeting location and your current position seamlessly via Google Maps integration.
- **Secure Authentication**: Robust token-based authentication using Django REST Framework and Flutter Secure Storage.

## Tech Stack
- **Frontend**: Flutter (Dart) - Uses a premium Material 3 design system.
- **Backend**: Django (Python) & Django REST Framework (DRF)
- **Database**: SQLite (Default) / MongoDB (Planned)
- **Maps**: Google Maps SDK (Flutter) & Geolocation services.

---

## Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0 or higher)
- [Python 3](https://www.python.org/downloads/) (v3.8 or higher)
- [Git](https://git-scm.com/)
- A valid Google Maps API Key (for Android/iOS).

---

### Backend Setup (Django)

1. **Navigate to the backend directory**:
   ```bash
   cd backend/minutemeet
   ```

2. **Create and activate a virtual environment**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows use `venv\Scripts\activate`
   ```

3. **Install the required dependencies**:
   ```bash
   pip install django djangorestframework django-cors-headers python-dotenv
   ```

4. **Environment Variables**:
   Create a `.env` file in `backend/minutemeet/minutemeet/.env` and add your Google Maps API Key:
   ```env
   GOOGLE_MAPS_API_KEY=your_actual_api_key_here
   ```

5. **Run Migrations**:
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

6. **Start the Django Development Server**:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```
   The backend will now be running at `http://127.0.0.1:8000`.

---

### Frontend Setup (Flutter)

1. **Navigate to the frontend directory**:
   ```bash
   cd frontend
   ```

2. **Fetch Flutter Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API Base URL**:
   The app automatically detects if it's running on an Android Emulator (`10.0.2.2`) or Web/iOS (`127.0.0.1`). If you are deploying to a physical device, update the IP address in `lib/core/constants.dart` to match your computer's local network IP address (e.g., `192.168.x.x`).

4. **Configure Google Maps API Key**:
   - **Android**: Open `android/app/src/main/AndroidManifest.xml` and insert your API key in the `<meta-data>` tag for `com.google.android.geo.API_KEY`.
   - **iOS**: Open `ios/Runner/AppDelegate.swift` and provide your API key to the `GMSServices` instance.

5. **Run the App**:
   ```bash
   flutter run
   ```

---

## Future Roadmap
- Integration with Places API (Restaurant reviews, ratings, menus).
- Factor in traffic conditions and public transit for accurate travel times.
- Accessibility preferences (e.g., wheelchair-accessible meeting spots).

## License
This project is open-source and available under the MIT License.

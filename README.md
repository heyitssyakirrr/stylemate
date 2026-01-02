# StyleMate (AURA FIT) 👗👔

**StyleMate** is an intelligent digital wardrobe application designed to help users organize their closet and discover new outfit combinations using Artificial Intelligence. 

Built with **Flutter** and **Supabase**, it leverages on-device Machine Learning (TensorFlow Lite) to analyze clothing items and uses Edge Functions to generate harmonized outfit recommendations based on visual similarity and real-time weather conditions.

## 🚀 Key Features

- **📱 Digital Closet**: Upload and organize your wardrobe. The app automatically classifies items and extracts visual features using a custom MobileNet-based TFLite model.
- **✨ AI Outfit Recommender**: Generates outfit suggestions using **Cosine Similarity** on feature embeddings to ensure visual harmony.
- **☁️ Weather Adaptive**: Fetches real-time local weather data (via Geolocator) to suggest season-appropriate looks (e.g., no winter jackets in summer).
- **🎨 Smart Filtering**: Constraints-based styling engine that respects occasion (Usage), season, and color preferences.
- **📊 Analytics**: Track your style journey and most-worn items (implied feature).
- **🔔 Daily Updates**: Local notifications to remind you of your daily look.

## 🛠️ Tech Stack

### Mobile App (Flutter)
- **Framework**: Flutter SDK 3.7+
- **State Management**: Provider / Controllers pattern
- **ML Engine**: `tflite_flutter` (On-device inference)
- **Backend Service**: `supabase_flutter` (Auth, Database, Realtime)
- **Location**: `geolocator` (For weather data)

### Backend (Supabase)
- **Database**: PostgreSQL (Stores user data and clothing metadata)
- **Edge Functions**: Deno / TypeScript (Handles the heavy lifting for outfit recommendation logic)
- **Auth**: Secure email and password authentication

## 🧠 How It Works

1. **Ingestion**: When you upload an image, `MLService` runs a TFLite model to extract a 2048-dimensional embedding vector and classify tags.
2. **Storage**: The image and its metadata (including the vector) are stored in Supabase.
3. **Recommendation**: 
   - The app sends a request to the `outfit-recommender` Edge Function.
   - The function retrieves your closet items and filters them based on dynamic constraints (Weather, Occasion).
   - It calculates a **Harmony Score** by computing the cosine similarity between item embeddings.
   - It validates compatibility (e.g., ensuring you don't mix "Sports" with "Formal" wear).
   - The best-scoring outfit is returned to the user.

## 📸 Screenshots

| Home Screen | Virtual Closet | Outfit Results |
|:---:|:---:|:---:|
| | | |

## 📦 Getting Started

### Prerequisites
- Flutter SDK installed
- Supabase project set up

### Installation

1. **Clone the repository**
   ```bash
   git clone [https://github.com/heyitssyakirrr/stylemate.git](https://github.com/heyitssyakirrr/stylemate.git)
   cd stylemate

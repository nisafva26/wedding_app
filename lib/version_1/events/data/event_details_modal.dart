import 'package:flutter/material.dart';

// ---------------- Models (same as before, trimmed) ----------------

class EventDetailsContent {
  final EventDetailsSection details;
  final OutfitInspirationSection outfit;
  final EventFlowSection flow;

  const EventDetailsContent({
    required this.details,
    required this.outfit,
    required this.flow,
  });
}

class EventDetailsSection {
  final String headline;
  final String description;
  final LocationSection location;
  final WeatherSection? weather;
  final List<AmenityItem> amenities;
  final Color mainColor;
  final Color detailsColor;

  final Color outfitSectionColor;
  final Color eventFlowSectionColor;

  final Color timePrimaryColor;
  final Color timeSecondaryColor;

  const EventDetailsSection({
    required this.headline,
    required this.description,
    required this.location,
    this.weather,
    this.amenities = const [],
    required this.mainColor,
    required this.detailsColor,
    required this.outfitSectionColor,
    required this.eventFlowSectionColor,
    required this.timePrimaryColor,
    required this.timeSecondaryColor,
  });
}

class LocationSection {
  final String title;
  final String subtitle;
  final String imageUrl;
  final int? distanceKm;
  final String? etaText;

  const LocationSection({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.distanceKm,
    this.etaText,
  });
}

class WeatherSection {
  final String label;
  final String temperatureText;
  final IconData icon;

  const WeatherSection({
    this.label = "THE WEATHER ON THE DAY",
    required this.temperatureText,
    required this.icon,
  });
}

class AmenityItem {
  final IconData icon;
  final String text;

  const AmenityItem({required this.icon, required this.text});
}

class OutfitInspirationSection {
  final String title;
  final String headline;
  final String description;
  final List<String> carouselImageUrls;
  final List<OutfitCategoryCard> categories;

  const OutfitInspirationSection({
    required this.title,
    required this.headline,
    required this.description,
    required this.carouselImageUrls,
    required this.categories,
  });
}

class OutfitCategoryCard {
  final String title;
  final String imageUrl;

  const OutfitCategoryCard({required this.title, required this.imageUrl});
}

class EventFlowStep {
  final String timeRange; // "5:00 PM - 6:00 PM"
  final String title; // "Guest Arrival +\nSnacks & chai"
  final IconData icon; // right-side icon

  const EventFlowStep({
    required this.timeRange,
    required this.title,
    required this.icon,
  });
}

class EventFlowSection {
  final String title;
  final List<EventFlowStep> steps;

  const EventFlowSection({required this.title, required this.steps});
}

// ---------------- Registry ----------------

String _keyFromTitle(String title) =>
    title.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

class EventContentRegistry {
  static EventDetailsContent forTitle(String eventTitle) {
    final k = _keyFromTitle(eventTitle);

    // fallback (so app never crashes)
    return _map[k] ?? _default(eventTitle);
  }

  static EventDetailsContent _default(String eventTitle) {
    return EventDetailsContent(
      details: EventDetailsSection(
        headline: "Details coming soon.",
        description: "We’ll update this section shortly.",
        location: const LocationSection(
          title: "-",
          subtitle: "-",
          imageUrl:
              "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=1400",
        ),
        weather: const WeatherSection(
          temperatureText: "--",
          icon: Icons.device_thermostat,
        ),
        amenities: const [],
        mainColor: Color(0xff771549),
        detailsColor: Color(0xffFFECF6),
        outfitSectionColor: Color(0xffF3FFDA),
        eventFlowSectionColor: Color(0xffFFECF6),
        timePrimaryColor: Color(0xff97195C),
        timeSecondaryColor: Color(0xffB4226F),
      ),
      outfit: OutfitInspirationSection(
        title: "Outfit inspiration",
        headline: "Wear what feels like you.",
        description: "Outfit guidance will be added soon.",
        carouselImageUrls: const [
          "https://images.unsplash.com/photo-1520975910444-8b3b4a3b3e20?w=1400",
        ],
        categories: const [
          OutfitCategoryCard(
            title: "Women",
            imageUrl:
                "https://images.unsplash.com/photo-1520975776293-3c6f4a7c7c43?w=900",
          ),
          OutfitCategoryCard(
            title: "Men",
            imageUrl:
                "https://images.unsplash.com/photo-1520975683241-54f3c4a6a2d0?w=900",
          ),
          OutfitCategoryCard(
            title: "Kids",
            imageUrl:
                "https://images.unsplash.com/photo-1520975631221-5c2a1e0a1f4a?w=900",
          ),
        ],
      ),
      flow: const EventFlowSection(
        title: "Event flow",
        steps: const [
          EventFlowStep(
            timeRange: "5:00 PM - 6:00 PM",
            title: "Guest Arrival +\nSnacks & chai",
            icon: Icons.local_cafe_outlined,
          ),
          EventFlowStep(
            timeRange: "6:00 PM - 7:00 PM",
            title: "Groom & bride entry +\nMehendi Moments",
            icon: Icons.front_hand_outlined,
          ),
          EventFlowStep(
            timeRange: "7:00 PM - 8:00 PM",
            title: "Dances\n& games",
            icon: Icons.emoji_emotions_outlined,
          ),
          EventFlowStep(
            timeRange: "8:00 PM - 9:00 PM",
            title: "Dinner",
            icon: Icons.restaurant_outlined,
          ),
          EventFlowStep(
            timeRange: "9:00 PM onwards",
            title: "DJ + dancing",
            icon: Icons.music_note_outlined,
          ),
        ],
      ),
    );
  }

  // ✅ Put your 3 events here (keyed by title)
  static final Map<String, EventDetailsContent> _map = {
    "mehendi": _mehendi(),
    "nikkah": _nikkah(),
    "reception": _reception(),
  };

  static EventDetailsContent _mehendi() {
    return EventDetailsContent(
      details: EventDetailsSection(
        headline: "A cozy mehendi night\nwith our closest people.",
        description:
            "Traditionally, the ladies apply mehendi and yes, you can add a little mehendi for the bride and groom too.",
        location: const LocationSection(
          title: "Levant Park",
          subtitle:
              "AlRuwayyah 3 - After Dubai Government Workshop. UAE, Dubai",
          imageUrl:
              "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=1400",
          distanceKm: 21,
          etaText: "1 hr 15 m away",
        ),
        weather: const WeatherSection(
          temperatureText: "15°C",
          icon: Icons.device_thermostat,
        ),
        timePrimaryColor: Color(0xff97195C),
        timeSecondaryColor: Color(0xffB4226F),
        mainColor: Color(0xff771549),
        detailsColor: Color(0xffFFECF6),
        outfitSectionColor: Color(0xffF3FFDA),
        eventFlowSectionColor: Color(0xffFFECF6),
        amenities: const [
          AmenityItem(icon: Icons.local_parking, text: "On-site parking"),
          AmenityItem(icon: Icons.child_friendly, text: "Kids play area"),
          AmenityItem(icon: Icons.pets, text: "Petting farm"),
          AmenityItem(icon: Icons.mosque, text: "Prayer area"),
        ],
      ),
      outfit: OutfitInspirationSection(
        title: "Outfit inspiration",
        headline: "Go bright, comfy, and\nready to move.",
        description:
            "Totally optional. Wear what feels like you.\n\nThink festive, playful, and photo-ready: bright colors, fun prints, and easy silhouettes that you can actually move in.",
        carouselImageUrls: const [
          "https://s.alicdn.com/@sc04/kf/A98035f6fffd941b5aba5eba4ea09b6c8H/New-Arrivals-Latest-Fashion-Elegant-Wedding-Party-Wear-Dresses-Women-Handmade-Henna-Brides-Indian-Pakistani-Lehenga-Choli.jpg",
          "https://cdn.shopify.com/s/files/1/0575/8851/4992/files/2_2f6e3816-5b6b-42a6-b29f-c28518f46aff.jpg?v=1728640189",
        ],
        categories: const [
          OutfitCategoryCard(
            title: "Women",
            imageUrl: "assets/images/outfit_women.png",
          ),
          OutfitCategoryCard(
            title: "Men",
            imageUrl: "assets/images/outfit_men.png",
          ),
          OutfitCategoryCard(
            title: "Kids",
            imageUrl: "assets/images/outfit_kid.png",
          ),
        ],
      ),
      flow: const EventFlowSection(
        title: "Event flow",
        steps: const [
          EventFlowStep(
            timeRange: "5:00 PM - 6:00 PM",
            title: "Guest Arrival +\nSnacks & chai",
            icon: Icons.local_cafe_outlined,
          ),
          EventFlowStep(
            timeRange: "6:00 PM - 7:00 PM",
            title: "Groom & bride entry +\nMehendi Moments",
            icon: Icons.front_hand_outlined,
          ),
          EventFlowStep(
            timeRange: "7:00 PM - 8:00 PM",
            title: "Dances\n& games",
            icon: Icons.emoji_emotions_outlined,
          ),
          EventFlowStep(
            timeRange: "8:00 PM - 9:00 PM",
            title: "Dinner",
            icon: Icons.restaurant_outlined,
          ),
          EventFlowStep(
            timeRange: "9:00 PM onwards",
            title: "DJ + dancing",
            icon: Icons.music_note_outlined,
          ),
        ],
      ),
    );
  }

  static EventDetailsContent _nikkah() {
    return EventDetailsContent(
      details: EventDetailsSection(
        headline: "A quiet, beautiful ceremony with our nearest and dearest.",
        description:
            "The main ceremony - calm, meaningful, and beautiful. Come a little early, settle in, and enjoy the island setting. ",
        location: const LocationSection(
          title: "Noor Island",
          subtitle:
              "Buhairah Corniche Road, Khalid Lagoon - Sharjah, United Arab Emirates",
          imageUrl:
              "https://res.klook.com/images/fl_lossy.progressive,q_65/c_fill,w_1200,h_630/w_80,x_15,y_15,g_south_west,l_Klook_water_br_trans_yhcmh3/activities/u9bgxo2shrgorwqrtg22/AlNoorIslandAdmissioninSharjah-KlookIndia.jpg",
          distanceKm: 12,
          etaText: "35 m away",
        ),
        timePrimaryColor: Color(0xff76450F),
        timeSecondaryColor: Color(0xff8D5F2D),
        weather: const WeatherSection(
          temperatureText: "18°C",
          icon: Icons.nights_stay_outlined,
        ),
        mainColor: Color(0xff5F3406),
        detailsColor: Color(0xffFFECD7),
        outfitSectionColor: Color(0xffFFECD7),
        eventFlowSectionColor: Color(0xffFFECD7),

        amenities: const [
          AmenityItem(icon: Icons.local_parking, text: "Paid parking on site"),
          AmenityItem(icon: Icons.child_friendly, text: "Kids play area"),
          AmenityItem(icon: Icons.pets, text: "Petting farm"),
          AmenityItem(
            icon: Icons.mosque, // best semantic match for prayer area
            text: "Prayer area",
          ),
          AmenityItem(icon: Icons.local_florist, text: "Butterfly garden"),
        ],
      ),

      outfit: OutfitInspirationSection(
        title: "Outfit inspiration",
        headline: "Sparkle a little.\nDance a lot.",
        description:
            "Festive fits encouraged. Choose something photo-ready and easy to dance in.",
        carouselImageUrls: const [
          "https://images.unsplash.com/photo-1520975869013-5c9c8b6d8c25?w=1400",
          "https://images.unsplash.com/photo-1520975958225-1f8b78f2f13c?w=1400",
        ],
        categories: const [
          OutfitCategoryCard(
            title: "Women",
            imageUrl: "assets/images/outfit_women.png",
          ),
          OutfitCategoryCard(
            title: "Men",
            imageUrl: "assets/images/outfit_men.png",
          ),
          OutfitCategoryCard(
            title: "Kids",
            imageUrl: "assets/images/outfit_kid.png",
          ),
        ],
      ),
      flow: const EventFlowSection(
        title: "Event flow",
        steps: const [
          EventFlowStep(
            timeRange: "5:00 PM - 6:00 PM",
            title: "Guest Arrival +\nSnacks & chai",
            icon: Icons.local_cafe_outlined,
          ),
          EventFlowStep(
            timeRange: "6:00 PM - 7:00 PM",
            title: "Groom & bride entry +\nMehendi Moments",
            icon: Icons.front_hand_outlined,
          ),
          EventFlowStep(
            timeRange: "7:00 PM - 8:00 PM",
            title: "Dances\n& games",
            icon: Icons.emoji_emotions_outlined,
          ),
          EventFlowStep(
            timeRange: "8:00 PM - 9:00 PM",
            title: "Dinner",
            icon: Icons.restaurant_outlined,
          ),
          EventFlowStep(
            timeRange: "9:00 PM onwards",
            title: "DJ + dancing",
            icon: Icons.music_note_outlined,
          ),
        ],
      ),
    );
  }

  static EventDetailsContent _reception() {
    return EventDetailsContent(
      details: EventDetailsSection(
        headline: "This is the\n party night",
        description:
            "Polished, lively, and full celebration mode. Come ready for photos, good food, and a proper dance floor later.",
        location: const LocationSection(
          title: "Hyatt Regency Dubai",
          subtitle: "Al Khaleej St - Al Corniche -\nDeira - Dubai",
          imageUrl:
              "https://images.destination2.co.uk/Hotels/giata/485037/Hyatt%20Regency%20Dubai%20_%20The%20Galleria%20Residence_1.jpg",
          distanceKm: 28,
          etaText: "1 hr 05 m away",
        ),
        mainColor: Color(0xff045622),
        detailsColor: Color(0xffDCFFE9),
        outfitSectionColor: Color(0xffDCFFE9),
        eventFlowSectionColor: Color(0xffDCFFE9),
        timePrimaryColor: Color(0xff04471D),
        timeSecondaryColor: Color(0xff0C7632),
        weather: const WeatherSection(
          temperatureText: "20°C",
          icon: Icons.wb_sunny_outlined,
        ),
        amenities: const [
          AmenityItem(icon: Icons.local_parking, text: "Parking"),
          AmenityItem(icon: Icons.mosque, text: "Prayer area"),
        ],
      ),
      outfit: OutfitInspirationSection(
        title: "Outfit inspiration",
        headline: "Classic. Elegant.\nWedding-ready.",
        description:
            "Traditional wear suggested. Keep it comfortable for a long ceremony and photos.",
        carouselImageUrls: const [
          "https://images.unsplash.com/photo-1529636798458-92182e662485?w=1400",
          "https://images.unsplash.com/photo-1519741497674-611481863552?w=1400",
        ],
        categories: const [
          OutfitCategoryCard(
            title: "Women",
            imageUrl: "assets/images/outfit_women.png",
          ),
          OutfitCategoryCard(
            title: "Men",
            imageUrl: "assets/images/outfit_men.png",
          ),
          OutfitCategoryCard(
            title: "Kids",
            imageUrl: "assets/images/outfit_kid.png",
          ),
        ],
      ),
      flow: const EventFlowSection(
        title: "Event flow",
        steps: const [
          EventFlowStep(
            timeRange: "6:00 PM - 6:45 PM",
            title: "Guest arrivals +\nwelcome drinks",
            icon: Icons.local_cafe_outlined,
          ),
          EventFlowStep(
            timeRange: "6:45 PM - 7:15 PM",
            title: "Couple entry +\nsettle in",
            icon: Icons.weekend_outlined,
          ),
          EventFlowStep(
            timeRange: "7:15 PM - 7:45 PM",
            title: "Cake cutting +\nspeeches",
            icon: Icons.cake_outlined,
          ),
          EventFlowStep(
            timeRange: "7:45 PM - 8:30 PM",
            title: "Photos with\nthe couple",
            icon: Icons.camera_alt_outlined,
          ),
          EventFlowStep(
            timeRange: "8:30 PM - 9:30 PM",
            title: "Dinner\nservice",
            icon: Icons.restaurant_outlined,
          ),
          EventFlowStep(
            timeRange: "6:00 PM - 8:30 PM",
            title: "Dancing, entertainment\n& celebration",
            icon: Icons.music_note_outlined,
          ),
        ],
      ),
    );
  }
}

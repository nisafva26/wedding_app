import 'package:flutter/material.dart';

enum OutfitEventTab { mehendi, nikkah, reception }

String outfitTabLabel(OutfitEventTab t) => switch (t) {
  OutfitEventTab.mehendi => "Mehendi",
  OutfitEventTab.nikkah => "Nikkah",
  OutfitEventTab.reception => "Reception",
};

class OutfitDetailsContent {
  final Color pageBg; // mint background
  final Color selectedTabColor; // maroon-ish for selected
  final Color unselectedTabColor; // faded

  final Color introCardColor;
  final Color introCardColorMen;
  final Color introCardColorKid;
  final String introHeadline;
  final String introSubBold;
  final String introBody;

  final WeatherCardData weather;

  final String colorsTitle;
  final List<ColorChipData> colors;

  final String inspirationsTitle;
  final List<String> inspirationImageAssetsWomen; // or URLs
  final List<String> inspirationImageAssetsMen; // or URLs
  final List<String> inspirationImageAssetsKids; // or URLs

  const OutfitDetailsContent({
    required this.pageBg,
    required this.selectedTabColor,
    required this.unselectedTabColor,
    required this.introCardColor,
    required this.introHeadline,
    required this.introSubBold,
    required this.introBody,
    required this.weather,
    required this.colorsTitle,
    required this.colors,
    required this.inspirationsTitle,

    required this.introCardColorMen,
    required this.introCardColorKid,
    required this.inspirationImageAssetsWomen,
    required this.inspirationImageAssetsMen,
    required this.inspirationImageAssetsKids,
  });
}

class WeatherCardData {
  final List<Color> gradient; // 2 colors
  final String label;
  final String temperature;
  final String note;
  final IconData icon;
  final Color weatherColorWomen;
  final Color weatherColorMen;
  final Color weatherColorKid;

  const WeatherCardData({
    required this.gradient,
    required this.label,
    required this.temperature,
    required this.note,
    required this.icon,
    required this.weatherColorWomen,
    required this.weatherColorMen,
    required this.weatherColorKid,
  });
}

class ColorChipData {
  final String name;
  final Color color;

  const ColorChipData(this.name, this.color);
}

// ✅ Local registry (3 events)
class OutfitDetailsRegistry {
  static OutfitDetailsContent forTab(OutfitEventTab t) {
    return switch (t) {
      OutfitEventTab.mehendi => _mehendi,
      OutfitEventTab.nikkah => _nikkah,
      OutfitEventTab.reception => _reception,
    };
  }

  static const _baseBg = Color(0xFFE9FFF3);

  static const OutfitDetailsContent _mehendi = OutfitDetailsContent(
    pageBg: _baseBg,
    selectedTabColor: Color(0xFF6B1842),
    unselectedTabColor: Color(0x336B1842),
    introCardColor: Color(0xFFF6DDE8),
    introHeadline: "Go bright, comfy, and\nready to move.",
    introSubBold: "Totally optional. Wear what feels like you.",
    introBody:
        "Think festive, playful, and photo-ready: bright colors, fun prints, and easy silhouettes that you can actually move in.",
    weather: WeatherCardData(
      gradient: [Color(0xFF7A0F44), Color(0xFFB21B64)],
      label: "THE WEATHER",
      temperature: "15°C",
      note: "This event is outdoors. Please carry a jacket, shawl, or stole.",
      icon: Icons.calendar_month_outlined,
      weatherColorWomen: Color(0xff771549),
      weatherColorMen: Color(0xff06471D),
      weatherColorKid: Color(0xff06471D),
    ),
    colorsTitle: "The colors",
    colors: [
      ColorChipData("Marigold", Color(0xFFF4C542)),
      ColorChipData("Coral", Color(0xFFFF6B6B)),
      ColorChipData("Fuchsia", Color(0xFFE11D74)),
      ColorChipData("Teal", Color(0xFF1FA7A8)),
      ColorChipData("Emerald", Color(0xFF1F8A4C)),
    ],
    inspirationsTitle: "Outfit inspirations",
    inspirationImageAssetsWomen: [
      "https://i.pinimg.com/1200x/bd/98/60/bd9860e1422646ff2f4dd8f4ada5612e.jpg",

      "https://i.pinimg.com/736x/c7/6a/22/c76a22d6ebc1b6b4df088e6f03638336.jpg",
      "https://i.pinimg.com/736x/15/19/8f/15198f718976acda66ddf83df25c53df.jpg",
      "https://i.pinimg.com/736x/36/94/fe/3694fe40893d5b6d7e70961afd74bb1e.jpg",
      "https://i.pinimg.com/1200x/04/c7/d3/04c7d3e2eac8b6a77de4fae807c62b8b.jpg",
      "https://i.pinimg.com/736x/e3/ca/1f/e3ca1fffa50a7dd38303e068b395df29.jpg",
    ],
    inspirationImageAssetsMen: [
      "https://i.pinimg.com/736x/2f/ac/9a/2fac9a7b3fa8903e62c7777ff5169d2d.jpg",
      "https://i.pinimg.com/736x/f8/1f/0e/f81f0e5b980dce69fc1aa584c32a0215.jpg",
      "https://i.pinimg.com/736x/3e/80/ee/3e80ee73b01cec7364e92750cdb5a45c.jpg",
      "https://i.pinimg.com/736x/be/80/84/be80849e8c7a98d60489bc066e614042.jpg",
      "https://i.pinimg.com/1200x/a3/f0/5e/a3f05e4c82f4c76b8c2682c5c211b09a.jpg",
      "https://i.pinimg.com/1200x/63/f4/bd/63f4bd22c2380798084bd68139062bd8.jpg",
    ],
    inspirationImageAssetsKids: [
      "https://i.pinimg.com/1200x/96/57/25/965725de04e73a73060beaaca34a3d58.jpg",
      "https://i.pinimg.com/1200x/e8/b7/9f/e8b79f0f77ba5d7254756f60345f5caf.jpg",
      'https://i.pinimg.com/1200x/4e/df/eb/4edfeb1ecdc974eac5ac858075ded6f0.jpg',
      "https://i.pinimg.com/736x/c9/e3/1e/c9e31ea69d347ebee2c94fbe4120b86f.jpg",
    ],
    introCardColorMen: Color(0xffE2EFC6),
    introCardColorKid: Color(0xffE2EFC6),
  );

  static const OutfitDetailsContent _nikkah = OutfitDetailsContent(
    pageBg: _baseBg,
    selectedTabColor: Color(0xFF6B1842),
    unselectedTabColor: Color(0x336B1842),
    introCardColor: Color(0xFFE6F1C9),

    introHeadline: "A quiet, beautiful ceremony with our nearest and dearest.",
    introSubBold: "Keep it timeless. Comfort matters.",
    introBody:
        "Think clean silhouettes, minimal shine, and polished tones . Choose something you’ll feel confident in for photos.",
    weather: WeatherCardData(
      gradient: [Color(0xFF0B3E23), Color(0xFF0F5A30)],
      label: "THE WEATHER",
      temperature: "18°C",
      note:
          "Evening can get breezy. Carry a light jacket\nif you get cold easily.",
      icon: Icons.calendar_month_outlined,
      weatherColorWomen: Color(0xff771549),
      weatherColorMen: Color(0xff06471D),
      weatherColorKid: Color(0xff06471D),
    ),
    colorsTitle: "The colors",
    colors: [
      ColorChipData("Ivory", Color(0xFFF4F1E8)),
      ColorChipData("Rose", Color(0xFFE9A7B7)),
      ColorChipData("Sage", Color(0xFF7BAE8E)),
      ColorChipData("Gold", Color(0xFFD4AF37)),
      ColorChipData("Black", Color(0xFF1B1B1B)),
    ],
    inspirationsTitle: "Outfit inspirations",
    inspirationImageAssetsWomen: [
      "https://s.alicdn.com/@sc04/kf/A98035f6fffd941b5aba5eba4ea09b6c8H/New-Arrivals-Latest-Fashion-Elegant-Wedding-Party-Wear-Dresses-Women-Handmade-Henna-Brides-Indian-Pakistani-Lehenga-Choli.jpg",

      "https://cdn.shopify.com/s/files/1/0575/8851/4992/files/2_2f6e3816-5b6b-42a6-b29f-c28518f46aff.jpg?v=1728640189",
      "https://s.alicdn.com/@sc04/kf/A98035f6fffd941b5aba5eba4ea09b6c8H/New-Arrivals-Latest-Fashion-Elegant-Wedding-Party-Wear-Dresses-Women-Handmade-Henna-Brides-Indian-Pakistani-Lehenga-Choli.jpg",
      "https://cdn.shopify.com/s/files/1/0575/8851/4992/files/2_2f6e3816-5b6b-42a6-b29f-c28518f46aff.jpg?v=1728640189",
    ],
    inspirationImageAssetsMen: [
      "https://i.pinimg.com/736x/e4/f8/04/e4f80415025c625033df85f247a1343f.jpg",
      "https://i.pinimg.com/1200x/b2/be/81/b2be8140b0b0feb63133bd2823bc3e00.jpg",
      "https://i.pinimg.com/736x/30/7d/95/307d9582904a9a9136c2fd47092615bf.jpg",
      "https://i.pinimg.com/736x/4f/d4/4e/4fd44ee6a3bbc74583b7f988cb251216.jpg",
      "https://i.pinimg.com/1200x/5f/e5/24/5fe5245758554def104dd68ba928c24b.jpg",
      "https://i.pinimg.com/1200x/f2/a7/0b/f2a70b4c20dae6290cee7be92f6a2972.jpg",
      "https://i.pinimg.com/736x/e7/35/00/e73500f3c991720b4e72254adc0a5b8e.jpg",
    ],
    inspirationImageAssetsKids: [
      "https://s.alicdn.com/@sc04/kf/A98035f6fffd941b5aba5eba4ea09b6c8H/New-Arrivals-Latest-Fashion-Elegant-Wedding-Party-Wear-Dresses-Women-Handmade-Henna-Brides-Indian-Pakistani-Lehenga-Choli.jpg",

      "https://cdn.shopify.com/s/files/1/0575/8851/4992/files/2_2f6e3816-5b6b-42a6-b29f-c28518f46aff.jpg?v=1728640189",
      "https://s.alicdn.com/@sc04/kf/A98035f6fffd941b5aba5eba4ea09b6c8H/New-Arrivals-Latest-Fashion-Elegant-Wedding-Party-Wear-Dresses-Women-Handmade-Henna-Brides-Indian-Pakistani-Lehenga-Choli.jpg",
      "https://cdn.shopify.com/s/files/1/0575/8851/4992/files/2_2f6e3816-5b6b-42a6-b29f-c28518f46aff.jpg?v=1728640189",
    ],
    introCardColorMen: Color(0xffE2EFC6),
    introCardColorKid: Color(0xffE2EFC6),
  );

  static const OutfitDetailsContent _reception = OutfitDetailsContent(
    pageBg: _baseBg,
    selectedTabColor: Color(0xFF6B1842),
    unselectedTabColor: Color(0x336B1842),
    introCardColor: Color(0xFFF6DDE8),
    introHeadline: "Dress up.\nGo a little glam.",
    introSubBold: "Reception is the moment ✨",
    introBody:
        "Bring your best look—structured fits, rich colors, and details\nthat pop under lights and cameras.",
    weather: WeatherCardData(
      gradient: [Color(0xFF2B0C1E), Color(0xFF7A0F44)],
      label: "THE WEATHER",
      temperature: "20°C",
      note: "Mostly indoors. A light layer is enough.",
      icon: Icons.calendar_month_outlined,
      weatherColorWomen: Color(0xff771549),
      weatherColorMen: Color(0xff06471D),
      weatherColorKid: Color(0xff06471D),
    ),
    colorsTitle: "The colors",
    colors: [
      ColorChipData("Burgundy", Color(0xFF6B1842)),
      ColorChipData("Champagne", Color(0xFFE7D7B8)),
      ColorChipData("Navy", Color(0xFF0B1F3A)),
      ColorChipData("Silver", Color(0xFFBFC7D5)),
      ColorChipData("Emerald", Color(0xFF1F8A4C)),
    ],
    inspirationsTitle: "Outfit inspirations",
    inspirationImageAssetsWomen: [
      "https://s.alicdn.com/@sc04/kf/A98035f6fffd941b5aba5eba4ea09b6c8H/New-Arrivals-Latest-Fashion-Elegant-Wedding-Party-Wear-Dresses-Women-Handmade-Henna-Brides-Indian-Pakistani-Lehenga-Choli.jpg",

      "https://cdn.shopify.com/s/files/1/0575/8851/4992/files/2_2f6e3816-5b6b-42a6-b29f-c28518f46aff.jpg?v=1728640189",
      "https://s.alicdn.com/@sc04/kf/A98035f6fffd941b5aba5eba4ea09b6c8H/New-Arrivals-Latest-Fashion-Elegant-Wedding-Party-Wear-Dresses-Women-Handmade-Henna-Brides-Indian-Pakistani-Lehenga-Choli.jpg",
      "https://cdn.shopify.com/s/files/1/0575/8851/4992/files/2_2f6e3816-5b6b-42a6-b29f-c28518f46aff.jpg?v=1728640189",
    ],
    inspirationImageAssetsMen: [
      "https://s.alicdn.com/@sc04/kf/A98035f6fffd941b5aba5eba4ea09b6c8H/New-Arrivals-Latest-Fashion-Elegant-Wedding-Party-Wear-Dresses-Women-Handmade-Henna-Brides-Indian-Pakistani-Lehenga-Choli.jpg",

      "https://cdn.shopify.com/s/files/1/0575/8851/4992/files/2_2f6e3816-5b6b-42a6-b29f-c28518f46aff.jpg?v=1728640189",
      "https://s.alicdn.com/@sc04/kf/A98035f6fffd941b5aba5eba4ea09b6c8H/New-Arrivals-Latest-Fashion-Elegant-Wedding-Party-Wear-Dresses-Women-Handmade-Henna-Brides-Indian-Pakistani-Lehenga-Choli.jpg",
      "https://cdn.shopify.com/s/files/1/0575/8851/4992/files/2_2f6e3816-5b6b-42a6-b29f-c28518f46aff.jpg?v=1728640189",
    ],
    inspirationImageAssetsKids: [
      "https://s.alicdn.com/@sc04/kf/A98035f6fffd941b5aba5eba4ea09b6c8H/New-Arrivals-Latest-Fashion-Elegant-Wedding-Party-Wear-Dresses-Women-Handmade-Henna-Brides-Indian-Pakistani-Lehenga-Choli.jpg",

      "https://cdn.shopify.com/s/files/1/0575/8851/4992/files/2_2f6e3816-5b6b-42a6-b29f-c28518f46aff.jpg?v=1728640189",
      "https://s.alicdn.com/@sc04/kf/A98035f6fffd941b5aba5eba4ea09b6c8H/New-Arrivals-Latest-Fashion-Elegant-Wedding-Party-Wear-Dresses-Women-Handmade-Henna-Brides-Indian-Pakistani-Lehenga-Choli.jpg",
      "https://cdn.shopify.com/s/files/1/0575/8851/4992/files/2_2f6e3816-5b6b-42a6-b29f-c28518f46aff.jpg?v=1728640189",
    ],
    introCardColorMen: Color(0xffE2EFC6),
    introCardColorKid: Color(0xffE2EFC6),
  );
}

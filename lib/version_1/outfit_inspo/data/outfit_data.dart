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

  final List<String> inspirationImageWebAssetsWomen; // or URLs
  final List<String> inspirationImageWebAssetsMen; // or URLs
  final List<String> inspirationImageWebAssetsKids; // or URLs

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
    required this.inspirationImageWebAssetsWomen,
    required this.inspirationImageWebAssetsMen,
    required this.inspirationImageWebAssetsKids,
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
    introSubBold:
        "Totally optional. Dress comfortably, in what makes you feel like yourself",
    introBody:
        "Think festive, playful, and photo-ready: bright colors, fun prints, and easy silhouettes that you can actually move in.",
    weather: WeatherCardData(
      gradient: [Color(0xFF7A0F44), Color(0xFFB21B64)],
      label: "THE WEATHER",
      temperature: "15°C",
      note: "This event is outdoors. Please carry a jacket, shawl, or stole.",
      icon: Icons.calendar_month_outlined,
      weatherColorWomen: Color(0xff771549),
      weatherColorMen: Color(0xff5F3406),
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
      "https://i.pinimg.com/1200x/42/e5/4c/42e54c5c41e40af371c8dae952acb763.jpg",
      "https://i.pinimg.com/736x/15/19/8f/15198f718976acda66ddf83df25c53df.jpg",
      "https://i.pinimg.com/1200x/7a/ba/84/7aba847bc2ee9460a20857048365d526.jpg",
      "https://i.pinimg.com/736x/09/7a/46/097a46284d95dc00bc821e6d4be01c7d.jpg",
      "https://i.pinimg.com/736x/0e/52/c0/0e52c07bf65631fa2b2139877178b306.jpg",
      "https://i.pinimg.com/736x/c8/6c/1c/c86c1c93ea1e524b91e0109572822d04.jpg",
      "https://i.pinimg.com/736x/70/75/84/707584c35461daa23076e1918697c2e6.jpg",
      "https://i.pinimg.com/736x/e6/2a/14/e62a14bfaa3afbadcc141499e15d4d0f.jpg",
      "https://i.pinimg.com/736x/75/97/90/7597907c11be88f2df8853b377411117.jpg",
      "https://i.pinimg.com/474x/35/c5/b0/35c5b036a749beda5e5e8f75c9ab562c.jpg",
      "https://i.pinimg.com/736x/a2/f1/91/a2f1917f2455df686d9b5070445355ed.jpg",
      "https://i.pinimg.com/736x/36/bd/01/36bd01153671496aa401b5d78a135652.jpg",
      "https://i.pinimg.com/1200x/2c/4f/b8/2c4fb80255bcbf1e24824ec833b6d863.jpg",
      "https://i.pinimg.com/736x/36/94/fe/3694fe40893d5b6d7e70961afd74bb1e.jpg",
      "https://i.pinimg.com/1200x/04/c7/d3/04c7d3e2eac8b6a77de4fae807c62b8b.jpg",
      "https://i.pinimg.com/736x/e3/ca/1f/e3ca1fffa50a7dd38303e068b395df29.jpg",
      "https://i.pinimg.com/736x/55/a6/01/55a601d76cac8eca81015bbec197c99f.jpg",
      "https://i.pinimg.com/1200x/5d/d1/5f/5dd15f2848f1202178e746428ad52c62.jpg",
      "https://i.pinimg.com/736x/52/80/04/528004eb840e04598b6af9c1d0bab090.jpg",
    ],
    inspirationImageAssetsMen: [
      "https://i.pinimg.com/736x/2f/ac/9a/2fac9a7b3fa8903e62c7777ff5169d2d.jpg",
      "https://i.pinimg.com/736x/f8/1f/0e/f81f0e5b980dce69fc1aa584c32a0215.jpg",
      "https://i.pinimg.com/1200x/b8/41/38/b84138082f4b9baf33ee2f1c16759024.jpg",
      "https://i.pinimg.com/736x/3e/80/ee/3e80ee73b01cec7364e92750cdb5a45c.jpg",
      "https://i.pinimg.com/736x/be/80/84/be80849e8c7a98d60489bc066e614042.jpg",
      "https://i.pinimg.com/1200x/a3/f0/5e/a3f05e4c82f4c76b8c2682c5c211b09a.jpg",
      "https://i.pinimg.com/1200x/63/f4/bd/63f4bd22c2380798084bd68139062bd8.jpg",
      "https://i.pinimg.com/736x/90/3c/f7/903cf757c25ec9a1a4f8ab9a8c3c67b8.jpg",
      "https://i.pinimg.com/1200x/5e/75/e0/5e75e0f1e1ab3f5e710c8adba91a6aaf.jpg",
      "https://i.pinimg.com/1200x/59/d3/21/59d321301ac452a0429b83a01ed512f7.jpg",
      "https://i.pinimg.com/1200x/1b/c2/ca/1bc2caecad7b44554a08e1efdc7342f8.jpg",
      "https://i.pinimg.com/736x/09/b3/2f/09b32fb051c10dae6b8fb3db616629fb.jpg",
      "https://i.pinimg.com/736x/c0/f5/6e/c0f56ee42cbe48344344bf2b4de527a6.jpg",
      "https://i.pinimg.com/1200x/40/dd/1c/40dd1c47c46fc0e52ace79be5f7cc511.jpg",
      "https://i.pinimg.com/736x/b5/40/e5/b540e5d0c244d0ebc8bffd58630f347a.jpg",
      "https://i.pinimg.com/1200x/03/c9/dd/03c9dd37c1f22bddca7a5ac801803faa.jpg",
      "https://i.pinimg.com/736x/a1/6b/3c/a16b3cd32b890bcf07dc13616caab531.jpg",
    ],
    inspirationImageAssetsKids: [
      "https://i.pinimg.com/1200x/96/57/25/965725de04e73a73060beaaca34a3d58.jpg",
      "https://i.pinimg.com/1200x/e8/b7/9f/e8b79f0f77ba5d7254756f60345f5caf.jpg",
      'https://i.pinimg.com/1200x/4e/df/eb/4edfeb1ecdc974eac5ac858075ded6f0.jpg',
      "https://i.pinimg.com/736x/c9/e3/1e/c9e31ea69d347ebee2c94fbe4120b86f.jpg",
    ],
    introCardColorMen: Color(0xffFFF0DF),
    introCardColorKid: Color(0xffE2EFC6),

    inspirationImageWebAssetsMen: [
      "assets/images/mehendi/men/mehendi_men_1.jpg",
      "assets/images/mehendi/men/mehendi_men_2.jpg",
      "assets/images/mehendi/men/mehendi_men_3.jpg",
      "assets/images/mehendi/men/mehendi_men_4.jpg",
      "assets/images/mehendi/men/mehendi_men_5.jpg",
      "assets/images/mehendi/men/mehendi_men_6.jpg",
      "assets/images/mehendi/men/mehendi_men_7.jpg",
      "assets/images/mehendi/men/mehendi_men_8.jpg",
      "assets/images/mehendi/men/mehendi_men_9.jpg",
    ],
    inspirationImageWebAssetsWomen: [
      "assets/images/mehendi/women/mehendi_women_1.jpg",
      "assets/images/mehendi/women/mehendi_women_2.jpg",
      "assets/images/mehendi/women/mehendi_women_3.jpg",
      "assets/images/mehendi/women/mehendi_women_4.jpg",
      "assets/images/mehendi/women/mehendi_women_5.jpg",

      "assets/images/mehendi/women/mehendi_women_7.jpg",
      "assets/images/mehendi/women/mehendi_women_8.jpg",
      "assets/images/mehendi/women/mehendi_women_9.jpg",
      "assets/images/mehendi/women/mehendi_women_10.jpg",
    ],
    inspirationImageWebAssetsKids: [
      "assets/images/mehendi/kid/mehendi_kid_1.jpg",
      "assets/images/mehendi/kid/mehendi_kid_2.jpg",
      "assets/images/mehendi/kid/mehendi_kid_3.jpg",

      "assets/images/mehendi/kid/mehendi_kid_4.jpg",
    ],
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
          "Evening can get breezy. Carry a light jacket if you get cold easily.",
      icon: Icons.calendar_month_outlined,
      weatherColorWomen: Color(0xff771549),
      weatherColorMen: Color(0xff5F3406),
      weatherColorKid: Color(0xff06471D),
    ),
    colorsTitle: "The colors",
    colors: [
      ColorChipData("Ivory", Color(0xFFFFFFF0)),
      ColorChipData("Rose", Color(0xFFE9A7B7)),
      ColorChipData("Sage", Color(0xFF7BAE8E)),
      ColorChipData("Gold", Color(0xFFD4AF37)),
      ColorChipData("Black", Color(0xFF1B1B1B)),
    ],
    inspirationsTitle: "Outfit inspirations",
    inspirationImageAssetsWomen: [
      "https://i.pinimg.com/736x/63/53/00/635300c2d8b2ecb9b275f29db800ba69.jpg",
      "https://i.pinimg.com/736x/5e/70/2d/5e702d7220b2e8f0ed7f752d7b8e09c6.jpg",
      "https://i.pinimg.com/736x/a9/9c/2f/a99c2fc2afd27fd1cecec6d5a74d82bb.jpg",
      "https://i.pinimg.com/1200x/10/b0/87/10b0879451e4b45dde972dacebe05b89.jpg",
      "https://i.pinimg.com/1200x/af/8b/bd/af8bbd5f1d91b8234f46ff27ba5dc8c5.jpg",
      "https://i.pinimg.com/1200x/6b/49/1e/6b491e7184f718e743d1c20a8ebd8741.jpg",
      "https://i.pinimg.com/1200x/06/5f/cc/065fcc0b8f066959aa7c400dfeeea5ce.jpg",
      "https://i.pinimg.com/1200x/7a/7b/69/7a7b691b4a9c6540fd23260228f0559b.jpg",
      "https://i.pinimg.com/736x/5e/70/2d/5e702d7220b2e8f0ed7f752d7b8e09c6.jpg",
      "https://i.pinimg.com/1200x/fc/93/3f/fc933ff8c6d829bd7215485e570921e2.jpg",
      'https://i.pinimg.com/736x/f4/a9/d4/f4a9d468f2d16d4802456813fa8c3397.jpg',
      "https://i.pinimg.com/1200x/e8/ed/5b/e8ed5b0b4330ecf691cb786bdd2d0af6.jpg",
      "https://i.pinimg.com/1200x/80/5e/b3/805eb3463792cfc641353efa9056fa5d.jpg",
      "https://i.pinimg.com/736x/ce/d8/61/ced861214e3585bc2ebd16d279541379.jpg",
      "https://i.pinimg.com/736x/07/2d/6b/072d6b82c29cb5c048c4cc02e3ce3884.jpg",
      "https://i.pinimg.com/1200x/82/3e/c5/823ec5006be7e54067315baa7797f295.jpg",

      "https://i.pinimg.com/736x/12/00/50/12005040fd806dd7e18ac5aee51f3a1a.jpg",
      "https://i.pinimg.com/736x/af/ff/8c/afff8ce17649059dd39cb8a572ecfe9e.jpg",
    ],
    inspirationImageAssetsMen: [
      "https://i.pinimg.com/736x/e4/f8/04/e4f80415025c625033df85f247a1343f.jpg",
      "https://i.pinimg.com/1200x/b2/be/81/b2be8140b0b0feb63133bd2823bc3e00.jpg",
      "https://i.pinimg.com/1200x/d9/86/3a/d9863aa1843849303692393cdf71c0bd.jpg",
      "https://i.pinimg.com/1200x/72/d6/c6/72d6c6f5a11eaa4c04ee75913d3bab8b.jpg",
      "https://i.pinimg.com/736x/79/09/37/790937482186197ae7fbd5dbde8bafe9.jpg",
      "https://i.pinimg.com/736x/d4/3e/ae/d43eaeb13078764f85aebbb80f50c55c.jpg",
      "https://i.pinimg.com/736x/b0/f1/b3/b0f1b32d35ca09d618473052288e4dca.jpg",
      "https://i.pinimg.com/736x/ce/a0/fc/cea0fc519673c5ef17506a7e23048572.jpg",
      "https://i.pinimg.com/1200x/e6/a0/b6/e6a0b6a476826c7ebcc4e90e02e78114.jpg",
      "https://i.pinimg.com/1200x/2e/2d/54/2e2d548b152db7def73777eb6156f462.jpg",
      "https://i.pinimg.com/736x/77/fc/0a/77fc0a09302bd056873054ce8653070a.jpg",
      "https://i.pinimg.com/1200x/05/83/77/05837726cf1f870c231ceae7cd9e7fc1.jpg",
      "https://i.pinimg.com/736x/f7/97/28/f79728d654c9a56924ae66d52a1d0af1.jpg",
      "https://i.pinimg.com/736x/87/08/cf/8708cf19461da32e34b339c2e60ad246.jpg",
      "https://i.pinimg.com/1200x/5d/b5/f1/5db5f1b5b679b27c92d32a74e0420f06.jpg",
      "https://i.pinimg.com/736x/a6/38/58/a638584a36e6951ec3c5d5f1b8500087.jpg",
      "https://i.pinimg.com/1200x/c2/94/55/c294551921479f584631f3754f06965c.jpg",
      "https://i.pinimg.com/736x/b2/1d/03/b21d03c17e5d735d36e602bcf48db4b2.jpg",
      "https://i.pinimg.com/736x/26/5c/c3/265cc31e32cb12061d99aa4749075f82.jpg",
      "https://i.pinimg.com/736x/30/7d/95/307d9582904a9a9136c2fd47092615bf.jpg",
      "https://i.pinimg.com/736x/4f/d4/4e/4fd44ee6a3bbc74583b7f988cb251216.jpg",
      "https://i.pinimg.com/1200x/5f/e5/24/5fe5245758554def104dd68ba928c24b.jpg",
      "https://i.pinimg.com/1200x/f2/a7/0b/f2a70b4c20dae6290cee7be92f6a2972.jpg",
      "https://i.pinimg.com/736x/e7/35/00/e73500f3c991720b4e72254adc0a5b8e.jpg",
      "https://i.pinimg.com/1200x/de/b3/34/deb3342c4770fa40880bf93f2b4561ca.jpg",
    ],
    inspirationImageAssetsKids: [
      "https://i.pinimg.com/1200x/0f/a1/9c/0fa19c5948752b45a6eea356166d0d6f.jpg",
      "https://i.pinimg.com/736x/33/82/c0/3382c0a6b378b8a41fd81798733e6bd8.jpg",
      "https://i.pinimg.com/1200x/fb/48/a9/fb48a9925ceb174dee6785a5c4b8f152.jpg",
      "https://i.pinimg.com/1200x/0b/3e/84/0b3e849e2d9530d8df5ef68d0191d8dc.jpg",
      "https://i.pinimg.com/736x/29/c4/e1/29c4e13332c9713eb9c8e7fce216a1d8.jpg",
    ],
    inspirationImageWebAssetsMen: [
      "assets/images/mehendi/men/mehendi_men_1.jpg",
      "assets/images/mehendi/men/mehendi_men_2.jpg",
      "assets/images/mehendi/men/mehendi_men_3.jpg",
      "assets/images/mehendi/men/mehendi_men_4.jpg",
      "assets/images/mehendi/men/mehendi_men_5.jpg",
      "assets/images/mehendi/men/mehendi_men_6.jpg",
      "assets/images/mehendi/men/mehendi_men_7.jpg",
      "assets/images/mehendi/men/mehendi_men_8.jpg",
      "assets/images/mehendi/men/mehendi_men_9.jpg",
    ],
    inspirationImageWebAssetsWomen: [
      "assets/images/mehendi/women/mehendi_women_1.jpg",
      "assets/images/mehendi/women/mehendi_women_2.jpg",
      "assets/images/mehendi/women/mehendi_women_3.jpg",
      "assets/images/mehendi/women/mehendi_women_4.jpg",
      "assets/images/mehendi/women/mehendi_women_5.jpg",
      "assets/images/mehendi/women/mehendi_women_6.jpg",
      "assets/images/mehendi/women/mehendi_women_7.jpg",
      "assets/images/mehendi/women/mehendi_women_8.jpg",
      "assets/images/mehendi/women/mehendi_women_9.jpg",
      "assets/images/mehendi/women/mehendi_women_10.jpg",
    ],
    inspirationImageWebAssetsKids: [
      "assets/images/mehendi/kid/mehendi_kid_1.jpg",
      "assets/images/mehendi/kid/mehendi_kid_2.jpg",
      "assets/images/mehendi/kid/mehendi_kid_3.jpg",

      "assets/images/mehendi/kid/mehendi_kid_4.jpg",
    ],
    introCardColorMen: Color(0xffFFF0DF),
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
        "Bring your best look ; structured fits, rich colors, and details\nthat pop under lights and cameras.",
    weather: WeatherCardData(
      gradient: [Color(0xFF2B0C1E), Color(0xFF7A0F44)],
      label: "THE WEATHER",
      temperature: "20°C",
      note: "Indoors. A light layer is enough.",
      icon: Icons.calendar_month_outlined,
      weatherColorWomen: Color(0xff771549),
      weatherColorMen: Color(0xff5F3406),
      weatherColorKid: Color(0xff06471D),
    ),
    colorsTitle: "The colors",
    colors: [
      ColorChipData("Burgundy", Color(0xFF6B1842)),
      ColorChipData("Champagne", Color(0xFFE7D7B8)),
      ColorChipData("Navy", Color(0xFF0B1F3A)),
      ColorChipData("Silver", Color(0xFFC0C0C0)),
      ColorChipData("Emerald", Color(0xFF1F8A4C)),
    ],
    inspirationsTitle: "Outfit inspirations",
    inspirationImageAssetsWomen: [
      "https://i.pinimg.com/1200x/bc/33/a5/bc33a58ac136390a63b59fc339e64488.jpg",
      "https://i.pinimg.com/736x/f4/c3/2e/f4c32e24cc9c28c348d77e886b7b2615.jpg",
      "https://i.pinimg.com/1200x/bf/a6/38/bfa6389106b5db50b4d4cdd9a63b1d76.jpg",
      "https://i.pinimg.com/474x/49/ad/15/49ad158ff815f35dbb7dcdc77d0243bf.jpg",
      "https://i.pinimg.com/736x/ba/fd/82/bafd82e03e6e978aef1f3a6446824f04.jpg",
      "https://i.pinimg.com/1200x/20/e2/4d/20e24d62548ba1ba5d1a3579dea0c43f.jpg",
      "https://i.pinimg.com/736x/19/f5/41/19f54128d0fb8104ca6181c293db0ace.jpg",
      "https://i.pinimg.com/736x/e3/1b/b7/e31bb766307f935ead12452e837cb48a.jpg",
      "https://i.pinimg.com/736x/59/2a/50/592a50c6d5319001108cdbc09b041a10.jpg",
      "https://i.pinimg.com/1200x/bf/76/46/bf76460f78459f1d6a72b04fc3b4b951.jpg",
      "https://i.pinimg.com/1200x/68/11/7c/68117c6529e032a938eb131703238d85.jpg",
      "https://i.pinimg.com/1200x/cd/c7/52/cdc752101c04b381f3a721811e872355.jpg",
    ],
    inspirationImageAssetsMen: [
      "https://i.pinimg.com/1200x/b7/e0/83/b7e0831251ba58a168198c7ab9cbe584.jpg",
      "https://i.pinimg.com/736x/21/4c/22/214c223f6969e36fe628f782bd9fcf37.jpg",
      "https://i.pinimg.com/1200x/da/ab/af/daabafe8bdbba917619d2b8af9020958.jpg",
      "https://i.pinimg.com/736x/1a/8d/d9/1a8dd9f2f5baace1e83ae83a90dfa1c7.jpg",
      "https://i.pinimg.com/736x/1d/d7/d7/1dd7d7300c3e9294e491063f8e416111.jpg",
      "https://i.pinimg.com/736x/95/0c/de/950cde2f4f4311ae34619a54b6fddf20.jpg",
      "https://i.pinimg.com/1200x/87/19/a4/8719a4bfdeee21cc4431abc4d02e19e4.jpg",
      "https://i.pinimg.com/736x/d4/34/a4/d434a4e01669b0700ebb3d2083877f72.jpg",
      "https://i.pinimg.com/736x/70/57/6a/70576ad14f745c8e8f0f6cd82b7393d9.jpg",
      "https://i.pinimg.com/1200x/41/82/36/418236bc7e0fa5c100deaf22efffbe7d.jpg",
      "https://i.pinimg.com/736x/ad/ad/9c/adad9c893c3d3c4a32494aa43ba85a0a.jpg",
    ],
    inspirationImageAssetsKids: [
      "https://i.pinimg.com/736x/5c/49/9a/5c499a9f8710bca70aaeb907f26715bd.jpg",
      "https://i.pinimg.com/1200x/2f/38/0d/2f380d4b14a33b9b63aa5415a00a149a.jpg",
      "https://i.pinimg.com/1200x/38/4e/ea/384eeac71e1b25840234c55abb1d0001.jpg",
      "https://i.pinimg.com/736x/3e/1b/41/3e1b419fce4272422bcf33692103f5e0.jpg",
    ],
    inspirationImageWebAssetsMen: [
      "assets/images/reception/men/reception_men_1.jpg",
      "assets/images/reception/men/reception_men_2.jpg",
      "assets/images/reception/men/reception_men_3.jpg",
      "assets/images/reception/men/reception_men_4.jpg",
      "assets/images/reception/men/reception_men_5.jpg",
      "assets/images/reception/men/reception_men_6.jpg",
      "assets/images/reception/men/reception_men_7.jpg",
      "assets/images/reception/men/reception_men_8.jpg",
      "assets/images/reception/men/reception_men_9.jpg",
      "assets/images/reception/men/reception_men_10.jpg",
      "assets/images/reception/men/reception_men_11.jpg",
    ],
    inspirationImageWebAssetsWomen: [
      "assets/images/reception/women/reception_women_1.jpg",
      "assets/images/reception/women/reception_women_2.jpg",
      "assets/images/reception/women/reception_women_3.jpg",
      "assets/images/reception/women/reception_women_4.jpg",
      "assets/images/reception/women/reception_women_5.jpg",
      "assets/images/reception/women/reception_women_6.jpg",
      "assets/images/reception/women/reception_women_7.jpg",
      "assets/images/reception/women/reception_women_8.jpg",
    ],
    inspirationImageWebAssetsKids: [
      "assets/images/reception/kid/reception_kid_1.jpg",
      "assets/images/reception/kid/reception_kid_2.jpg",
      "assets/images/reception/kid/reception_kid_3.jpg",
      "assets/images/reception/kid/reception_kid_4.jpg",
    ],
    introCardColorMen: Color(0xffFFF0DF),
    introCardColorKid: Color(0xffE2EFC6),
  );
}

import 'package:flutter/material.dart';
import 'package:wedding_invite/version_1/events/data/event_details_modal.dart';

class DetailsSectionUI extends StatelessWidget {
  const DetailsSectionUI({
    required this.data,
    required this.onDirectionsTap,
    required this.color, required this.title,
  });

  final EventDetailsSection data;
  final VoidCallback onDirectionsTap;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pink info card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 23, 10, 26),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.headline,
                style: const TextStyle(
                  fontSize: 20,
                  // height: 1,
                  color: Colors.black,
                  fontFamily: 'SFPRO',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 53),
              Text(
                data.description,
                style: const TextStyle(
                  fontSize: 14,
                  // height: 1,
                  color: Colors.black,
                  fontFamily: 'SFPRO',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Location block (grey container)
        _LocationBlock(
          location: data.location,
          weather: data.weather,
          amenities: data.amenities,
          onDirectionsTap: onDirectionsTap,
          color: data.mainColor,
          title: title,
        ),
      ],
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({
    required this.location,
    required this.onDirectionsTap,
    required this.weather,
    required this.amenities,
    required this.color, required this.title,
  });

  final LocationSection location;
  final WeatherSection? weather;
  final List<AmenityItem> amenities;
  final VoidCallback onDirectionsTap;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(21, 28, 20, 30),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "About the location",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontFamily: 'SFPRO',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 25),

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9.8,
                  child: Image.network(location.imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 21),

              Text(
                location.title,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontFamily: 'SFPRO',
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                location.subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: Colors.black,
                  fontFamily: 'SFPRO',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 25),

              // directions + distance row
              Row(
                children: [
                  _DirectionsButton(onTap: onDirectionsTap, color: color),
                  const Spacer(),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (location.distanceKm != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "${location.distanceKm} km",
                              style: const TextStyle(
                                fontFamily: 'SFPRO',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                      if (location.etaText != null) ...[
                        // const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            location.etaText!,
                            style: const TextStyle(
                              color: Color(0xFF777777),
                              fontFamily: 'SFPRO',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // divider
              const SizedBox(height: 29),
              const Divider(height: 1),

              // weather
              if (weather != null) ...[
                const SizedBox(height: 27),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            weather!.label,
                            style: const TextStyle(
                              letterSpacing: 1.2,
                              fontSize: 12,
                              color: Colors.black,
                              fontFamily: 'SFPRO',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            weather!.temperatureText,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.black,
                              fontFamily: 'SFPRO',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(weather!.icon, size: 26),
                  ],
                ),
                const SizedBox(height: 27),
                const Divider(height: 1),
              ],

              // amenities
              if (amenities.isNotEmpty) ...[
                const SizedBox(height: 33),
                const Text(
                  "Amenities",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontFamily: 'SFPRO',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 27),
                ...amenities.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(a.icon, color: const Color(0xFF9A2A2A2)),
                        const SizedBox(width: 12),
                        Text(
                          a.text,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'SFPRO',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if(title=='nikkah')
                const SizedBox(height: 110),
              ],
            ],
          ),
        ),
        if(title=='nikkah')
        Positioned(
          bottom: 0,
          right: 0,
          left: 0,
          child: Container(
            // width: 383,
            // height: 110,
            decoration: ShapeDecoration(
              color: const Color(0xFFF25454),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(19.0),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parking is not free at this location.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'SFPRO',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'SMS  to 5566: {SOURCE} {PLATE } {HOURS} \n(example: SHJ 12345 2).',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'SFPRO',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DirectionsButton extends StatelessWidget {
  const _DirectionsButton({required this.onTap, required this.color});
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              "Get directions",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SFPRO',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

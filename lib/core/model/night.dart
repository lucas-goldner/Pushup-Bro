/// The hour night starts on the island (8 pm, local time).
const kNightStartHour = 20;

/// The hour night ends on the island (6 am, local time).
const kNightEndHour = 6;

/// Whether [now] is at night on the island: from 8 pm until 6 am. The
/// island's music and its look both follow this.
bool isNight(DateTime now) =>
    now.hour >= kNightStartHour || now.hour < kNightEndHour;

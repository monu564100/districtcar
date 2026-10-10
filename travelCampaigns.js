/**
 * District Car Tourism & Travel Hindi Jokes & Engagement Campaign Catalog
 * Features iconic Jharkhand destinations with humorous Hindi travel pitches.
 */

const travelCampaigns = [
  {
    id: 'netarhat_sunset_1',
    place: 'Netarhat',
    district: 'Latehar',
    title: '🌄 Chalo Netarhat Ghoom Ke Aatey Hai!',
    body: 'Bhai, laptop band kar, Maggie aur pahadon ki hawa bula rahi hai! Netarhat Magnolia Sunset Point ka round-trip cab sirf District Car se book karo.',
    hindiJoke: 'Ghar wale pooch rahe hain shaadi kab karoge? Humne bola: pehle Netarhat ka sunset dekh aane do!',
    imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop',
    category: 'nature',
    target: 'customers',
    suggestedVehicle: 'suv'
  },
  {
    id: 'deoghar_darshan_2',
    place: 'Baba Baidyanath Mandir, Deoghar',
    district: 'Deoghar',
    title: '🚩 Har Har Mahadev! Chalo Deoghar Darshan!',
    body: 'Peda khane aur Baba Dham ka darshan karne ka man hai? Pariwar ke sath AC cab book karo - No tension, full aashirwad!',
    hindiJoke: 'Dost ne pucha: Itna tension kyu le rahe ho? Humne bola: Baidyanath Dham ghoom aao, sab sankat door ho jayenge!',
    imageUrl: 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=800&auto=format&fit=crop',
    category: 'pilgrimage',
    target: 'customers',
    suggestedVehicle: 'sedan'
  },
  {
    id: 'patratu_valley_3',
    place: 'Patratu Valley & Dam',
    district: 'Ramgarh',
    title: '🏎️ Patratu Valley ke Ghumavdaar Raaste!',
    body: 'Ekdum Bollywood level scenic drive aur lake boating! Chai, pakode aur romantic roads ka trip District Car cab me book karo.',
    hindiJoke: 'Traffic se tang aa chuke ho? Patratu ki hawaon me gaadi chalao, BP apne aap normal ho jayega!',
    imageUrl: 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&auto=format&fit=crop',
    category: 'adventure',
    target: 'customers',
    suggestedVehicle: 'sedan'
  },
  {
    id: 'hundru_fall_4',
    place: 'Hundru & Jonha Falls',
    district: 'Ranchi',
    title: '🌊 Garmi / Weekend me Hundru Falls ka Dhamaka!',
    body: 'Jharna dekhna hai? Chalo Ranchi ke mashhoor Hundru aur Jonha Fall! Friends group ke sath instant SUV book karo.',
    hindiJoke: 'Gym join karne ki sochi thi, par doston ne bola Hundru Falls ki seedhiyan chadh lo, cardio ho jayega!',
    imageUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=800&auto=format&fit=crop',
    category: 'waterfall',
    target: 'customers',
    suggestedVehicle: 'suv'
  },
  {
    id: 'parasnat_shikharji_5',
    place: 'Parasnath (Shikharji)',
    district: 'Giridih',
    title: '🏔️ Parasnath Pahadi - Jharkhand ka Sabse Uncha Shikhar!',
    body: 'Pavitra Shikharji tirth yatra aur haseen pahaadon ki shanti. Family round-trip booking par payein special discount!',
    hindiJoke: 'Mobile network aaye na aaye, Parasnath pahonchte hi dil ko shanti pakka milegi!',
    imageUrl: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=800&auto=format&fit=crop',
    category: 'pilgrimage',
    target: 'customers',
    suggestedVehicle: 'suv'
  },
  {
    id: 'betla_national_park_6',
    place: 'Betla National Park & Palamu Qila',
    district: 'Palamu / Latehar',
    title: '🐅 Jungle Safari @ Betla National Park!',
    body: 'Hathi, hiran aur jungle safari ka thrill! Itihaasik Palamu kila aur jungle ka trip District Car cab ke sath planned!',
    hindiJoke: 'Office boss tiger ki tarah daad raha ho, toh Betla aakar asli tiger dekh lo, darr nikal jayega!',
    imageUrl: 'https://images.unsplash.com/photo-1534567153574-2b12153a87f0?w=800&auto=format&fit=crop',
    category: 'wildlife',
    target: 'customers',
    suggestedVehicle: 'suv'
  },
  {
    id: 'dassam_fall_7',
    place: 'Dassam Falls & Kanchi River',
    district: 'Khunti / Bundu',
    title: '💦 Dassam Falls - Khunti ke Paas Cool Picnic!',
    body: 'Kanchi nadi ka gungunaata paani aur hari-bhari ghatiyan. Weekend family picnic cab ab bas 1 click door.',
    hindiJoke: 'Ghar me AC chala ke kab tak baithoge? Asli thandak Dassam Falls ke paani ke fawaare me hai!',
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop',
    category: 'waterfall',
    target: 'customers',
    suggestedVehicle: 'mini'
  },
  {
    id: 'dimna_lake_8',
    place: 'Dimna Lake & Dalma Hills',
    district: 'East Singhbhum (Jamshedpur)',
    title: '🏞️ Dimna Lake ke Kinaare Chai aur Sukoon!',
    body: 'Jamshedpur ke Dalma pahadon ke beech Dimna Lake ka khubsoorat nazaara! Apne doston ke sath ride schedule karo.',
    hindiJoke: 'Stress bhagane ke liye doctor ne dawa nahi, Dimna Lake par drive karne ki salah di hai!',
    imageUrl: 'https://images.unsplash.com/photo-1470246973918-29a93221c455?w=800&auto=format&fit=crop',
    category: 'nature',
    target: 'customers',
    suggestedVehicle: 'sedan'
  }
];

module.exports = {
  travelCampaigns
};

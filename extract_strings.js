const fs = require('fs');
const content = fs.readFileSync('c:/Users/ARAFATH/StudioProjects/Dak/lib/tamp16.js', 'utf8');
const matches = [...content.matchAll(/"([^"]+)"/g)];
const unique = [...new Set(matches.map(m => m[1]))];
const filtered = unique.filter(s => s.length > 2 && !s.includes('package:') && !s.includes('flutter__') && !s.includes('dart:') && !s.includes('_Location'));
fs.writeFileSync('c:/Users/ARAFATH/StudioProjects/Dak/strings16.txt', filtered.join('\n'));

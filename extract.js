const fs = require('fs');
const content = fs.readFileSync('c:/Users/ARAFATH/StudioProjects/Dak/lib/tamp6.js', 'utf8');
const matches = [...content.matchAll(/\"([^\"]+)\"/g)];
const unique = [...new Set(matches.map(m => m[1]))];
unique.forEach(s => {
    if (s.length > 2 && !s.startsWith('package:') && !s.startsWith('dart:') && !s.startsWith('file:') && !s.startsWith('flutter:')) {
        console.log(s);
    }
});

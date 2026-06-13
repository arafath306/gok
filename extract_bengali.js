const fs = require('fs');
const content = fs.readFileSync('c:/Users/ARAFATH/StudioProjects/Dak/lib/tamp16.js', 'utf8');
const regex = /"([\s\S]*?)"/g;
let match;
const strings = new Set();
while ((match = regex.exec(content)) !== null) {
  if (/[^\x00-\x7F]/.test(match[1])) {
    strings.add(match[1].replace(/\n/g, '\\n'));
  }
}
fs.writeFileSync('c:/Users/ARAFATH/StudioProjects/Dak/strings16_bengali.txt', [...strings].join('\n'));

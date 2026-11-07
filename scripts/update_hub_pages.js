const fs = require('fs');
const path = require('path');

const cluster1 = require('./seo/build_cluster1_tours.js');
const cluster2 = require('./seo/build_cluster2_services.js');
const cluster3 = require('./seo/build_cluster3_blogs.js');
const cluster4 = require('./seo/build_cluster4_news.js');

const landingDir = path.join(__dirname, '..', 'landing');

// 1. Update services.html
const servicesFile = path.join(landingDir, 'services.html');
let servicesHtml = fs.readFileSync(servicesFile, 'utf8');

const serviceCardsHtml = cluster2.map(s => {
  if (servicesHtml.includes(`services/${s.slug}`)) return '';
  return `
      <div class="service-card">
        <div>
          <span class="service-card-tag">${s.metaTitle}</span>
          <h2>${s.h1}</h2>
          <span class="hi-name">डिस्ट्रिक्ट कार खूंटी स्पेशल रूट</span>
          <p>${s.metaDescription}</p>
        </div>
        <div class="service-card-footer">
          <a href="services/${s.slug}" class="btn-card-learn">View Fares & Book →</a>
          <a href="tel:+918789601387" class="btn-card-call"><i class="fa-solid fa-phone"></i></a>
        </div>
      </div>`;
}).filter(Boolean).join('\n');

if (serviceCardsHtml) {
  servicesHtml = servicesHtml.replace('</main>', `${serviceCardsHtml}\n    </div>\n  </main>`);
  // Fix double closing div if any
  servicesHtml = servicesHtml.replace('</div>\n    </div>\n  </main>', '</div>\n  </main>');
  fs.writeFileSync(servicesFile, servicesHtml, 'utf8');
  console.log("Updated services.html with new service cards.");
} else {
  console.log("Services cards already present in services.html.");
}

// 2. Update tours.html
const toursFile = path.join(landingDir, 'tours.html');
let toursHtml = fs.readFileSync(toursFile, 'utf8');

const tourCardsHtml = cluster1.map(t => {
  if (toursHtml.includes(`tours/${t.slug}`)) return '';
  return `
        <article class="tour-card" data-category="cultural" data-name="${t.h1.toLowerCase()}">
          <div class="tour-card-media">
            <img width="800" height="450" src="assets/tour_banner_jharkhand.jpg" alt="${t.metaTitle}" class="tour-card-img" loading="lazy">
            <span class="tour-badge-top"><i class="fa-solid fa-star"></i> Khunti Special</span>
          </div>
          <div class="tour-card-body">
            <div class="tour-location-meta"><i class="fa-solid fa-location-dot"></i> ${t.geo.name}</div>
            <h3 class="tour-card-title">${t.h1}</h3>
            <p class="tour-card-desc">${t.metaDescription}</p>
            <div class="tour-card-footer">
              <span class="tour-price-tag">${t.infoStats[3].val}</span>
              <a href="tours/${t.slug}" class="btn-tour-view">View Tour & Book →</a>
            </div>
          </div>
        </article>`;
}).filter(Boolean).join('\n');

if (tourCardsHtml) {
  const insertMarker = 'id="destinations-container"';
  const markerIdx = toursHtml.indexOf(insertMarker);
  if (markerIdx !== -1) {
    const endOpenDiv = toursHtml.indexOf('>', markerIdx);
    toursHtml = toursHtml.slice(0, endOpenDiv + 1) + '\n' + tourCardsHtml + toursHtml.slice(endOpenDiv + 1);
    fs.writeFileSync(toursFile, toursHtml, 'utf8');
    console.log("Updated tours.html with new tour cards.");
  }
} else {
  console.log("Tour cards already present in tours.html.");
}

// 3. Update blogs.html
const blogsFile = path.join(landingDir, 'blogs.html');
let blogsHtml = fs.readFileSync(blogsFile, 'utf8');

const blogCardsHtml = cluster3.map(b => {
  if (blogsHtml.includes(`blogs/${b.slug}`)) return '';
  return `
      <article class="article-card" style="border: 2px solid #93C5FD;">
        <div class="article-img-wrap">
          <img width="400" height="220" loading="lazy" decoding="async" src="assets/tour_banner_jharkhand.jpg" alt="${b.metaTitle}">
          <span class="article-category">Khunti Guide & FAQs</span>
        </div>
        <div class="article-content">
          <div class="article-meta">
            <span><i class="fa-regular fa-calendar"></i> Nov 2026</span>
            <span><i class="fa-solid fa-location-dot"></i> Khunti</span>
          </div>
          <h2 class="article-title"><a href="blogs/${b.slug}">${b.h1}</a></h2>
          <p class="article-desc">${b.metaDescription}</p>
          <a href="blogs/${b.slug}" class="article-read-link">Read Full Travel Guide →</a>
        </div>
      </article>`;
}).filter(Boolean).join('\n');

if (blogCardsHtml) {
  const blogMarker = '<div class="articles-grid"';
  const bIdx = blogsHtml.indexOf(blogMarker);
  if (bIdx !== -1) {
    const bEndOpen = blogsHtml.indexOf('>', bIdx);
    blogsHtml = blogsHtml.slice(0, bEndOpen + 1) + '\n' + blogCardsHtml + blogsHtml.slice(bEndOpen + 1);
    fs.writeFileSync(blogsFile, blogsHtml, 'utf8');
    console.log("Updated blogs.html with new blog cards.");
  }
} else {
  console.log("Blog cards already present in blogs.html.");
}

// 4. Update news-local.html
const newsFile = path.join(landingDir, 'news-local.html');
let newsHtml = fs.readFileSync(newsFile, 'utf8');

const newsCardsHtml = cluster4.map(n => {
  if (newsHtml.includes(`news-local/${n.slug}`)) return '';
  return `
      <article class="news-card" data-district="Khunti">
        <div class="card-badge">स्थानीय समाचार • खूंटी</div>
        <h3 class="card-title"><a href="news-local/${n.slug}">${n.h1}</a></h3>
        <p class="card-snippet">${n.metaDescription}</p>
        <div class="card-footer-meta">
          <span><i class="fa-regular fa-clock"></i> 7 नवंबर 2026</span>
          <a href="news-local/${n.slug}" class="read-more-link">पूरा समाचार पढ़ें →</a>
        </div>
      </article>`;
}).filter(Boolean).join('\n');

if (newsCardsHtml) {
  const newsMarker = '<div class="news-grid"';
  const nIdx = newsHtml.indexOf(newsMarker);
  if (nIdx !== -1) {
    const nEndOpen = newsHtml.indexOf('>', nIdx);
    newsHtml = newsHtml.slice(0, nEndOpen + 1) + '\n' + newsCardsHtml + newsHtml.slice(nEndOpen + 1);
    fs.writeFileSync(newsFile, newsHtml, 'utf8');
    console.log("Updated news-local.html with new news cards.");
  }
} else {
  console.log("News cards already present in news-local.html.");
}

console.log("Hub index page synchronization complete!");

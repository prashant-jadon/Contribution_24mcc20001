const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

(async () => {
  console.log('Launching browser...');
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  const page = await browser.newPage();

  // Set a wide viewport for landscape
  await page.setViewport({ width: 1440, height: 900 });

  const htmlPath = path.resolve(__dirname, 'future_titans_final (1).html');
  console.log('Loading HTML:', htmlPath);
  await page.goto(`file://${htmlPath}`, { waitUntil: 'networkidle0', timeout: 60000 });

  // Wait for fonts to load
  await page.evaluate(() => document.fonts.ready);
  await new Promise(r => setTimeout(r, 3000));
  console.log('Page loaded, fonts ready.');

  // Inject print CSS for page breaks and landscape layout
  await page.addStyleTag({
    content: `
      @page {
        size: A4 landscape;
        margin: 0;
      }

      @media print {
        *, *::before, *::after {
          -webkit-print-color-adjust: exact !important;
          print-color-adjust: exact !important;
          color-adjust: exact !important;
        }

        html, body {
          margin: 0 !important;
          padding: 0 !important;
          overflow: visible !important;
        }

        /* Kill all animations */
        .cover-eyebrow, .cover-h1, .cover-tagline, .cover-bottom {
          animation: none !important;
          opacity: 1 !important;
          transform: none !important;
        }

        /* =========================================
           SECTION WRAPPERS — each becomes a page
        ========================================= */

        /* We wrap content with page-break-inside: avoid and page-break-after: always
           via data-pdf-page attribute injected by JS below */
        [data-pdf-page] {
          page-break-after: always;
          page-break-inside: avoid;
          overflow: hidden;
        }
        [data-pdf-page]:last-child {
          page-break-after: auto;
        }

        /* Make each page section fill the landscape page */
        .pdf-page-wrapper {
          width: 100%;
          min-height: 100vh;
          box-sizing: border-box;
          overflow: hidden;
          page-break-after: always;
          page-break-inside: avoid;
        }
        .pdf-page-wrapper:last-child {
          page-break-after: auto;
        }
      }
    `
  });

  // Restructure the DOM: wrap sections into page groups as user specified
  await page.evaluate(() => {
    const body = document.body;
    const children = Array.from(body.children);

    // Map out all top-level elements
    // children[0] = section.cover
    // children[1] = div (startup india endorsement band)
    // children[2] = section.s-dark (THE PROBLEM)
    // children[3] = div.statement-band
    // children[4] = section.s-dark (decision trigger: "not a workshop...")
    // children[5] = section.s-dark (OUR SOLUTION)
    // children[6] = section.s-dark (WHO WE ARE + People + Partners)
    // children[7] = section.s-light (CRITICAL THINKING PROGRESSION)
    // children[8] = section.s-dark (COMPARISON TABLE / MARKET REALITY)
    // children[9] = div.cost-hero
    // children[10] = section.s-white (WHAT YOUR SCHOOL GETS)
    // children[11] = section.s-dark (WHAT YOUR STUDENTS GET + JOURNEY)
    // children[12] = section.closing

    // Define page groups (indices into children array)
    const pageGroups = [
      [0, 1],       // Page 1: Cover + Startup India band
      [2],          // Page 2: The Problem
      [3, 4],       // Page 3: Statement Band + Decision Trigger
      [5],          // Page 4: Our Solution
      [6],          // Page 5: Who We Are + Featured In + People + Partners
      [7],          // Page 6: Critical Thinking Progression
      [8],          // Page 7: Market Reality / Comparison
      [9],          // Page 8: Cost Hero
      [10],         // Page 9: What Your School Gets
      [11],         // Page 10: What Your Students Get + Journey
      [12],         // Page 11: Closing
    ];

    // Create wrapper divs
    const wrappers = pageGroups.map((indices, i) => {
      const wrapper = document.createElement('div');
      wrapper.className = 'pdf-page-wrapper';
      wrapper.setAttribute('data-pdf-page', String(i + 1));
      return wrapper;
    });

    // Move children into wrappers (need to do this carefully)
    // First, detach all children
    const detached = children.map(c => body.removeChild(c));

    // Then add them into wrappers
    pageGroups.forEach((indices, i) => {
      indices.forEach(idx => {
        if (detached[idx]) {
          wrappers[i].appendChild(detached[idx]);
        }
      });
    });

    // Add wrappers back to body
    wrappers.forEach(w => body.appendChild(w));
  });

  console.log('DOM restructured with page breaks.');

  const outputPath = path.resolve(__dirname, 'Future_Titans_Presentation.pdf');
  await page.pdf({
    path: outputPath,
    landscape: true,
    printBackground: true,
    preferCSSPageSize: true,
    format: 'A4',
    margin: { top: '0', right: '0', bottom: '0', left: '0' },
  });

  console.log(`✅ PDF saved to: ${outputPath}`);
  await browser.close();
})();

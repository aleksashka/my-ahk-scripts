// ==UserScript==
// @name         Wait for load, click buttons, send Signal
// @version      1.2
// @description  Waits for page load (via paragraphs, clicks buttons and signals via download
// @author       ChatGPT + alakinalexandr@gmail.com
// @match        *://*/*
// @grant        none
// ==/UserScript==

(function () {
    'use strict';

    const BUTTON_TEXTS = ["Show Me", "Open Transcript"];
    const CLICK_DELAY_MS = 1000;
    const SIGNAL_FILE_NAME = "tm_page_done.txt";
    let lastUrl = location.href;

    // --- Monitor URL change every second ---
    setInterval(() => {
        const currentUrl = location.href;
        if (currentUrl !== lastUrl) {
            lastUrl = currentUrl;
            console.log('TM_Load: URL changed:', currentUrl);
            runAfterPageReady();
        }
    }, 1000);

    // --- Wait until content paragraph appears ---
    async function runAfterPageReady() {
        try {
            console.log('TM_Load: Waiting for any of known paragraphs...');
            await waitForParagraph();
            console.log('TM_Load: Page is ready, clicking buttons');
            const elems = findMatchingElements();
            clickSequentially(elems, CLICK_DELAY_MS, sendSignal);
        } catch (err) {
            console.warn('TM_Load:', err.message);
        }
    }

    function waitForParagraph(timeout = 15000) {
        const selectors = [
            'p.content-paragraph',
            'p.assessment-intro.mb-4'
        ];

        return new Promise((resolve, reject) => {
            const start = Date.now();

            const check = () => {
                const el = selectors.map(sel => document.querySelector(sel)).find(Boolean);
                if (el) {
                    observer.disconnect();
                    console.log(`TM_Load: Found <${el.tagName.toLowerCase()}.${el.className}>:`, el.textContent.trim().slice(0, 30) + '...');
                    resolve(el);
                } else if (Date.now() - start > timeout) {
                    observer.disconnect();
                    reject(new Error('TM_Load: Timeout waiting for a paragraph'));
                }
            };

            const observer = new MutationObserver(check);
            observer.observe(document.documentElement, { childList: true, subtree: true });

            check();
        });
    }

    function findMatchingElements() {
        const elements = [];

        // Collect <a><span>Text</span></a>
        const aElems = document.querySelectorAll("a span");
        aElems.forEach(span => {
            const text = span.innerText || "";
            if (BUTTON_TEXTS.includes(text.trim())) {
                elements.push(span.closest('a'));
            }
        });

        // Collect <button> and <input>
        const buttonElems = document.querySelectorAll("button, input[type='button'], input[type='submit']");
        buttonElems.forEach(el => {
            const text = el.innerText || el.value || "";
            if (BUTTON_TEXTS.includes(text.trim())) {
                elements.push(el);
            }
        });

        return elements;
    }

    function clickSequentially(elems, delay, callback) {
        if (!elems.length) {
            console.log("TM_Load: No matching buttons found.");
            callback();
            return;
        }

        let i = 0;
        const clickNext = () => {
            const el = elems[i];
            if (el) {
                // console.log(`TM_Load: Clicking: ${el.tagName}, text: ${el.innerText || el.value}`);
                el.click();
            }
            i++;
            if (i < elems.length) {
            //if (i < 5) {
                setTimeout(clickNext, delay);
            } else {
                console.log(`TM_Load: Clicked: ${i} elements`);
                setTimeout(callback, delay);
            }
        };

        clickNext();
    }

    function sendSignal() {
        const blob = new Blob(["done"], { type: "text/plain" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = SIGNAL_FILE_NAME;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        console.log("TM_Load: Signal sent.");
    }

})();

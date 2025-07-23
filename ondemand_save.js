// ==UserScript==
// @name         Button Clicker + AHK Signal
// @namespace    http://example.com/
// @version      1.1
// @description  Clicks various buttons, then signals AHK via download
// @match        *://*/*
// @grant        none
// ==/UserScript==

(function () {
    'use strict';

    const BUTTON_TEXTS = ["Show Me", "Open Transcript"];
    const CLICK_DELAY_MS = 1000;
    const SIGNAL_FILE_NAME = "tm_page_done.txt";

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
            console.log("No matching buttons found.");
            callback();
            return;
        }

        let i = 0;
        const clickNext = () => {
            const el = elems[i];
            if (el) {
                console.log(`Clicking: ${el.tagName}, text: ${el.innerText || el.value}`);
                el.click();
            }
            i++;
            if (i < elems.length) {
            //if (i < 5) {
                setTimeout(clickNext, delay);
            } else {
                setTimeout(callback, delay);
            }
        };

        clickNext();
    }

    function signalAHK() {
        const blob = new Blob(["done"], { type: "text/plain" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = SIGNAL_FILE_NAME;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        console.log("Signal sent to AHK.");
    }

    // Hotkey: Ctrl + Shift + Z
    window.addEventListener('keydown', function (e) {
        if (e.ctrlKey && e.shiftKey && e.key.toLowerCase() === 'z') {
            const elems = findMatchingElements();
            clickSequentially(elems, CLICK_DELAY_MS, signalAHK);
        }
    });
})();

// The static half of the site's script. WIGGLE_PALETTES and WIGGLE_INDEX are
// written above this line by scripts/bake-guide-site.lua.
(function () {
	"use strict";

	var root = document.documentElement;
	var KEY = "wiggle-palette";
	var OFF = "wiggle-off";

	function remember(key, value) {
		try { localStorage.setItem(key, value); } catch (e) { /* private window */ }
	}

	function recall(key) {
		try { return localStorage.getItem(key); } catch (e) { return null; }
	}

	// ------------------------------------------------------------ palette

	function wear(name) {
		if (WIGGLE_PALETTES.indexOf(name) < 0) { return; }
		root.dataset.palette = name;
		remember(KEY, name);
		if (picker) { picker.value = name; }
	}

	var picker = document.getElementById("palette");
	var chosen = recall(KEY);
	if (chosen) { wear(chosen); }
	if (picker) {
		picker.value = root.dataset.palette;
		picker.addEventListener("change", function () { wear(picker.value); });
	}

	// -------------------------------------------------------------- shake
	//
	// The detector is UI/Wiggle.lua, constant for constant. Six turns inside
	// 1.2 seconds, each leg at least 60 units long, deaf for a second after
	// one. In the game a shake swaps the theme, which is how much of the
	// addon is drawn; there is no addon on this page to draw more of, so here
	// it steps to the next palette, which is the half of the gesture a
	// website can honestly show.

	var SPAN = 60, TURNS = 6, WINDOW = 1.2, QUIET = 1;

	var turns = [], head = 0, quiet = 0, pivot = null, far = 0, way = 0;
	for (var i = 0; i < TURNS; i++) { turns.push(-Infinity); }

	function feed(x, now) {
		if (now < quiet) { pivot = null; return false; }
		if (pivot === null) { pivot = x; far = x; way = 0; return false; }
		if (way === 0) {
			if (x - pivot >= SPAN) { way = 1; far = x; }
			else if (pivot - x >= SPAN) { way = -1; far = x; }
			return false;
		}
		if ((x - far) * way > 0) { far = x; return false; }
		if ((far - x) * way < SPAN) { return false; }

		pivot = far; far = x; way = -way;
		turns[head] = now;
		head = (head + 1) % TURNS;
		if (now - turns[head] > WINDOW) { return false; }
		for (var k = 0; k < TURNS; k++) { turns[k] = -Infinity; }
		quiet = now + QUIET;
		pivot = null;
		return true;
	}

	var button = document.getElementById("wiggle-off");
	var wiggling = recall(OFF) !== "yes";

	function say() {
		if (button) { button.textContent = wiggling ? "Turn it off" : "Turn it on"; }
	}
	say();

	if (button) {
		button.addEventListener("click", function () {
			wiggling = !wiggling;
			remember(OFF, wiggling ? "no" : "yes");
			pivot = null;
			say();
		});
	}

	document.addEventListener("mousemove", function (event) {
		if (!wiggling) { return; }
		if (!feed(event.clientX, event.timeStamp / 1000)) { return; }
		var at = WIGGLE_PALETTES.indexOf(root.dataset.palette);
		wear(WIGGLE_PALETTES[(at + 1) % WIGGLE_PALETTES.length]);
	}, { passive: true });

	// ------------------------------------------------------------- search

	var field = document.getElementById("find");
	var hits = document.getElementById("hits");
	if (!field || !hits) { return; }

	var depth = document.querySelector(".brand");
	var up = depth && depth.getAttribute("href").indexOf("../") === 0 ? "../" : "";

	function fold(text) { return text.toLowerCase(); }

	var haystack = WIGGLE_INDEX.map(function (row) {
		return {
			heading: fold(row.h),
			page: fold(row.p),
			text: fold(row.t),
			// The index page's sections are the list of the other pages, so
			// every one of them matches half the guide. They are an answer
			// only when nothing else is.
			contents: row.u.indexOf("index.html") === 0,
		};
	});

	// A section whose own heading is the word beats one that only mentions it.
	// Without this, typing "swing" put the swing timer's own section fifth,
	// under three pages that mention it in passing.
	function rank(row, word) {
		if (row.contents) { return 4; }
		if (row.heading === word) { return 0; }
		if (row.heading.indexOf(word) >= 0) { return 1; }
		if (row.page.indexOf(word) >= 0) { return 2; }
		return 3;
	}

	function snippet(text, word) {
		var at = fold(text).indexOf(word);
		if (at < 0) { return text.slice(0, 120); }
		var from = Math.max(0, at - 40);
		var cut = text.slice(from, from + 150);
		return (from > 0 ? "…" : "") + cut + "…";
	}

	var picked = -1;

	function show(rows, word) {
		picked = -1;
		if (!rows.length) {
			hits.innerHTML = '<p class="none">Nothing in the guide says that.</p>';
			hits.hidden = false;
			return;
		}
		hits.innerHTML = rows.map(function (row) {
			var a = document.createElement("a");
			a.className = "hit";
			a.href = up + row.u;
			var b = document.createElement("b");
			b.textContent = row.h;
			var s = document.createElement("span");
			s.textContent = row.p + " — " + snippet(row.t, word);
			a.appendChild(b);
			a.appendChild(s);
			return a.outerHTML;
		}).join("");
		hits.hidden = false;
	}

	function look() {
		var word = fold(field.value.trim());
		if (word.length < 2) { hits.hidden = true; hits.innerHTML = ""; return; }
		var found = [];
		for (var k = 0; k < haystack.length; k++) {
			var row = haystack[k];
			if (row.heading.indexOf(word) < 0 && row.page.indexOf(word) < 0
				&& row.text.indexOf(word) < 0) { continue; }
			found.push({ row: WIGGLE_INDEX[k], at: k, score: rank(row, word) });
		}
		found.sort(function (a, b) { return a.score - b.score || a.at - b.at; });
		show(found.slice(0, 12).map(function (hit) { return hit.row; }), word);
	}

	field.addEventListener("input", look);

	field.addEventListener("keydown", function (event) {
		var found = hits.querySelectorAll(".hit");
		if (event.key === "Escape") { hits.hidden = true; field.blur(); return; }
		if (!found.length) { return; }
		if (event.key === "ArrowDown" || event.key === "ArrowUp") {
			event.preventDefault();
			picked += event.key === "ArrowDown" ? 1 : -1;
			if (picked < 0) { picked = found.length - 1; }
			if (picked >= found.length) { picked = 0; }
			for (var k = 0; k < found.length; k++) {
				found[k].classList.toggle("on", k === picked);
			}
			found[picked].scrollIntoView({ block: "nearest" });
		} else if (event.key === "Enter" && picked >= 0) {
			event.preventDefault();
			found[picked].click();
		}
	});

	document.addEventListener("click", function (event) {
		if (!hits.contains(event.target) && event.target !== field) { hits.hidden = true; }
	});

	// The one key the guide's own reader is most likely to reach for.
	document.addEventListener("keydown", function (event) {
		if (event.key === "/" && document.activeElement !== field) {
			event.preventDefault();
			field.focus();
			field.select();
		}
	});
}());

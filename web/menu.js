(function () {
    'use strict';

    var RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'pure_clothing';

    function post(name, data) {
        return fetch('https://' + RES + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data === undefined ? {} : data)
        }).then(function (r) { return r.json(); }).catch(function () { return null; });
    }
    function $(sel, el) { return (el || document).querySelector(sel); }
    function h(tag, attrs, children) {
        var e = document.createElement(tag);
        if (attrs) for (var k in attrs) {
            if (k === 'class') e.className = attrs[k];
            else if (k === 'html') e.innerHTML = attrs[k];
            else if (k === 'text') e.textContent = attrs[k];
            else if (k.slice(0, 2) === 'on') e.addEventListener(k.slice(2), attrs[k]);
            else e.setAttribute(k, attrs[k]);
        }
        (children || []).forEach(function (c) { if (c) e.appendChild(typeof c === 'string' ? document.createTextNode(c) : c); });
        return e;
    }
    function copy(o) { return JSON.parse(JSON.stringify(o)); }
    function fmt(s) {
        var args = Array.prototype.slice.call(arguments, 1), i = 0;
        return String(s).replace(/%[sd]/g, function () { return args[i++]; });
    }
    function T(key) { return (S && S.texts && S.texts[key]) || key; }
    function money(n) { return '$' + Number(n || 0).toLocaleString('en-US'); }
    function priceText(p) { return p > 0 ? money(p) : T('free'); }

    var ICONS = {
        clothes: 'M8 3L3 6l2.2 4 2.3-1.2V21h9V8.8l2.3 1.2L21 6l-5-3c-.8 1.8-2.2 2.8-4 2.8S8.8 4.8 8 3z',
        accessories: 'M3 17h18M5.5 17c0-5.5 2.8-9.5 6.5-9.5s6.5 4 6.5 9.5M9 7.8c.8-1.8 1.9-2.8 3-2.8s2.2 1 3 2.8',
        cart: 'M3 4h2.5l2.2 11h10.6L21 7H7M9.5 19.5a1 1 0 1 0 0 .1M17.5 19.5a1 1 0 1 0 0 .1',
        jacket: 'M8 3L3 6l2.2 4 2.3-1.2V21h9V8.8l2.3 1.2L21 6l-5-3M12 6.5V21M8 3l4 3.5L16 3M9.5 13h1M13.5 13h1',
        shirt: 'M8 3L3 6l2.2 4 2.3-1.2V21h9V8.8l2.3 1.2L21 6l-5-3c-.8 1.8-2.2 2.8-4 2.8S8.8 4.8 8 3z',
        gloves: 'M8.5 21v-6.5L6 10.5l1.5-1 2.5 3V4.5a1.2 1.2 0 0 1 2.4 0V10h.6V3.2a1.2 1.2 0 0 1 2.4 0V10h.6V4.5a1.2 1.2 0 0 1 2.4 0v8c0 4.3-2 6.5-4.4 8.5',
        pants: 'M7 3h10l1.5 18h-4.2L12 10l-2.3 11H5.5zM7 6.5h10',
        shoes: 'M3 13.5L4 8l4.5 1c.8 2 2.8 3.2 5.5 3.4l5 .6c1.3.2 2 1.2 2 2.4V17H3zM3 17h18M8 10.5l1.5-1.5M10.5 11.5L12 10',
        decals: 'M5 4h10l4 4v12H5zM15 4v4h4M9 13l2 2 4-4',
        neck: 'M5.5 3.5c0 6.5 2.6 10.5 6.5 10.5s6.5-4 6.5-10.5M12 14v2.5M10 18.5a2 2 0 1 0 4 0 2 2 0 1 0-4 0',
        mask: 'M4 7.5c3.5-2.5 12.5-2.5 16 0v4.5c0 5-4 8.5-8 8.5s-8-3.5-8-8.5zM7.5 11.5c.8-.8 2.2-.8 3 0M13.5 11.5c.8-.8 2.2-.8 3 0M10 16.5c1.2.6 2.8.6 4 0',
        bag: 'M7 9a5 5 0 0 1 10 0v11.5H7zM9.8 9V6.2a2.2 2.2 0 0 1 4.4 0V9M9 14h6v3.5H9z',
        vest: 'M8.5 3L4 6v14h6.5v-6.5h3V20H20V6l-4.5-3-2 4h-3zM7 10h2.5M14.5 10H17',
        hat: 'M3 17h18M5.5 17c0-5.5 2.8-9.5 6.5-9.5s6.5 4 6.5 9.5M9 7.8c.8-1.8 1.9-2.8 3-2.8s2.2 1 3 2.8',
        glasses: 'M2.5 11.5a4 3.2 0 1 0 8 0 4 3.2 0 1 0-8 0M13.5 11.5a4 3.2 0 1 0 8 0 4 3.2 0 1 0-8 0M10.5 11.2c1-.6 2-.6 3 0',
        ears: 'M12 3v3.5M9 9.5a3 3 0 1 0 6 0 3 3 0 1 0-6 0M12 12.5l-2.5 3 2.5 5 2.5-5z',
        watch: 'M9 2.5h6l.8 4M9 21.5h6l.8-4M9 2.5l-.8 4M9 21.5l-.8-4M6.5 12a5.5 5.5 0 1 0 11 0 5.5 5.5 0 1 0-11 0M12 9.5V12l1.8 1.2',
        bracelet: 'M4 11a8 3.8 0 1 0 16 0 8 3.8 0 1 0-16 0M4 11v2.2c0 2.1 3.6 3.8 8 3.8s8-1.7 8-3.8V11',
        star: 'M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.8l-5.2 2.8 1-5.8-4.3-4.1 5.9-.8z',
        eye: 'M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12zM9 12a3 3 0 1 0 6 0 3 3 0 1 0-6 0',
        eyeOff: 'M2 12s3.6-7 10-7c2 0 3.8.7 5.2 1.6M22 12s-3.6 7-10 7c-2 0-3.8-.7-5.2-1.6M3 3l18 18',
        none: 'M5.6 5.6l12.8 12.8M3 12a9 9 0 1 0 18 0 9 9 0 1 0-18 0',
        mouse: 'M7 9a5 5 0 0 1 10 0v6a5 5 0 0 1-10 0zM12 4v5',
        wheel: 'M7 9a5 5 0 0 1 10 0v6a5 5 0 0 1-10 0zM12 6.5v4',
        cross: 'M6 6l12 12M18 6L6 18'
    };
    function svg(name) { return '<svg viewBox="0 0 24 24"><path d="' + (ICONS[name] || '') + '"/></svg>'; }

    var SECTIONS = ['clothes', 'accessories', 'cart'];

    var S = null;
    var thumbs = null;
    var thumbsReady = fetch('miniatures/index.json').then(function (r) { return r.json(); }).then(function (list) {
        thumbs = {};
        (list || []).forEach(function (c) { thumbs[c] = true; });
    }).catch(function () { thumbs = {}; });

    function emptyState(data) {
        return {
            texts: data.texts || {},
            model: data.model,
            slots: data.slots || [],
            worn: copy(data.worn || {}),
            origin: copy(data.worn || {}),
            shop: data.shop || {},
            menu: data.menu || {},
            favorites: {},
            section: 'clothes',
            tab: {},
            categories: {},
            hides: {},
            favFilter: {},
            kind: {},
            cart: {},
            bought: {},
            buying: false
        };
    }

    function slotsOf(section) {
        return S.slots.filter(function (s) { return section === 'accessories' ? s.prop !== undefined : s.prop === undefined; });
    }
    function slotByKey(key) {
        for (var i = 0; i < S.slots.length; i++) if (S.slots[i].key === key) return S.slots[i];
        return null;
    }
    function label(slot) { return T('slot_' + slot.key); }
    function itemLabel(slot) { return T('item_' + slot.key); }

    function loadCategory(slot) {
        var key = S.model + '|' + slot.key;
        if (S.categories[key]) return Promise.resolve(S.categories[key]);
        return post('category', { key: slot.key }).then(function (res) {
            if (!res || !Array.isArray(res.items)) return null;
            if (S) S.categories[key] = res;
            return res;
        });
    }
    function categoryLoaded(slot) { return S.categories[S.model + '|' + slot.key] || null; }

    // ---- rail ---------------------------------------------------------------------------------

    function renderSections() {
        var box = $('#sections');
        box.innerHTML = '';
        var count = Object.keys(S.cart).length;
        SECTIONS.forEach(function (k) {
            if (k !== 'cart' && slotsOf(k).length === 0) return;
            var b = h('button', {
                class: 'section' + (S.section === k ? ' active' : ''), html: svg(k) + '<span>' + T(k) + '</span>',
                onclick: function () { goTo(k); }
            });
            if (k === 'cart' && count > 0) b.appendChild(h('span', { class: 'badge', text: String(count) }));
            box.appendChild(b);
        });
    }

    function place(map) {
        var root = document.documentElement.style;
        var rem = parseFloat(getComputedStyle(document.documentElement).fontSize) || 16;
        if (typeof map === 'number' && map > 0 && map < 0.7) {
            root.setProperty('--bottom', Math.max(4.4 * rem, map * window.innerHeight + 0.9 * rem) + 'px');
            root.setProperty('--top', '2.6rem');
        } else {
            root.removeProperty('--bottom');
            root.removeProperty('--top');
        }
    }

    function applyTheme(theme) {
        var root = document.documentElement.style;
        var map = { Accent: '--accent', Background: '--bg', Tile: '--tile', Price: '--price', Text: '--text' };
        for (var k in map) {
            if (theme && theme[k]) root.setProperty(map[k], theme[k]); else root.removeProperty(map[k]);
        }
        var scale = theme && Number(theme.Scale) > 0 ? Number(theme.Scale) : 1;
        root.fontSize = (1.4815 * scale) + 'vh';
        root.setProperty('--columns', theme && Number(theme.Columns) >= 2 ? String(Math.floor(theme.Columns)) : '4');
    }
    function opt(name) { return !(S && S.menu && S.menu[name] === false); }

    function goTo(section) {
        S.section = section;
        renderSections();
        renderPanel();
    }

    // ---- panel --------------------------------------------------------------------------------

    function renderPanel() {
        var p = $('#panel');
        var old = $('#panel .grid');
        if (old && old._obs) old._obs.disconnect();
        p.innerHTML = '';
        if (S.section === 'cart') renderCart(p); else renderCategoryPanel(p, S.section);
        renderHelp();
        updateButtons();
    }

    function renderHelp() {
        $('#help').classList.toggle('hidden', !opt('HelpBar'));
        var t = '<span class="t"><kbd>' + svg('mouse') + '</kbd>' + T('help_rotate') + '</span>' +
            '<span class="t"><kbd>' + svg('mouse') + '</kbd>' + T('help_orbit') + '</span>' +
            '<span class="t"><kbd>' + svg('wheel') + '</kbd>' + T('help_zoom') + '</span>';
        if (S.section !== 'cart') t += '<span class="t"><kbd>&larr;</kbd><kbd>&rarr;</kbd>' + T('help_color') + '</span>';
        t += '<span class="t"><kbd>Esc</kbd>' + T('help_quit') + '</span>';
        $('#help').innerHTML = t;
    }

    function activeSlot() {
        if (S.section === 'cart') return null;
        var slots = slotsOf(S.section), k = S.tab[S.section];
        for (var i = 0; i < slots.length; i++) if (slots[i].key === k) return slots[i];
        return slots[0] || null;
    }

    function renderCategoryPanel(p, section) {
        var slots = slotsOf(section), slot = activeSlot();
        if (!slot) return;
        S.tab[section] = slot.key;
        var bar = h('div', { class: 'tabs' });
        slots.forEach(function (s) {
            bar.appendChild(h('button', {
                class: 'tab' + (s.key === slot.key ? ' active' : '') + (S.cart[s.key] ? ' changed' : ''),
                html: svg(s.icon || s.key) + '<span>' + label(s) + '</span>',
                onclick: function () { S.tab[section] = s.key; renderPanel(); }
            }));
        });
        p.appendChild(bar);
        renderGrid(p, slot);
    }

    function renderGrid(p, slot) {
        var header = h('div', { class: 'header' });
        header.appendChild(h('h1', { text: label(slot) }));
        if (opt('Favorites')) header.appendChild(h('button', {
            class: 'icon-btn star' + (S.favFilter[slot.key] ? ' on' : ''), html: svg('star'), title: T('favorites_only'),
            onclick: function () { S.favFilter[slot.key] = !S.favFilter[slot.key]; renderPanel(); }
        }));
        var hidden = !!S.hides[slot.key];
        if (opt('HideButton')) header.appendChild(h('button', {
            class: 'icon-btn eye' + (hidden ? ' on' : ''), html: svg(hidden ? 'eyeOff' : 'eye'),
            title: hidden ? T('show_piece') : T('hide_piece'),
            onclick: function () {
                var hide = !S.hides[slot.key];
                if (hide) S.hides[slot.key] = true; else delete S.hides[slot.key];
                post('hide', { key: slot.key, hide: hide });
                renderPanelKeepScroll();
            }
        }));
        var right = h('div', { class: 'right' });
        var pager = h('div', { class: 'pager' });
        var num = h('span', { class: 'num', text: '…' });
        pager.appendChild(h('button', { html: '&lsaquo;', onclick: function () { neighbour(slot, -1); } }));
        pager.appendChild(num);
        pager.appendChild(h('button', { html: '&rsaquo;', onclick: function () { neighbour(slot, 1); } }));
        right.appendChild(pager);
        header.appendChild(right);
        p.appendChild(header);

        var colors = h('div', { class: 'colors hidden' });
        p.appendChild(colors);
        var grid = h('div', { class: 'grid' });
        p.appendChild(grid);
        grid.appendChild(h('div', { class: 'empty', text: T('loading') }));

        loadCategory(slot).then(function (res) {
            if (!S || grid.parentNode !== p || !p.isConnected) return;
            grid.innerHTML = '';
            if (!res) { grid.appendChild(h('div', { class: 'empty', text: T('unavailable') })); return; }
            var items = filterKind(slot, res.items, p, colors);
            // the "nothing" tile always comes first
            items = items.filter(function (it) { return it.n; }).concat(items.filter(function (it) { return !it.n; }));
            if (!items.some(function (it) { return !it.n; })) {
                grid.appendChild(h('div', { class: 'empty', text: S.kind[slot.key] === 'new' ? T('no_new') : T('nothing_here') }));
            }
            if (S.favFilter[slot.key]) items = items.filter(function (it) { return it.n || (it.c && S.favorites[it.c]); });
            var withNone = items.some(function (it) { return it.n; });
            if (S.favFilter[slot.key] && items.length <= (withNone ? 1 : 0)) {
                grid.appendChild(h('div', { class: 'empty', html: T('no_favorites') }));
            }
            var observer = new IntersectionObserver(function (entries) {
                entries.forEach(function (e) {
                    if (!e.isIntersecting) return;
                    var img = e.target;
                    img.src = img.getAttribute('data-src');
                    observer.unobserve(img);
                });
            }, { root: grid, rootMargin: '300px 0px' });
            var frag = document.createDocumentFragment();
            items.forEach(function (it) { frag.appendChild(tile(slot, it, observer)); });
            grid.appendChild(frag);
            grid._obs = observer;
            grid._items = items;
            grid._num = num;
            grid._colors = colors;
            grid._slot = slot;
            updateSelection(grid, true);
        });
    }

    // Base game / add-on sub tabs, only when the category has both.
    function filterKind(slot, items, p, before) {
        var nBase = 0, nNew = 0;
        items.forEach(function (it) { if (!it.n) { if (it.a) nNew++; else nBase++; } });
        if (!nBase || !nNew) return items;
        var kind = S.kind[slot.key];
        if (!kind) {
            var worn = S.worn[slot.key], pos = worn ? worn.d : null;
            kind = 'base';
            for (var i = 0; i < items.length; i++) if (items[i].p === pos && items[i].a) { kind = 'new'; break; }
            S.kind[slot.key] = kind;
        }
        var bar = h('div', { class: 'subtabs' });
        [['base', T('base'), nBase], ['new', T('new'), nNew]].forEach(function (o) {
            bar.appendChild(h('button', {
                class: 'subtab' + (kind === o[0] ? ' active' : ''), text: o[1] + ' (' + o[2] + ')',
                onclick: function () { S.kind[slot.key] = o[0]; renderPanel(); }
            }));
        });
        p.insertBefore(bar, before);
        var isNew = kind === 'new';
        return items.filter(function (it) { return it.n || !!it.a === isNew; });
    }

    function tile(slot, it, observer) {
        var t = h('div', { class: 'tile', 'data-p': it.p });
        if (it.n) {
            t.appendChild(h('div', { class: 'none', html: svg('none') }));
        } else {
            if (it.c && opt('Favorites')) {
                var fav = h('button', {
                    class: 'fav' + (S.favorites[it.c] ? ' on' : ''), html: svg('star'), title: T('favorite'),
                    onclick: function (e) {
                        e.stopPropagation();
                        var on = !S.favorites[it.c];
                        if (on) S.favorites[it.c] = true; else delete S.favorites[it.c];
                        fav.classList.toggle('on', on);
                        post('favorite', { key: it.c, on: on });
                    }
                });
                t.appendChild(fav);
            }
            if (typeof it.price === 'number') t.appendChild(h('span', { class: 'price', text: priceText(it.price) }));
            if (it.c && thumbs && thumbs[it.c]) {
                var img = h('img', { 'data-src': 'miniatures/' + it.c + '.webp', alt: '' });
                img.addEventListener('error', function () { img.replaceWith(noImage(slot, it)); });
                t.appendChild(img);
                observer.observe(img);
            } else {
                t.appendChild(noImage(slot, it));
            }
            if (it.a && opt('NewTag')) t.appendChild(h('span', { class: 'new-tag', text: T('new_tag') }));
            if (it.t > 1) t.appendChild(h('span', { class: 'ncolors', text: it.t + ' ' + T('colors') }));
        }
        t.addEventListener('click', function () { select(slot, it.p); });
        return t;
    }
    function noImage(slot, it) {
        return h('div', { class: 'no-image', html: svg(slot.icon || slot.key) + '<b>' + T('number') + ' ' + it.p + '</b>' });
    }

    function shownGrid() { var g = $('#panel .grid'); return g && g._items ? g : null; }

    function updateSelection(grid, scroll) {
        if (!grid || !grid._items) return;
        updateButtons();
        var slot = grid._slot, worn = S.worn[slot.key];
        var pos = worn ? worn.d : null;
        var items = grid._items, idx = -1;
        for (var i = 0; i < items.length; i++) if (items[i].p === pos) { idx = i; break; }
        var old = grid.querySelector('.tile.selected');
        if (old) old.classList.remove('selected');
        var el = idx >= 0 ? grid.children[grid.children.length - items.length + idx] : null;
        if (el) {
            el.classList.add('selected');
            if (scroll) el.scrollIntoView({ block: 'nearest' });
        }
        var nb = items.filter(function (it) { return !it.n; }).length;
        var rank = idx >= 0 && !items[idx].n ? items.slice(0, idx + 1).filter(function (it) { return !it.n; }).length : 0;
        grid._num.textContent = (rank > 0 ? rank : '–') + ' / ' + nb;
        var c = grid._colors;
        var max = idx >= 0 && !items[idx].n ? (items[idx].t || 1) - 1 : 0;
        if (!worn || idx < 0 || items[idx].n || max < 1) { c.classList.add('hidden'); return; }
        c.classList.remove('hidden');
        c.innerHTML = '';
        c.appendChild(h('span', { text: T('color') }));
        var pg = h('div', { class: 'pager' });
        pg.appendChild(h('button', { html: '&lsaquo;', onclick: function () { changeTexture(slot, -1); } }));
        pg.appendChild(h('span', { class: 'num', text: (worn.t + 1) + ' / ' + (max + 1) }));
        pg.appendChild(h('button', { html: '&rsaquo;', onclick: function () { changeTexture(slot, 1); } }));
        c.appendChild(pg);
    }

    function itemOf(slot, d) {
        var res = categoryLoaded(slot);
        if (!res) return null;
        for (var i = 0; i < res.items.length; i++) if (res.items[i].p === d) return res.items[i];
        return null;
    }
    function rankOf(slot, d) {
        var res = categoryLoaded(slot), rank = 0;
        if (!res) return 0;
        for (var i = 0; i < res.items.length; i++) {
            if (!res.items[i].n) rank++;
            if (res.items[i].p === d) return res.items[i].n ? 0 : rank;
        }
        return 0;
    }

    // What the player changed since he came in, and can pay for.
    function updateCart(slot) {
        var worn = S.worn[slot.key], origin = S.origin[slot.key], it = worn && itemOf(slot, worn.d);
        var same = origin && worn && origin.d === worn.d && origin.t === worn.t;
        var boughtKey = worn ? slot.key + '|' + worn.d + '|' + worn.t : '';
        if (!worn || !it || it.n || same || typeof it.price !== 'number' || S.bought[boughtKey]) {
            delete S.cart[slot.key];
        } else {
            S.cart[slot.key] = { d: worn.d, t: worn.t, price: it.price, rank: rankOf(slot, worn.d), c: it.c || null };
        }
        renderSections();
        var tab = $('#panel .tab.active');
        if (tab) tab.classList.toggle('changed', !!S.cart[slot.key]);
    }

    function select(slot, pos) {
        S.worn[slot.key] = { d: pos, t: 0 };
        if (S.hides[slot.key]) delete S.hides[slot.key];
        updateCart(slot);
        updateSelection(shownGrid());
        var eye = $('#panel .icon-btn.eye');
        if (eye && eye.classList.contains('on')) renderPanelKeepScroll();
        post('set', { key: slot.key, d: pos, t: 0 });
    }
    function renderPanelKeepScroll() {
        var g = $('#panel .grid'), top = g ? g.scrollTop : 0;
        renderPanel();
        var g2 = $('#panel .grid');
        if (g2) g2.scrollTop = top;
    }

    function neighbour(slot, dir) {
        var g = shownGrid();
        if (!g) return;
        var items = g._items, worn = S.worn[slot.key], idx = -1;
        for (var i = 0; i < items.length; i++) if (worn && items[i].p === worn.d) { idx = i; break; }
        var n = idx + dir;
        if (idx < 0) n = dir > 0 ? 0 : items.length - 1;
        if (n < 0) n = items.length - 1;
        if (n >= items.length) n = 0;
        if (items[n]) { select(slot, items[n].p); updateSelection(g, true); }
    }

    function changeTexture(slot, dir) {
        var worn = S.worn[slot.key], it = worn && itemOf(slot, worn.d);
        if (!worn || !it || it.n) return;
        var max = (it.t || 1) - 1;
        if (max < 1) return;
        var t = worn.t + dir;
        if (t > max) t = 0;
        if (t < 0) t = max;
        worn.t = t;
        updateCart(slot);
        updateSelection(shownGrid());
        post('set', { key: slot.key, d: worn.d, t: t });
    }

    // ---- cart ---------------------------------------------------------------------------------

    function cartTotal() {
        var total = 0;
        for (var k in S.cart) total += S.cart[k].price;
        return total;
    }

    function renderCart(p) {
        p.appendChild(h('div', { class: 'header' }, [h('h1', { text: T('cart') })]));
        var list = h('div', { class: 'cart-list' });
        var keys = Object.keys(S.cart);
        if (!keys.length) list.appendChild(h('div', { class: 'empty', html: T('cart_empty') }));
        S.slots.forEach(function (slot) {
            var e = S.cart[slot.key];
            if (!e) return;
            var thumb = h('div', { class: 'thumb' });
            if (e.c && thumbs && thumbs[e.c]) thumb.appendChild(h('img', { src: 'miniatures/' + e.c + '.webp', alt: '' }));
            else thumb.innerHTML = svg(slot.icon || slot.key);
            var it = itemOf(slot, e.d);
            var detail = T('number') + ' ' + (e.rank || e.d) + (it && it.t > 1 ? ' · ' + T('color') + ' ' + (e.t + 1) : '');
            list.appendChild(h('div', { class: 'cart-item' }, [
                thumb,
                h('div', { class: 'info' }, [h('b', { text: itemLabel(slot) }), h('span', { text: detail })]),
                h('span', { class: 'price', text: priceText(e.price) }),
                h('button', {
                    class: 'remove', html: svg('cross'), title: T('remove'),
                    onclick: function () { restoreSlot(slot); renderPanel(); }
                })
            ]));
        });
        p.appendChild(list);
        p.appendChild(h('div', { class: 'cart-total' }, [
            h('span', { text: T('cart_total') + ' (' + keys.length + ')' }),
            h('span', { class: 'sum', text: money(cartTotal()) })
        ]));
        p.appendChild(h('div', { class: 'cart-hint', text: T('cart_hint') }));
    }

    function restoreSlot(slot) {
        var o = S.origin[slot.key];
        S.worn[slot.key] = o ? copy(o) : null;
        delete S.hides[slot.key];
        updateCart(slot);
        if (o) post('set', { key: slot.key, d: o.d, t: o.t });
    }

    // ---- buttons ------------------------------------------------------------------------------

    function buyablePiece() {
        var slot = activeSlot();
        if (!slot) return { reason: T('nothing_selected') };
        var g = shownGrid();
        if (!g) return { reason: T('loading') };
        var worn = S.worn[slot.key], it = worn && itemOf(slot, worn.d);
        if (!worn || !it || it.n) return { reason: T('nothing_selected') };
        if (typeof it.price !== 'number') return { reason: T('not_sold_here') };
        var o = S.origin[slot.key];
        if (o && o.d === worn.d && o.t === worn.t) return { reason: T('already_worn') };
        return { slot: slot, worn: worn, it: it, rank: rankOf(slot, worn.d), key: slot.key + '|' + worn.d + '|' + worn.t };
    }

    function updateButtons() {
        if (!S) return;
        var b = $('#btn-buy-one');
        var a = S.section === 'cart' ? { reason: '' } : buyablePiece();
        b.classList.toggle('inactive', !a.slot || S.buying);
        b.title = a.slot ? '' : (a.reason || '');
        $('#buy-one-price').textContent = a.slot ? priceText(a.it.price) : '';
        var count = Object.keys(S.cart).length;
        $('#btn-pay').classList.toggle('inactive', count === 0 || S.buying);
        $('#pay-total').textContent = count ? money(cartTotal()) : '';
    }

    $('#btn-buy-one').addEventListener('click', function () {
        if (!S || S.buying) return;
        var a = buyablePiece();
        if (!a.slot) { toast(a.reason); return; }
        var name = itemLabel(a.slot) + ' ' + T('number') + ' ' + a.rank + (a.it.t > 1 ? ' (' + T('color').toLowerCase() + ' ' + (a.worn.t + 1) + ')' : '');
        var price = a.it.price > 0 ? fmt(T('for_price'), money(a.it.price)) : '(' + T('free').toLowerCase() + ')';
        var text = S.bought[a.key] ? fmt(T('confirm_buy_again'), name, price) : fmt(T('confirm_buy_one_text'), name, price);
        var piece = { key: a.slot.key, d: a.worn.d, t: a.worn.t };
        confirm(T('confirm_buy_one_title'), text, function () {
            S.buying = true;
            updateButtons();
            post('buyOne', piece).then(function (res) {
                if (!S) return;
                S.buying = false;
                if (res && res.ok) {
                    S.bought[a.key] = true;
                    updateCart(a.slot);
                    toast(fmt(T('bought'), res.price > 0 ? fmt(T('for_price'), money(res.price)) : ''), true);
                } else {
                    toast((res && res.reason) || (res ? T('buy_failed') : T('no_answer')));
                }
                updateButtons();
            });
        });
    });

    $('#btn-pay').addEventListener('click', function () {
        if (!S || S.buying) return;
        var keys = Object.keys(S.cart);
        if (!keys.length) return;
        var pieces = keys.map(function (k) { return { key: k, d: S.cart[k].d, t: S.cart[k].t }; });
        var total = cartTotal();
        confirm(fmt(T('confirm_pay_title'), money(total)), fmt(T('confirm_pay_text'), keys.length), function () {
            S.buying = true;
            updateButtons();
            post('checkout', { pieces: pieces }).then(function (res) {
                if (!S) return;
                S.buying = false;
                if (res && res.ok) {
                    keys.forEach(function (k) { S.bought[k + '|' + S.cart[k].d + '|' + S.cart[k].t] = true; });
                    S.cart = {};
                    renderSections();
                    toast(fmt(T('paid'), money(res.total || total), keys.length), true);
                } else {
                    toast((res && res.reason) || (res ? T('buy_failed') : T('no_answer')));
                }
                updateButtons();
            });
        });
    });

    $('#btn-reset').addEventListener('click', function () {
        if (!S) return;
        confirm(T('confirm_reset_title'), T('confirm_reset_text'), function () {
            S.worn = copy(S.origin);
            S.cart = {};
            S.hides = {};
            post('reset');
            renderSections();
            renderPanel();
        });
    });

    $('#btn-quit').addEventListener('click', askQuit);
    function askQuit() {
        if (!S) return;
        var text = Object.keys(S.bought).length ? T('confirm_quit_bought') : T('confirm_quit_text');
        confirm(T('confirm_quit_title'), text, function () { post('exit'); });
    }

    // ---- modal, toast, keys -------------------------------------------------------------------

    var onYes = null;
    function confirm(title, text, fn) {
        $('#modal-title').textContent = title;
        $('#modal-text').textContent = text;
        $('#modal-no').textContent = T('no');
        $('#modal-yes').textContent = T('yes');
        onYes = fn;
        $('#modal').classList.remove('hidden');
    }
    function closeModal() { $('#modal').classList.add('hidden'); onYes = null; }
    $('#modal-no').addEventListener('click', closeModal);
    $('#modal-yes').addEventListener('click', function () { var f = onYes; closeModal(); if (f) f(); });

    var toastTimer = null;
    function toast(text, ok) {
        var b = $('#toast');
        b.textContent = text;
        b.classList.toggle('ok', !!ok);
        b.classList.remove('hidden');
        clearTimeout(toastTimer);
        toastTimer = setTimeout(function () { b.classList.add('hidden'); }, 3500);
    }

    document.addEventListener('keydown', function (e) {
        if (!S || $('#menu').classList.contains('hidden')) return;
        if (e.key === 'Escape') {
            if (!$('#modal').classList.contains('hidden')) closeModal(); else askQuit();
            return;
        }
        if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
            var g = shownGrid();
            if (g) { changeTexture(g._slot, e.key === 'ArrowLeft' ? -1 : 1); e.preventDefault(); }
        }
    });

    // ---- camera (mouse on the free part of the screen) ---------------------------------------

    function freeZone(el) {
        if (!S || !el || $('#menu').classList.contains('hidden') || !$('#modal').classList.contains('hidden')) return false;
        return !(el.closest && el.closest('.ui-panel'));
    }
    var drag = false, lastX = 0, accX = 0, sendPlanned = false;
    function sendDrag() {
        sendPlanned = false;
        if (accX === 0) return;
        var dx = accX; accX = 0;
        post(drag === 'orbit' ? 'camOrbit' : 'camRotate', { dx: dx });
    }
    document.addEventListener('mousedown', function (e) {
        if ((e.button !== 0 && e.button !== 2) || !freeZone(e.target)) return;
        drag = e.button === 2 ? 'orbit' : 'ped';
        lastX = e.clientX; accX = 0;
        document.body.style.cursor = e.button === 2 ? 'move' : 'grabbing';
        e.preventDefault();
    }, true);
    document.addEventListener('mousemove', function (e) {
        if (!drag) return;
        accX += (e.clientX - lastX) / window.innerWidth;
        lastX = e.clientX;
        if (!sendPlanned) { sendPlanned = true; setTimeout(sendDrag, 30); }
    }, true);
    document.addEventListener('mouseup', function () {
        if (!drag) return;
        sendDrag();
        drag = false;
        document.body.style.cursor = '';
    }, true);
    document.addEventListener('contextmenu', function (e) { if (S) e.preventDefault(); }, true);
    document.addEventListener('wheel', function (e) {
        if (!freeZone(e.target) || e.deltaY === 0) return;
        post('camZoom', { dir: e.deltaY < 0 ? 1 : -1, x: e.clientX / window.innerWidth, y: e.clientY / window.innerHeight });
    }, { passive: true });

    // ---- open / close -------------------------------------------------------------------------

    function open(data) {
        if (!thumbs) { thumbsReady.then(function () { open(data); }); return; }
        S = emptyState(data);
        (Array.isArray(data.favorites) ? data.favorites : []).forEach(function (c) { S.favorites[c] = true; });
        applyTheme(data.theme);
        place(data.map);
        var logo = $('#logo');
        if (data.logo) { $('img', logo).src = data.logo; logo.classList.remove('hidden'); } else logo.classList.add('hidden');
        document.querySelectorAll('[data-t]').forEach(function (el) { el.textContent = T(el.getAttribute('data-t')); });
        $('#btn-buy-one').classList.toggle('hidden', !opt('BuyOneButton'));
        $('#btn-reset').classList.toggle('hidden', !opt('ResetButton'));
        S.section = slotsOf('clothes').length ? 'clothes' : (slotsOf('accessories').length ? 'accessories' : 'cart');
        renderSections();
        renderPanel();
        $('#menu').classList.remove('hidden');
    }
    function close() {
        S = null;
        drag = false;
        document.body.style.cursor = '';
        closeModal();
        $('#menu').classList.add('hidden');
        $('#panel').innerHTML = '';
        $('#sections').innerHTML = '';
    }

    // ---- wardrobe (without pure_inventory: take a worn piece off) ----------------------------

    var W = null;
    function openWardrobe(data) {
        if (!thumbs) { thumbsReady.then(function () { openWardrobe(data); }); return; }
        W = { texts: data.texts || {} };
        applyTheme(data.theme);
        var box = $('#wardrobe');
        $('h1', box).textContent = W.texts.wardrobe || 'Wardrobe';
        $('.hint', box).textContent = W.texts.wardrobe_hint || '';
        $('#wardrobe-close').textContent = W.texts.close || 'Close';
        renderWardrobe(data.items || []);
        box.classList.remove('hidden');
    }
    function renderWardrobe(items) {
        var list = $('#wardrobe .list');
        list.innerHTML = '';
        if (!items.length) list.appendChild(h('div', { class: 'empty', text: W.texts.wardrobe_empty || '' }));
        items.forEach(function (it) {
            var thumb = h('div', { class: 'thumb' });
            if (it.c && thumbs[it.c]) thumb.appendChild(h('img', { src: 'miniatures/' + it.c + '.webp', alt: '' }));
            else thumb.innerHTML = svg(it.icon || it.key);
            list.appendChild(h('button', {
                class: 'piece', title: W.texts.take_off || '',
                onclick: function () {
                    post('takeOff', { key: it.key }).then(function (res) { if (W && res) renderWardrobe(res.items || []); });
                }
            }, [thumb, h('b', { text: W.texts['item_' + it.key] || it.key }), h('span', { class: 'off', html: svg('cross') })]));
        });
    }
    function closeWardrobe() {
        W = null;
        $('#wardrobe').classList.add('hidden');
    }
    $('#wardrobe-close').addEventListener('click', function () { post('closeWardrobe'); closeWardrobe(); });
    document.addEventListener('keydown', function (e) {
        if (W && e.key === 'Escape') { post('closeWardrobe'); closeWardrobe(); }
    });

    window.addEventListener('message', function (e) {
        var d = e.data || {};
        if (d.action === 'open') open(d.data || {});
        else if (d.action === 'wardrobe') openWardrobe(d.data || {});
        else if (d.action === 'close') { close(); closeWardrobe(); }
        else if (d.action === 'toast' && S) toast(d.text, d.ok);
    });
})();

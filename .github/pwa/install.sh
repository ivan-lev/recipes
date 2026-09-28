#!/usr/bin/env bash
# Превращает собранный CookCLI сайт в PWA: заменяет манифест (у CookCLI пути
# от корня домена, а на GitHub Pages сайт лежит в подкаталоге), подменяет иконки,
# кладёт service worker в корень сайта и регистрирует его на каждой странице.
set -euo pipefail

site="$1"
here="$(dirname "$0")"

cp "$here/site.webmanifest" "$site/static/site.webmanifest"
cp "$here/sw.js" "$site/sw.js"
cp "$here"/png/* "$site/static/"

# Страницы лежат на разной глубине, поэтому путь к sw.js считаем от ссылки на манифест.
head_tags='<meta name="theme-color" content="#f97316"><meta name="apple-mobile-web-app-title" content="Рецепты"><script>if("serviceWorker" in navigator)navigator.serviceWorker.register(new URL("../sw.js",document.querySelector("link[rel=manifest]").href))</script>'

find "$site" -name '*.html' -print0 | xargs -0 perl -pi -e "s|</head>|${head_tags}</head>|"

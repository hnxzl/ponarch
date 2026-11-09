# Maintainer: local build
pkgname=ponarch-quickshell
pkgver=1.0.0
pkgrel=21
pkgdesc="Ponarch: notch interaktif ringan untuk Hyprland (Quickshell), terinspirasi Ponarch untuk Windows"
arch=('any')
url="https://github.com/YOUR_USER/ponarch-quickshell"
license=('custom')
# quickshell tidak dijadikan depends keras supaya paket quickshell-git / fork (mis. end-4) tetap dipakai
depends=('bash')
optdepends=(
    'quickshell: runtime notch (wajib; paket quickshell-git juga boleh)'
    'brightnessctl: slider kecerahan'
    'networkmanager: toggle Wi-Fi (nmcli)'
    'power-profiles-daemon: ganti power profile'
    'curl: cuaca (Open-Meteo), jadwal sholat (Aladhan), lokasi otomatis (IP)'
    'libnotify: notifikasi Pomodoro'
    'localsend: kirim file dari HP (ponarch localsend)'
    'waybar: bar penuh untuk ponarch mode'
    'cava: visualizer musik opsional'
    'imagemagick: warna dari wallpaper / ikon aplikasi (mode Glass)'
    'github-cli: tab GitHub PR'
    'zip: Shelf compress'
    'libarchive: Shelf extract'
    'imagemagick: Shelf konversi gambar'
    'python: Google Calendar (ponarch gcal)'
    'zenity: dialog pilih folder (Copy/Move)'
)
install=ponarch.install

package() {
    install -Dm755 "$startdir/ponarch" "$pkgdir/usr/bin/ponarch"
    install -d "$pkgdir/usr/share/ponarch"
    install -m755 "$startdir/gcal.py" "$pkgdir/usr/share/ponarch/gcal.py"
    install -m644 "$startdir"/qml/*.qml "$startdir"/qml/cava.conf "$pkgdir/usr/share/ponarch/"
    install -d "$pkgdir/usr/share/ponarch/icons"
    install -m644 "$startdir"/qml/icons/*.svg "$pkgdir/usr/share/ponarch/icons/"
    install -Dm644 "$startdir/hypr-ponarch.conf" "$pkgdir/usr/share/doc/ponarch/hypr-ponarch.conf"
    install -Dm644 "$startdir/README.md" "$pkgdir/usr/share/doc/ponarch/README.md"
    install -d "$pkgdir/usr/share/doc/ponarch/screenshots"
    install -m644 "$startdir"/screenshots/*.png "$pkgdir/usr/share/doc/ponarch/screenshots/"
    install -d "$pkgdir/usr/share/doc/ponarch/screenshots/features"
    install -m644 "$startdir"/screenshots/features/*.png "$pkgdir/usr/share/doc/ponarch/screenshots/features/"
}
